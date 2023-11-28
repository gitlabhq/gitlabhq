---
stage: AI-powered
group: Duo Chat
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Duo Chat

## Set up GitLab Duo Chat

NOTE:
Use [this snippet](https://gitlab.com/gitlab-org/gitlab/-/snippets/2554994) for help automating the following section.

1. [Enable Anthropic API features](index.md#configure-anthropic-access).
1. [Ensure the embedding database is configured](index.md#set-up-the-embedding-database).
1. Ensure that your current branch is up-to-date with `master`.
1. Enable the feature in Rails console: `Feature.enable(:tanuki_bot_breadcrumbs_entry_point)`

## Working with GitLab Duo Chat

Prompts are the most vital part of GitLab Duo Chat system. Prompts are the instructions sent to the Large Language Model to perform certain tasks.

The state of the prompts is the result of weeks of iteration. If you want to change any prompt in the current tool, you must put it behind a feature flag.

If you have any new or updated prompts, ask members of AI Framework team to review, because they have significant experience with them.

## Contributing to GitLab Duo Chat

The Chat feature uses a [zero-shot agent](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb) that includes a system prompt explaining how the large language model should interpret the question and provide an
answer. The system prompt defines available tools that can be used to gather
information to answer the user's question.

The zero-shot agent receives the user's question and decides which tools to use to gather information to answer it.
It then makes a request to the large language model, which decides if it can answer directly or if it needs to use one
of the defined tools.

The tools each have their own prompt that provides instructions to the large language model on how to use that tool to
gather information. The tools are designed to be self-sufficient and avoid multiple requests back and forth to
the large language model.

After the tools have gathered the required information, it is returned to the zero-shot agent, which asks the large language
model if enough information has been gathered to provide the final answer to the user's question.

### Adding a new tool

To add a new tool:

1. Create files for the tool in the `ee/lib/gitlab/llm/chain/tools/` folder. Use existing tools like `issue_identifier` or
   `resource_reader` as a template.

1. Write a class for the tool that includes:

    - Name and description of what the tool does
    - Example questions that would use this tool
    - Instructions for the large language model on how to use the tool to gather information - so the main prompts that
      this tool is using.

1. Test and iterate on the prompt using RSpec tests that make real requests to the large language model.
    - Prompts require trial and error, the non-deterministic nature of working with LLM can be surprising.
    - Anthropic provides good [guide](https://docs.anthropic.com/claude/docs/introduction-to-prompt-design) on working on prompts.
    - GitLab [guide](prompts.md) on working with prompts.

1. Implement code in the tool to parse the response from the large language model and return it to the zero-shot agent.

1. Add the new tool name to the `tools` array in `ee/lib/gitlab/llm/completions/chat.rb` so the zero-shot agent knows about it.

1. Add tests by adding questions to the test-suite for which the new tool should respond to. Iterate on the prompts as needed.

The key things to keep in mind are properly instructing the large language model through prompts and tool descriptions,
keeping tools self-sufficient, and returning responses to the zero-shot agent. With some trial and error on prompts,
adding new tools can expand the capabilities of the Chat feature.

There are available short [videos](https://www.youtube.com/playlist?list=PL05JrBw4t0KoOK-bm_bwfHaOv-1cveh8i) covering this topic.

## Debugging

To gather more insights about the full request, use the `Gitlab::Llm::Logger` file to debug logs.
The default logging level on production is `INFO` and **must not** be used to log any data that could contain personal identifying information.

To follow the debugging messages related to the AI requests on the abstraction layer, you can use:

```shell
export LLM_DEBUG=1
gdk start
tail -f log/llm.log
```

## Testing GitLab Duo Chat against real LLMs locally

Because success of answers to user questions in GitLab Duo Chat heavily depends
on toolchain and prompts of each tool, it's common that even a minor change in a
prompt or a tool impacts processing of some questions.

To make sure that a change in the toolchain doesn't break existing
functionality, you can use the following RSpec tests to validate answers to some
predefined questions when using real LLMs:

```ruby
export VERTEX_AI_EMBEDDINGS='true' # if using Vertex embeddings
export ANTHROPIC_API_KEY='<key>' # can use dev value of Gitlab::CurrentSettings
export VERTEX_AI_CREDENTIALS='<vertex-ai-credentials>' # can set as dev value of Gitlab::CurrentSettings.vertex_ai_credentials
export VERTEX_AI_PROJECT='<vertex-project-name>' # can use dev value of Gitlab::CurrentSettings.vertex_ai_project

REAL_AI_REQUEST=1 bundle exec rspec ee/spec/lib/gitlab/llm/chain/agents/zero_shot/executor_real_requests_spec.rb
```

When you need to update the test questions that require documentation embeddings,
make sure a new fixture is generated and committed together with the change.

## Running the rspecs tagged with `real_ai_request`

The following CI jobs for GitLab project run the rspecs tagged with `real_ai_request`:

- `rspec-ee unit gitlab-duo-chat-zeroshot`:
   the job runs `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/executor_real_requests_spec.rb`.
   The job is optionally triggered and allowed to fail.

- `rspec-ee unit gitlab-duo-chat-qa`:
   The job runs the QA evaluation tests in
   `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`.
   The job is optionally triggered and allowed to fail.

- `rspec-ee unit gitlab-duo-chat-qa-fast`:
  The job runs a single QA evaluation test from `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`.
  The job is always run and not allowed to fail. Although there's a chance that the QA test still might fail,
  it is cheap and fast to run and intended to prevent a regression in the QA test helpers.

### Management of credentials and API keys for CI jobs

All API keys required to run the rspecs should be [masked](../../ci/variables/index.md#mask-a-cicd-variable)

The exception is GCP credentials as they contain characters that prevent them from being masked.
Because the CI jobs need to run on MR branches, GCP credentials cannot be added as a protected variable
and must be added as a regular CI variable.
For security, the GCP credentials and the associated project added to
GitLab project's CI must not be able to access any production infrastructure and sandboxed.

## GraphQL Subscription

The GraphQL Subscription for Chat behaves slightly different because it's user-centric. A user could have Chat open on multiple browser tabs, or also on their IDE.
We therefore need to broadcast messages to multiple clients to keep them in sync. The `aiAction` mutation with the `chat` action behaves the following:

1. All complete Chat messages (including messages from the user) are broadcasted with the `userId`, `aiAction: "chat"` as identifier.
1. Chunks from streamed Chat messages and currently used tools are broadcasted with the `userId`, `resourceId`, and the `clientSubscriptionId` from the mutation as identifier.

Note that we still broadcast chat messages and currently used tools using the `userId` and `resourceId` as identifier.
However, this is deprecated and should no longer be used. We want to remove `resourceId` on the subscription as part of [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420296).

## Testing GitLab Duo Chat in production-like environments

GitLab Duo Chat is enabled in the [Staging](https://staging.gitlab.com) and
[Staging Ref](https://staging-ref.gitlab.com/) GitLab environments.

Because GitLab Duo Chat is currently only available to members of groups in the
Ultimate tier, Staging Ref may be an easier place to test changes as a GitLab
team member because
[you can make yourself an instance Admin in Staging Ref](https://about.gitlab.com/handbook/engineering/infrastructure/environments/staging-ref/#admin-access)
and, as an Admin, easily create licensed groups for testing.
