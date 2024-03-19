---
stage: none
group: Contributor Success
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Beta program

The GitLab Beta program provides GitLab Beta program members with early access to exclusive features.
This page lists features available for testing as part of the program.

WARNING:
The GitLab Beta Program is not operational yet. This page is in draft & in preparation for an upcoming launch.

These features may not be ready for production use and follow the [Experimental or Beta policy](../../policy/experiment-beta-support.md) of GitLab.

## Git suggestions

- [GitLab CLI feature documentation](../../editor_extensions/gitlab_cli/index.md#gitlab-duo-commands)
- [Feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409636)

<!-- Copied from ../../editor_extensions/gitlab_cli/index.md#gitlab-duo-commands -->
Use `glab ask` to ask questions about `git` commands. It can help you remember a
command you forgot, or provide suggestions on how to run commands to perform other tasks.

**Get started:**

1. To install GLab, see [installation instructions](https://gitlab.com/gitlab-org/cli/#installation).
1. Set up [GitLab ClI Authentication](https://gitlab.com/gitlab-org/cli/#authentication).
1. Use `glab ask git` to generate a Git command with AI in your command line:

   ```shell
   glab ask git <your_question>
   ```

   Examples:
   - `glab ask git how do I know the branch I'm on`
   - `glab ask git how to create a new branch with only a few particular commits`
   - `glab ask git how to find commits from removed branches`

   After it replies, you can execute the command it generates.

## Code explanation

- [Code explanation feature documentation](../../user/ai_features.md#explain-code-in-the-web-ui-with-code-explanation)
- [Feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/407285)

<!-- from ../../user/ai_features.md#explain-code-in-the-web-ui-with-code-explanation -->
With the help of a large language model, GitLab Duo can explain code in natural language.

**Get started:**

1. On the left sidebar, select **Search or go to** and find your project.
1. Select any file in your project that contains code.
1. On the file, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the
   first line of your selection to view it. This sends the selected code, together with a prompt,
   to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.

## GitLab Duo Chat

- [GitLab Duo Chat feature documentation](../../user/gitlab_duo_chat.md)
- [Feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)

<!-- from ../../user/gitlab_duo_chat.md -->
GitLab Duo Chat is your personal AI-powered assistant for boosting productivity.
It can assist various tasks of your daily work with the AI-generated content.

**Get started:**

1. On the left sidebar, select **Help** (**{question-o}**) > **GitLab Duo Chat**.
1. GitLab Duo Chat opens in the right sidebar. Enter your question or try one of these examples:
   - `Where to find docs for CI job artifacts configuration?`
   - `Explain the concept of a 'fork' in a concise manner.`
   - `Provide step-by-step instructions on how to reset a user's password.`

## Generate issue description

- [Generate issue description feature documentation](../../user/ai_features.md#summarize-an-issue-with-issue-description-generation)
- [Feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409844)

<!-- from ../../user/ai_features.md#summarize-an-issue-with-issue-description-generation -->
Write a short summary of an issue and GitLab Duo generates a description for you.

**Get started:**

1. Create a new issue.
1. Above the **Description** field, select **AI actions > Generate issue description**. Hint: AI actions can be found next to **Preview**
1. Write a short description and select **Submit**.

   GitLab Duo replaces the issue description with AI-generated text.

## Test generation

- [Tests generation feature documentation](../../user/gitlab_duo_chat.md#write-tests-in-the-ide)
- [Feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)

<!-- ../../user/gitlab_duo_chat.md#write-tests-in-the-ide -->
`/tests` is a special command to generate a testing suggestion for the selected code in your editor.
This feature is available in VS Code and the Web IDE only.

**Get started:**

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to your file or directory.
1. Select **Edit > Open in Web IDE**.
1. Select code inside file.
1. On the left sidebar of Web IDE select the **GitLab Duo Chat** icon.
1. Enter `/tests` in AI dialog.

   You can add additional instructions:
   - `/tests using RSpec framework`
   - `/tests markdown syntax`
1. GitLab Duo Chat returns a code block with an example RSpec test you can use for the code you selected.
