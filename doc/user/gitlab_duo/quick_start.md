---
stage: AI-powered
group: AI Framework
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
ignore_in_report: true
---

# Get started with GitLab Duo Code Suggestions

GitLab Duo is an AI-powered enhancement integrated into the GitLab DevSecOps platform, designed to boost productivity and efficiency. It leverages advanced large language models (LLMs) from Google Vertex AI and Anthropic Claude to provide various AI-driven features. These features operate independently, ensuring that the core functionality of GitLab remains unaffected even if an AI feature encounters issues.

GitLab Duo Code Suggestions helps you write code more efficiently by using generative AI to suggest code while you’re developing.

## Step 1: Understand how Code Suggestions works

Code Suggestions is made up of code completion and code generation. These are two distinct features that help developers write code more efficiently:

|  | Code completion | Code generation |
| :---- | :---- | :---- |
| Purpose | Provides suggestions for completing the current line of code.  | Generates new code based on a natural language comment. |
| Trigger | Triggers when typing, usually with a short delay.  | Triggers when pressing Enter after writing a comment that includes specific keywords. |
| Scope | Limited to the current line or small block of code.  | Can generate entire methods, functions, or even classes based on the context. |
| Accuracy | More accurate for simple tasks and short blocks of code.  | Can be more accurate for complex tasks and large blocks of code due to its ability to analyze context and use a larger language model. |
| When to use | Use code completion for quick tasks, small code snippets, or when you need a slight boost in productivity. | Use code generation for more complex tasks, larger codebases, or when you want to write new code from scratch based on a natural language description. |

## Step 2: Supported languages, text editors and IDEs

To ensure your preferred tooling is supported, review the:

[Supported languages](../project/repository/code_suggestions/supported_extensions.md#supported-languages)
[Supported editors](../project/repository/code_suggestions/supported_extensions.md#supported-editor-extensions)

## Step 3: Enable Code Suggestions

First, [purchase seats for GitLab Duo](../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo).

Then, assign seats to users to grant access to GitLab Duo for:

- [Self-managed](../../subscriptions/subscription-add-ons.md#for-self-managed)
- [Dedicated](../../subscriptions/subscription-add-ons.md#for-self-managed)
- [GitLab.com](../../subscriptions/subscription-add-ons.md#for-gitlabcom-1)

## Step 4: Using Code Suggestions

Follow the documentation to [use Code Suggestions](../project/repository/code_suggestions/index.md#use-code-suggestions).

## Step 5: Troubleshooting common challenges

[Troubleshoot](../project/repository/code_suggestions/troubleshooting.md) commonly faced challenges.
