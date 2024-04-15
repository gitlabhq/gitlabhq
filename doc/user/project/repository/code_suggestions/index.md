---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions

DETAILS:
**Tier:** Premium or Ultimate with GitLab Duo Pro
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - [Introduced support for Code Generation](https://gitlab.com/gitlab-org/gitlab/-/issues/415583) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.
> - Subscription changed to require GitLab Duo Pro on February 15, 2024.

NOTE:
GitLab Duo Code Suggestions requires [GitLab 16.8](https://about.gitlab.com/releases/2024/01/18/gitlab-16-8-released/) and later. Earlier GitLab versions are not supported.

Write code more efficiently by using generative AI to suggest code while you're developing.

With GitLab Duo Code Suggestions, you get:

- Code completion, which suggests completions to the current line you are typing.
- Code generation, which generates code based on a natural language code
  comment block. Write a comment like `# Type more here`, then press <kbd>Enter</kbd> to generate
  code based on the context of your comment and the rest of your code.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[View a click-through demo](https://gitlab.navattic.com/code-suggestions).
<!-- Video published on 2023-12-09 --> <!-- Demo published on 2024-02-01 -->

## Use Code Suggestions

Prerequisites:

- You must have [one of the supported IDE extensions](supported_extensions.md#supported-editor-extensions).
- Your organization must have purchased the GitLab Duo Pro add-on and
  [assigned you a seat](../../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-pro-seats).
- For self-managed GitLab, you must have GitLab 16.8 or later, and have
  [configured proxy settings](../../../../subscriptions/subscription-add-ons.md#configure-network-and-proxy-settings).

To use Code Suggestions:

1. Author your code.
   As you type, suggestions are displayed. Code Suggestions provide code snippets
   or complete the current line, depending on the cursor position.

1. Describe the requirements in natural language.
   Code Suggestions generates functions and code snippets based on the context provided.

1. To accept a suggestion, press <kbd>Tab</kbd>. To reject a suggestion, press <kbd>Esc</kbd>.
1. To ignore a suggestion, keep typing as you usually would.

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

## Best practices

To get the best results from code generation:

- Be as specific as possible while remaining concise.
- State the outcome you want to generate (for example, a function)
  and provide details on what you want to achieve.
- Add additional information, like the framework or library you want to use.
- Add a space or new line after each comment.
  This space tells the code generator that you have completed your instructions.

For example, to create a Python web service with some specific requirements,
you might write something like:

```plaintext
# Create a web service using Tornado that allows a user to log in, run a security scan, and review the scan results.
# Each action (log in, run a scan, and review results) should be its own resource in the web service
...
```

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

### Best practice examples

For use cases and best practices, follow the [GitLab Duo examples documentation](../../../gitlab_duo_examples.md).

## Response time

- Code completion suggestions are usually low latency.
- For code generation:
  - Algorithms or large code blocks might take more than 10 seconds to generate.
  - Streaming of code generation responses is supported in VS Code, leading to faster average response times. Other supported IDEs offer slower response times and will return the generated code in a single block.

## Accuracy of results

We are continuing to work on the accuracy of overall generated content.
However, Code Suggestions might generate suggestions that are:

- Irrelevant.
- Incomplete.
- Results in failed pipelines.
- Potentially insecure.
- Offensive or insensitive.

When using Code Suggestions, [code review best practice](../../../../development/code_review.md) still applies.

## Progressive enhancement

This feature is designed as a progressive enhancement to developer IDEs.
Code Suggestions offer a completion if a suitable recommendation is provided to the user in a timely manner.
In the event of a connection issue or model inference failure, the feature gracefully degrades.
Code Suggestions do not prevent you from writing code in your IDE.

## Disable Code Suggestions

To disable Code Suggestions, disable the feature in your IDE editor extension.

### Disable Code Suggestions for a project

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10. This feature is an [Experiment](../../../../policy/experiment-beta-support.md).

Prerequisites:

- You must have at least the Maintainer role in the project.

You can disable Code Suggestions for specific projects.

To do so, use the GraphQL API to [update the `duoFeaturesEnabled` setting in your project](../../../../api/graphql/getting_started.md#update-project-settings).

For more information on this setting, see the [API documentation on the `projectSettingsUpdate` mutation](../../../../api/graphql/reference/index.md#mutationprojectsettingsupdate).

## Feedback

Provide feedback about your Code Suggestions experience in [issue 435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783).
