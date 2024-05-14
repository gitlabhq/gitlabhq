---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Clone a Git repository to your local computer

When you clone a repository, a connection is created with a server and the files from the remote repository are downloaded to your computer.

This connection requires you to add credentials. You can either use SSH or HTTPS. SSH is recommended.

## Clone with SSH

Clone with SSH when you want to authenticate only one time.

1. Authenticate with GitLab by following the instructions in the [SSH documentation](../../user/ssh.md).
1. On the left sidebar, select **Search or go to** and find the project you want to clone.
1. On the project's overview page, in the upper-right corner, select **Code**, then copy the URL for **Clone with SSH**.
1. Open a terminal and go to the directory where you want to clone the files.
   Git automatically creates a folder with the repository name and downloads the files there.
1. Run this command:

   ```shell
   git clone <copied URL>
   ```

1. To view the files, go to the new directory:

   ```shell
   cd <new directory>
   ```

You can also
[clone a repository and open it directly in Visual Studio Code](../../user/project/repository/index.md#clone-and-open-in-visual-studio-code).

## Clone with HTTPS

Clone with HTTPS when you want to authenticate each time you perform an operation between your computer and GitLab.
[OAuth credential helpers](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers) can decrease
the number of times you must manually authenticate, making HTTPS a seamless experience.

1. On the left sidebar, select **Search or go to** and find the project you want to clone.
1. On the project's overview page, in the upper-right corner, select **Code**, then copy the URL for **Clone with HTTPS**.
1. Open a terminal and go to the directory where you want to clone the files.
1. Run the following command. Git automatically creates a folder with the repository name and downloads the files there.

   ```shell
   git clone <copied URL>
   ```

1. GitLab requests your username and password.

   If you have enabled two-factor authentication (2FA) on your account, you cannot use your account password. Instead, you can do one of the following:

   - [Clone using a token](#clone-using-a-token) with `read_repository` or `write_repository` permissions.
   - Install an [OAuth credential helper](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers).

   If you have not enabled 2FA, use your account password.

1. To view the files, go to the new directory:

   ```shell
   cd <new directory>
   ```

NOTE:
On Windows, if you enter your password incorrectly multiple times and an `Access denied` message appears,
add your namespace (username or group) to the path:
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

### Clone using a token

Clone with HTTPS using a token if:

- You want to use 2FA.
- You want to have a revocable set of credentials scoped to one or more repositories.

You can use any of these tokens to authenticate when cloning over HTTPS:

- [Personal access tokens](../../user/profile/personal_access_tokens.md).
- [Deploy tokens](../../user/project/deploy_tokens/index.md).
- [Project access tokens](../../user/project/settings/project_access_tokens.md).
- [Group access tokens](../../user/group/settings/group_access_tokens.md).

For example:

```shell
git clone https://<username>:<token>@gitlab.example.com/tanuki/awesome_project.git
```
