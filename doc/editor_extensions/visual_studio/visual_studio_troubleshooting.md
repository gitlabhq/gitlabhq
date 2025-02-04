---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Neovim."
title: Visual Studio troubleshooting
---

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the Visual Studio plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/new).

For troubleshooting the extension for GitLab Duo Code Suggestions,
see [Troubleshooting Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md#microsoft-visual-studio-troubleshooting)..

## View more logs

More logs are available in the **GitLab Extension Output** window:

1. In Visual Studio, on the top bar, go to the **Tools > Options** menu.
1. Find the **GitLab** option, and set **Log Level** to **Debug**.
1. Go to **View > Output** to open the extension log. In the dropdown list, select **GitLab Extension** as the log filter.
1. Verify that the debug log contains similar output:

   ```shell
   GetProposalManagerAsync: Code suggestions enabled. ContentType (csharp) or file extension (cs) is supported.
   GitlabProposalSourceProvider.GetProposalSourceAsync
   ```

### View activity log

If your extension does not load or crashes, check the activity log for errors.
Your activity log is available in this location:

```plaintext
C:\Users\WINDOWS_USERNAME\AppData\Roaming\Microsoft\VisualStudio\VS_VERSION\ActivityLog.xml
```

Replace these values in the directory path:

- `WINDOWS_USERNAME`: Your Windows username.
- `VS_VERSION`: The version of your Visual Studio installation.
