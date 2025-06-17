---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Set up your authoring environment
---

Set up your environment for writing and previewing GitLab documentation.

You can use whichever tools you're most comfortable with.
Use this guidance to help ensure you have the tools you need.

- Install a code editor, like VS Code or Sublime Text, to work with Markdown files.
- [Install Git](../../topics/git/how_to_install_git/_index.md) and
  [add an SSH key to your GitLab profile](../../user/ssh.md#add-an-ssh-key-to-your-gitlab-account).
- Install documentation [linters](testing/_index.md) and configure them in your code editor:
  - [markdownlint](testing/markdownlint.md)
  - [Vale](testing/vale.md)
- If you're using VS Code, [install the GitLab Workflow extension](../../editor_extensions/visual_studio_code/setup.md)
  to get GitLab Duo Chat and other GitLab features in your editor.
- [Set up the docs site to build locally](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/setup.md).
- Optional. Install the [Conventional Comments](https://gitlab.com/conventionalcomments/conventional-comments-button) extension for Chrome.
  The plugin adds **Conventional Comment** buttons to GitLab comments.

After you're comfortable with your toolset, you can [install the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/_index.md), a fully functional self-managed version of GitLab.

You can use GDK to:

- [Preview documentation changes locally](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_docs.md).
- [Preview code changes locally](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/preview_gitlab_changes.md).
