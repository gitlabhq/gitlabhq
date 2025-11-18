---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat best practices
---

When prompting GitLab Duo Chat with questions, apply the following best practices
to receive concrete examples and specific guidance.

{{< alert type="note" >}}

Unless stated otherwise, the following best practices apply to both [GitLab Duo Chat (Classic)](_index.md) and [GitLab Duo Chat (Agentic)](agentic_chat.md).

{{< /alert >}}

## Have a conversation

Treat chats like conversations, not search forms. Start with a search-like question,
then follow up with related questions to refine the scope. Build context through back-and-forth.

For example, you might ask:

```plaintext
c# start project best practices
```

Then follow up with:

```plaintext
Please show the project structure for the C# project.
```

## Refine the prompt

For better responses, provide more context up front.
Think through the full scope of what you need help with and include it in one prompt.

```plaintext
How can I get started creating an empty C# console application in VS Code?
Please show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

## Follow prompt patterns

Structure prompts as problem statement, request for help, then add specificity.
Don't feel you must ask everything up front.

```plaintext
I need to fulfill compliance requirements. How can I get started with Codeowners and approval rules?
```

Then ask:

```plaintext
Please show an example for Codeowners with different teams: backend, frontend, release managers.
```

## Use low-context communication

Even if code is selected, provide context as if none is visible.
Be specific on factors like language, framework, and requirements.

```plaintext
When implementing a pure virtual function in an inherited C++ class,
should I use virtual function override, or just function override?
```

This context is less important when you use GitLab Duo Chat (Agentic) because it autonomously searches,
retrieves, and combines information from multiple sources. However, you should
still be explicit to help Chat work as efficiently as possible.

## Repeat yourself

Try rephrasing a question if you get an unexpected or strange response. Add more context.

```plaintext
How can I get started creating an C# application in VS Code?
```

Follow up with:

```plaintext
How can I get started creating an empty C# console application in VS Code?
```

## Be patient

Avoid yes/no questions. Start general, then provide specifics as needed.

```plaintext
Explain labels in GitLab. Provide an example for efficient usage with issue boards.
```

## Reset when needed

Use `/reset` if Chat gets stuck on a wrong track.

## Refine slash command prompts

Go beyond the basic slash command. Use them with more specific suggestions.

```plaintext
/refactor into a multi-line written string. Show different approaches for all C++ standards.
```

Or:

```plaintext
/explain why this code has multiple vulnerabilities
```

Although slash commands still work for GitLab Duo Chat (Agentic), they are less important because
you can use [agentic capabilities](agentic_chat.md#gitlab-duo-chat-capabilities)
such as autonomous project search and file access, and multi-source analysis.

## Use GitLab Duo Chat (Agentic) capabilities

Use the [GitLab Duo Chat (Agentic)-specific capabilities](agentic_chat.md#gitlab-duo-chat-capabilities)
to help answer complex questions more comprehensively and efficiently, such as:

- Searching across projects.
- Creating and editing files.
- Analyzing information from multiple sources simultaneously.

## Related topics

- GitLab Duo Chat best practices [blog post](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [Videos on how to use Chat](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ)
- [Request a GitLab Duo Chat learning session](https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/476)
