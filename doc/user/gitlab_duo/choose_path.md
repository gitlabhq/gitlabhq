---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Learn how to use GitLab Duo AI-powered features to enhance your software development lifecycle."
title: 'GitLab Duo: Choose your path'
---

GitLab Duo is a suite of AI-powered features that assist you while you work in GitLab.

Select the path that best matches what you want to do:

{{< tabs >}}

{{< tab title="Get started" >}}

**Perfect for**: New users exploring GitLab Duo

Follow this path to learn how to:

- Use the variety of GitLab Duo features
- Get help from AI through GitLab Duo Chat
- Generate and improve code

[Start here: GitLab Duo →](_index.md)

{{< /tab >}}

{{< tab title="Enhance my coding" >}}

**Perfect for**: Developers looking to boost productivity

Follow this path to learn how to:

- Use Code Suggestions in your IDE
- Generate, understand, and refactor code
- Create tests automatically

[Start here: Code Suggestions →](../project/repository/code_suggestions/_index.md)

{{< /tab >}}

{{< tab title="Improve code reviews" >}}

**Perfect for**: Reviewers and team leads

Follow this path to learn how to:

- Generate merge request descriptions
- Get AI-powered code reviews
- Summarize review comments and generate commit messages

[Start here: GitLab Duo in merge requests →](../project/merge_requests/duo_in_merge_requests.md)

{{< /tab >}}

{{< tab title="Secure my application" >}}

**Perfect for**: Security and DevSecOps professionals

Follow this path to learn how to:

- Understand vulnerabilities
- Automatically generate fix suggestions
- Create merge requests to address security issues

[Start here: Vulnerability explanation and resolution →](../application_security/vulnerabilities/_index.md#explaining-a-vulnerability)

{{< /tab >}}

{{< /tabs >}}

## Quick start

Want to start using GitLab Duo right now? Here's how:

1. Open GitLab Duo Chat by selecting **GitLab Duo Chat** in the upper-right corner of the GitLab UI.
1. Ask a question about your project, code, or how to use GitLab.
1. Try one of the AI-powered features like Code Suggestions in your IDE, or use Chat to summarize a bulky issue.

[View all of the GitLab Duo possibilities →](_index.md)

## Common tasks

Need to do something specific? Here are some common tasks:

| Task | Description | Quick Guide |
|------|-------------|-------------|
| Get AI assistance | Ask GitLab Duo questions about code, projects, or GitLab | [GitLab Duo Chat →](../gitlab_duo_chat/_index.md) |
| Generate code | Get code suggestions as you type in your IDE | [Code Suggestions →](../project/repository/code_suggestions/_index.md) |
| Understand code | Have code explained in plain language | [Code Explanation →](../project/repository/code_explain.md) |
| Fix CI/CD issues | Analyze and fix failed jobs | [Root Cause Analysis →](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) |
| Summarize changes | Generate descriptions for merge requests | [Merge Request Summary →](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) |

## How GitLab Duo integrates with your workflow

GitLab Duo is integrated with your development processes and is available:

- In the GitLab UI
- Through GitLab Duo Chat
- In IDE extensions
- In the CLI

## Experience levels

### For beginners

If you're new to GitLab Duo, start with these features:

- **[GitLab Duo Chat](../gitlab_duo_chat/_index.md)** - Ask questions about GitLab and get help with basic tasks
- **[Code Explanation](../project/repository/code_explain.md)** - Understand code in files or merge requests
- **[Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)** - Generate descriptions for your changes automatically

### For intermediate users

After you're comfortable with the basics, try these more advanced features:

- **[Code Suggestions](../project/repository/code_suggestions/_index.md)** - Get AI-powered code completion in your IDE
- **[Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide)** - Create tests for your code automatically
- **[Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)** - Troubleshoot failed CI/CD jobs

### For advanced users

When you're ready to maximize your productivity with GitLab Duo:

- **[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)** - Host LLMs on your own infrastructure
- **[GitLab Duo Workflow](../duo_workflow/_index.md)** - Automate tasks in your development workflow
- **[Vulnerability Resolution](../application_security/vulnerabilities/_index.md#vulnerability-resolution)** - Automatically generate merge requests to fix security issues

## Best practices

Follow these tips for effective GitLab Duo usage:

1. **Be specific in your prompts**
   - Provide clear context for better results
   - Include relevant details about your code and objectives
   - Use code task commands like `/explain`, `/refactor`, and `/tests` in Chat

1. **Improve code responsibly**
   - Always review AI-generated code before using it
   - Test generated code to ensure it works as expected
   - Use vulnerability resolution with appropriate review

1. **Refine iteratively**
   - If a response isn't helpful, refine your question
   - Try breaking complex requests into smaller parts
   - Add more details for better context

1. **Leverage Chat for learning**
   - Ask about GitLab features you're not familiar with
   - Get explanations for error messages and problems
   - Learn best practices for your specific technology

## Next steps

Ready to dive deeper? Try these resources:

- [GitLab Duo use cases](use_cases.md) - Practical examples and exercises
- [Set up GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md) - For complete control over your data

## Troubleshooting

Having issues? Check these common solutions:

- [GitLab Duo features don't work on self-managed](troubleshooting.md#gitlab-duo-features-do-not-work-on-self-managed)
- [GitLab Duo features not available for users](troubleshooting.md#gitlab-duo-features-not-available-for-users)
- [Run a health check](setup.md#run-a-health-check-for-gitlab-duo) to diagnose your GitLab Duo setup

Need more help? Search the GitLab documentation or [ask the GitLab community](https://forum.gitlab.com/).
