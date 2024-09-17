---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Neovim."
---

# Visual Studio troubleshooting

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the Visual Studio plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/new).

## Code Suggestions not displayed

1. Check all the steps in [Code Suggestions aren't displayed](../../user/project/repository/code_suggestions/troubleshooting.md#suggestions-not-displayed-in-microsoft-visual-studio) first.
1. Ensure you have properly [configured the extension](index.md#configure-the-extension).
1. Ensure you are working on a [supported language](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages).
1. If another extension provides similar suggestion or completion features, the extension might not return suggestions. To resolve this:
   1. Disable all other Visual Studio extensions.
   1. Confirm that you now receive Code Suggestions.
   1. Re-enable extensions one at a time, testing for Code Suggestions each time, to find the extension that conflicts.

## View more logs

More logs are available in the **GitLab Extension Output** window:

1. In Visual Studio, on the top bar, go to the **Tools > Options** menu.
1. Find the **GitLab** option, and set **Log Level** to **Debug**.
1. Go to **View > Output** to open the extension log. In the dropdown list, select **GitLab Extension** as the log filter.
1. Verify that the debug log contains similar output:

   ```shell
   14:48:21:344 GitlabProposalSource.GetCodeSuggestionAsync
   14:48:21:344 LsClient.SendTextDocumentCompletionAsync("GitLab.Extension.Test\TestData.cs", 34, 0)
   14:48:21:346 LS(55096): time="2023-07-17T14:48:21-05:00" level=info msg="update context"
   ```

## Error: unable to find last release

If you receive this error message, your commits are likely on the main branch of
your fork, instead of a feature branch:

```plaintext
buildtag.sh: Error: unable to find last release.
```

To resolve this issue:

1. Create a separate feature branch for your changes.
1. Cherry-pick your commits into your feature branch.
1. Retry your command.
