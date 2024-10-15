---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab remote URL format

In VS Code, you can browse GitLab repositories
[in read-only mode](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/README.md#browse-a-repository-without-cloning)
with a custom remote URL.

GitLab remote URLs require these parameters:

- `instanceUrl`: The GitLab instance URL, not including `https://` or `http://`.
  - If the GitLab instance [uses a relative URL](../../install/relative_url.md), include the relative URL in the URL.
  - For example, the URL for the `main` branch of the project `templates/ui` on the instance `example.com/gitlab` is
    `gitlab-remote://example.com/gitlab/<label>?project=templates/ui&ref=main`.
- `label`: The text Visual Studio Code uses as the name of this workspace folder:
  - It must appear immediately after the instance URL.
  - It can't contain unescaped URL components, such as `/` or `?`.
  - For an instance installed at the domain root, such as `https://gitlab.com`, the label must be the first path element.
  - For URLs that refer to the root of a repository, the label must be the last path element.
  - VS Code treats any path elements that appear after the label as a path inside the repository. For example,
    `gitlab-remote://gitlab.com/GitLab/app?project=gitlab-org/gitlab&ref=master` refers to the `app` directory of
    the `gitlab-org/gitlab` repository on GitLab.com.
- `projectId`: Can be either the numeric ID (like `5261717`) or the namespace (`gitlab-org/gitlab-vscode-extension`) of the
  project. If your instance uses a reverse proxy, specify `projectId` with the numeric ID. For more information, see
  [issue 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775).
- `gitReference`: The repository branch or commit SHA.

The parameters are then placed together in this order:

```plaintext
gitlab-remote://<INSTANCE_URL>/<LABEL>?project=<PROJECT_ID>&ref=<GIT_REFERENCE>
```

For example, the `projectID` for the main GitLab project is `278964`, so the remote URL for the main GitLab project is:

```plaintext
gitlab-remote://gitlab.com/<LABEL>?project=278964&ref=master
```

## Browse a repository in read-only mode

With this extension, you can browse a GitLab repository in read-only mode without cloning it.

Prerequisites:

- You have [registered an access token](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup) for that GitLab instance.

To browse a GitLab repository in read-only mode:

1. Open the command palette by pressing <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>.
1. Run the **GitLab: Open Remote Repository** command.
1. Select **Open in current window**, **Open in new window**, or **Add to workspace**.
1. To add a repository, select `Enter gitlab-remote URL`, then enter the `gitlab-remote://` URL for your desired project.
1. To view a repository you've already added, select **Choose a project**, then select your desired project from the dropdown list.
1. In the dropdown list, select the Git branch you want to view, then press <kbd>Enter</kbd> to confirm.

To add a `gitlab-remote` URL to your workspace file, see
[Workspace file](https://code.visualstudio.com/docs/editor/multi-root-workspaces#_workspace-file) in the VS Code documentation.
