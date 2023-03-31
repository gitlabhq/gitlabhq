---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Workflow extension for VS Code **(FREE)**

The [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
integrates GitLab with Visual Studio Code. You can decrease context switching and
do more day-to-day tasks in Visual Studio Code, such as:

- [View issues](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#browse-issues-review-mrs).
- Run [common commands](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#commands)
  from the Visual Studio Code [command palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette).
- Create and [review](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#merge-request-reviews)
  merge requests directly from Visual Studio Code.
- [Validate your GitLab CI/CD configuration](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#validate-gitlab-cicd-configuration).
- [View the status of your pipeline](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#information-about-your-branch-pipelines-mr-closing-issue).
- [View the output of CI/CD jobs](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#view-the-job-output).
- [Create](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#create-snippet)
  and paste snippets to, and from, your editor.
- [Browse repositories](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#browse-a-repository-without-cloning)
  without cloning them.

## Download the extension

Download the extension from the [Visual Studio Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).

## Configure the extension

After you [download the extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
you can [configure](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#extension-settings):

- [Features to display or hide](https://gitlab.com/gitlab-org/gitlab-vscode-extension#extension-settings).
- [Self-signed certificate](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#self-signed-certificates) information.

## Code Suggestions (Closed Beta) **(ULTIMATE)**

> [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Closed Beta](/ee/policy/alpha-beta-support.md#closed-beta-features).

FLAG:
This feature is in Closed Beta. To request to join the Closed Beta, [fill out this form](https://forms.gle/cbjqJhLGV1i7t6Sd8).

Code Suggestions empower your developers to code more efficiently by suggesting code
as they type. Depending on the cursor position, the extension either:

- Provides entire code snippets, like generating functions.
- Completes the current line.

Developers can press <kbd>Tab</kbd> to accept suggestions.

Code Suggestions support the following languages with the highest confidence:

- C
- C++
- Java
- JavaScript
- Go
- Python

Suggestions may be mixed for other languages.

<div class="video-fallback">
  See an end-to-end demo: <a href="https://www.youtube.com/watch?v=WnxBYxN2-p4">How to get started with GitLab Code Suggestions in VS Code</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/WnxBYxN2-p4" frameborder="0" allowfullscreen> </iframe>
</figure>

### Enable Code Suggestions **(ULTIMATE)**

Prerequisites:

- You have been granted access to the Closed Beta.
- You have [created a personal access token](../../profile/personal_access_tokens.md#create-a-personal-access-token)
  with the `read_api` and `read_user` scopes.

To enable Code Suggestions in VS Code:

1. Download and configure the
   [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
   for Visual Studio Code.
1. In **GitLab: Add Account to VS Code on Mac**, add your GitLab work account to the VS Code extension:
   - In macOS, press <kbd>Shift</kbd> + <kbd>Command</kbd> + <kbd>P</kbd>.
   - In Windows, press <kbd>Shift</kbd> + <kbd>Control</kbd> + <kbd>P</kbd>
1. Provide your GitLab instance URL. A default is provided.
1. Provide your personal access token.
1. After your GitLab account connects successfully, in the left sidebar, select **Extensions**.
1. Find the **GitLab workflow** extension, select **Settings** (**{settings}**), and select **Extension Settings**.
1. Enable **GitLab › AI Assisted Code Suggestions**.

Start typing and receive suggestions for your GitLab projects.

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab-vscode-extension` issue queue](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues).

## Related topics

- [Download the extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- [Extension documentation](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/README.md)
- [View source code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
