---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Configure the Gitpod development environment
---

To contribute code without the overhead of setting up a local development environment,
you should use Gitpod.

## Use Gitpod to contribute without a local environment setup

Set aside about 15 minutes to launch the GDK in Gitpod.

1. [Launch the GDK in Gitpod](https://gitpod.io/#https://gitlab.com/gitlab-community/gitlab/-/tree/master/).
1. Select **Continue with GitLab** to start a Gitpod environment for this fork.
1. If this is your first time using Gitpod, create a free account and connect it
   to your GitLab account:
   1. Select **Authorize** when prompted to **Authorize Gitpod.io to use your account?**.
   1. On the **Welcome to Gitpod** screen, enter your name and select whether you would like
      to **Connect with LinkedIn** or **Continue with 10 hours per month**.
   1. Choose the `Browser` version of VS Code when prompted to **Choose an editor**.
   1. Continue through the settings until the **New Workspace** screen.
1. On the **New Workspace** screen, before you select **Continue**:
   - Leave the default repository URL: `gitlab.com/gitlab-community/gitlab/-/tree/master/`.
   - Select your preferred **Editor**.

      The examples in this tutorial use Visual Studio Code (VS Code) as the editor,
      sometimes referred to as an integrated development environment (IDE).

   - Leave the default **Class**: `Standard`.

1. Wait a few minutes for Gitpod to launch.

   You can begin exploring the codebase and making your changes after the editor you chose has launched.

1. You will need to wait a little longer for GitLab to be available to preview your changes.

   When the GitLab GDK is ready, the **Terminal** panel in Gitpod will return
   a URL local to the Gitpod environment:

   ```shell
   => GitLab available at http://127.0.0.1:3000.
   ```

   Select the `http://127.0.0.1:3000` to open the GitLab development environment in a new browser tab.

1. After the environment loads, sign in as the default `root` user and
   follow the prompts to change the default password:

   - Username: `root`
   - Password: `5iveL!fe`

After the Gitpod editor is ready, continue to [Change the code with Gitpod](contribute-gitpod.md).
