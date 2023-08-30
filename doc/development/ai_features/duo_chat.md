---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Duo chat

## Set up GitLab Duo Chat

NOTE:
Use [this snippet](https://gitlab.com/gitlab-org/gitlab/-/snippets/2554994) for help automating the following section.

1. [Enable Anthropic API features](index.md#configure-anthropic-access).
1. [Enable OpenAI support](index.md#configure-openai-access).
1. [Ensure the embedding database is configured](index.md#set-up-the-embedding-database).
1. Enable feature specific feature flag.

   ```ruby
   Feature.enable(:gitlab_duo)
   Feature.enable(:tanuki_bot)
   Feature.enable(:ai_redis_cache)
   ```

1. Ensure that your current branch is up-to-date with `master`.
1. To access the GitLab Duo Chat interface, in the lower-left corner of any page, select **Help** and **Ask GitLab Duo Chat**.

### Tips for local development

1. When responses are taking too long to appear in the user interface, consider restarting Sidekiq by running `gdk restart rails-background-jobs`. If that doesn't work, try `gdk kill` and then `gdk start`.
1. Alternatively, bypass Sidekiq entirely and run the chat service synchronously. This can help with debugging errors as GraphQL errors are now available in the network inspector instead of the Sidekiq logs.

```diff
diff --git a/ee/app/services/llm/chat_service.rb b/ee/app/services/llm/chat_service.rb
index 5fa7ae8a2bc1..5fe996ba0345 100644
--- a/ee/app/services/llm/chat_service.rb
+++ b/ee/app/services/llm/chat_service.rb
@@ -5,7 +5,7 @@ class ChatService < BaseService
     private

     def perform
-      worker_perform(user, resource, :chat, options)
+      worker_perform(user, resource, :chat, options.merge(sync: true))
     end

     def valid?
```

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
adding new tools can expand the capabilities of the chat feature.

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

## Testing GitLab Duo Chat with predefined questions

Because success of answers to user questions in GitLab Duo Chat heavily depends on toolchain and prompts of each tool, it's common that even a minor change in a prompt or a tool impacts processing of some questions. To make sure that a change in the toolchain doesn't break existing functionality, you can use the following rspecs to validate answers to some predefined questions:

```ruby
export OPENAI_API_KEY='<key>'
export ANTHROPIC_API_KEY='<key>'
REAL_AI_REQUEST=1 rspec ee/spec/lib/gitlab/llm/chain/agents/zero_shot/executor_spec.rb
```

When you need to update the test questions that require documentation embeddings,
make sure a new fixture is generated and committed together with the change.
