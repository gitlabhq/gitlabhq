---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Create a push mirror to passively receive changes from an upstream repository."
title: Push mirroring
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

A _push mirror_ is a downstream repository that [mirrors](_index.md) the commits made
to the upstream repository. Push mirrors passively receive copies of the commits made to the
upstream repository. To prevent the mirror from diverging from the upstream
repository, don't push commits directly to the downstream mirror. Push commits to
the upstream repository instead.

While [pull mirroring](pull.md) periodically retrieves updates from the upstream repository,
push mirrors only receive changes when:

- Commits are pushed to the upstream GitLab repository.
- An administrator [force-updates the mirror](_index.md#force-an-update).

When you push a change to the upstream repository, the push mirror receives it in five minutes, or one minute if the setting **Only mirror protected branches** is on.

When a branch is merged into the default branch and deleted in the source project,
it is deleted from the remote mirror on the next push. Branches with unmerged
changes are kept. If a branch diverges, the **Mirroring repositories** section
displays an error.

[GitLab Silent Mode](../../../../administration/silent_mode/_index.md) disables pushing to,
and pulling from, remote mirrors.

## Configure push mirroring

To set up push mirroring for an existing project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Mirroring repositories**.
1. Enter a repository URL.
1. In the **Mirror direction** dropdown list, select **Push**.
1. Select an **Authentication method**. For more information, see
   [Authentication methods for mirrors](_index.md#authentication-methods-for-mirrors).
1. Select **Only mirror protected branches**, if necessary.
1. Select **Keep divergent refs**, if desired.
1. To save the configuration, select **Mirror repository**.

### Configure push mirrors through the API

You can also create and modify project push mirrors through the
[remote mirrors API](../../../../api/remote_mirrors.md).

## Keep divergent refs

By default, if any ref (branch or tag) on the remote (downstream) mirror diverges from the
local repository, the upstream repository overwrites any changes on the remote:

1. A repository mirrors `main` and `develop` branches to a remote.
1. A new commit is added to `develop` on the remote mirror.
1. The next push updates the remote mirror to match the upstream repository.
1. The new commit added to `develop` on the remote mirror is lost.

If **Keep divergent refs** is selected, the changes are handled differently:

1. Updates to the `develop` branch on the remote mirror are skipped.
1. The `develop` branch on the remote mirror preserves the commit that does not
   exist on the upstream repository. Any refs that exist in the remote mirror,
   but not the upstream, are left untouched.
1. The update is marked failed.

After you create a mirror, you can only modify the value of **Keep divergent refs**
through the [remote mirrors API](../../../../api/remote_mirrors.md).

## Set up a push mirror from GitLab to GitHub

To configure a mirror from GitLab to GitHub:

1. Create a [GitHub fine-grained personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#fine-grained-personal-access-tokens)
   with at least read and write permissions on the [repository contents](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#repository-permissions-for-contents). If your
   repository contains a `.github/workflows` directory, you must also grant
   read and write access for the [Workflows](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#repository-permissions-for-workflows).
   For a more fine-grained access, you can configure your token to only apply
   to the specific repository.
1. Enter a **Git repository URL** with this format, changing the variables as needed:

   ```plaintext
   https://github.com/GROUP/PROJECT.git
   ```

   - `GROUP`: The group on GitHub.
   - `PROJECT`: The project on GitHub.
1. For **Username**, enter the username of the owner of the personal access token.
1. For **Password**, enter your GitHub personal access token.
1. Select **Mirror repository**.

The mirrored repository is listed. For example:

```plaintext
https://*****:*****@github.com/<your_github_group>/<your_github_project>.git
```

The repository pushes shortly thereafter. To force a push, select **Update now** (**{retry}**).

## Set up a push mirror from GitLab to AWS CodeCommit

AWS CodeCommit push mirroring is the best way to connect GitLab repositories to
AWS CodePipeline. GitLab is not yet supported as one of their Source Code Management (SCM) providers.
Each new AWS CodePipeline needs significant AWS infrastructure setup. It also
requires an individual pipeline per branch.

If AWS CodeDeploy is the final step of a CodePipeline, you can, instead combine
these tools to create a deployment:

- GitLab CI/CD pipelines.
- The AWS CLI in the final job in `.gitlab-ci.yml` to deploy to CodeDeploy.

NOTE:
GitLab-to-AWS-CodeCommit push mirroring cannot use SSH authentication until [GitLab issue 34014](https://gitlab.com/gitlab-org/gitlab/-/issues/34014) is resolved.

To set up a mirror from GitLab to AWS CodeCommit:

1. In the AWS IAM console, create an IAM user.
1. Add the following least privileges permissions for repository mirroring as an **inline policy**.

   The Amazon Resource Names (ARNs) must explicitly include the region and account. This IAM policy
   grants privilege for mirroring access to two sample repositories. These permissions have
   been tested to be the minimum (least privileged) required for mirroring:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "MinimumGitLabPushMirroringPermissions",
               "Effect": "Allow",
               "Action": [
                   "codecommit:GitPull",
                   "codecommit:GitPush"
               ],
               "Resource": [
                 "arn:aws:codecommit:us-east-1:111111111111:MyDestinationRepo",
                 "arn:aws:codecommit:us-east-1:111111111111:MyDemo*"
               ]
           }
       ]
   }
   ```

1. After the user is created, select the AWS IAM user name.
1. Select the **Security credentials** tab.
1. Under **HTTPS Git credentials for AWS CodeCommit**, select **Generate credentials**.

   NOTE:
   This Git user ID and password is specific to communicating with CodeCommit. Do
   not confuse it with the IAM user ID or AWS keys of this user.

1. Copy or download the special Git HTTPS user ID and password.
1. In the AWS CodeCommit console, create a new repository to mirror from your GitLab repository.
1. Open your new repository, in the upper-right corner, select **Code > Clone HTTPS** (not **Clone HTTPS (GRC)**).
1. In GitLab, open the repository to be push-mirrored.
1. Select **Settings > Repository**, and then expand **Mirroring repositories**.
1. Fill in the **Git repository URL** field using this format, replacing
   `<aws-region>` with your AWS region, and
   `<your_codecommit_repo>` with the name of your repository in CodeCommit:

   ```plaintext
   https://git-codecommit.<aws-region>.amazonaws.com/v1/repos/<your_codecommit_repo>
   ```

1. For **Authentication method**, select **Username and Password**.
1. For **Username**, enter the AWS **special HTTPS Git user ID**.
1. For **Password**, enter the special IAM Git clone user ID password created earlier in AWS.
1. Leave the option **Only mirror protected branches** for CodeCommit. It pushes more
   frequently (from every five minutes to every minute).

   CodePipeline requires individual pipeline setups for named branches you want
   to have a AWS CI setup for. Because feature branches with dynamic names are unsupported,
   configuring **Only mirror protected branches** doesn't cause flexibility problems
   with CodePipeline integration. You must also protect all the named branches you
   want to build CodePipelines for.

1. Select **Mirror repository**. You should see the mirrored repository appear:

   ```plaintext
   https://*****:*****@git-codecommit.<aws-region>.amazonaws.com/v1/repos/<your_codecommit_repo>
   ```

To test mirroring by forcing a push, select **Update now** (the half-circle arrows).
If **Last successful update** shows a date, you have configured mirroring correctly.
If it isn't working correctly, a red `error` tag appears, and shows the error message as hover text.

## Set up a push mirror to another GitLab instance with 2FA activated

1. On the destination GitLab instance, create a
   [personal access token](../../../profile/personal_access_tokens.md) with `write_repository` scope.
1. On the source GitLab instance:
   1. Enter the **Git repository URL** using this format:
      `https://<destination host>/<your_gitlab_group_or_name>/<your_gitlab_project>.git`.
   1. Enter the **Username** `oauth2`.
   1. Enter the **Password**. Use the GitLab personal access token created on the
      destination GitLab instance.
   1. Select **Mirror repository**.

## Related topics

- [Troubleshooting](troubleshooting.md) for repository mirroring.
- [Remote mirrors API](../../../../api/remote_mirrors.md)
