---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Protect your project with secret push protection'
---

If your application uses external resources, you usually need to authenticate your
application with a **secret**, like a token or key. If a secret is pushed to a
remote repository, anyone with access to the repository can impersonate you or your
application.

With secret push protection, if GitLab detects a secret in the commit history,
it can block a push to prevent a leak. Enabling secret push protection is a good
way to reduce the amount of time you spend reviewing your commits for sensitive data
and remediating leaks if they occur.

In this tutorial, you'll configure secret push protection and see what happens when you try to commit a fake secret.
You'll also learn how to skip secret push protection, in case you need to bypass a false positive.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
This tutorial is adapted from the following GitLab Unfiltered videos:

- [Introduction to Secret Push Protection](https://www.youtube.com/watch?v=SFVuKx3hwNI)
<!-- Video published on 2024-06-21 -->
- [Configuration - Enabling Secret Push Protection for your project](https://www.youtube.com/watch?v=t1DJN6Vsmp0)
<!-- Video published on 2024-06-23 -->
- [Skip Secret Push Protection](https://www.youtube.com/watch?v=wBAhe_d2DkQ)
<!-- Video published on 2024-06-04 -->

## Before you begin

Make sure you have the following before you complete this tutorial:

- A GitLab Ultimate subscription.
- A test project. You can use any project you like, but consider creating a test project specifically for this tutorial.
- Some familiarity with command-line Git.

Additionally, on GitLab Self-Managed only, ensure secret push protection is
[enabled on the instance](secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance).

## Enable secret push protection

To use secret push protection, you need to enable it for each project you want to protect.
Let's start by enabling it in a test project.

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Secure > Security configuration**.
1. Turn on the **Secret push protection** toggle.

Next, you'll test secret push protection.

## Try pushing a secret to your project

GitLab identifies secrets by matching specific patterns of letters, digits, and symbols. These patterns
are also used to identify the type of secret.
Let's test this feature by adding the fake secret `glpat-12345678901234567890` to our project: <!-- gitleaks:allow -->

1. In the project, check out a new branch:

   ```shell
   git checkout -b push-protection-tutorial
   ```

1. Create a new file with the following content, removing the spaces before and after
   the `-` to match the exact format of a personal access token:

   ```plaintext
   hello, world!
   glpat - 12345678901234567890
   ```

1. Commit the file to your branch:

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

   The secret is now entered into the commit history. Note that secret push protection doesn't stop you from committing a secret; it only alerts you when you push.

1. Push the changes to GitLab. You should see something like this:

   ```shell
   $ git push
   remote: GitLab:
   remote: PUSH BLOCKED: Secrets detected in code changes
   remote:
   remote: Secret push protection found the following secrets in commit: 123abc
   remote: -- myFile.txt:2 | GitLab Personal Access Token
   remote:
   remote: To push your changes you must remove the identified secrets.
   To gitlab.com:
    ! [remote rejected] push-protection-tutorial -> main (pre-receive hook declined)
   ```

   GitLab detects the secret and blocks the push. From the error report, we can see:

   - The commit that contains the secret (`123abc`)
   - The file and line number that contains the secret (`myFile.txt:2`)
   - The type of secret (`GitLab Personal Access Token`)

If we had successfully pushed our changes, we would need to spend considerable time and effort to revoke and replace the secret.
Instead, we can [remove the secret from the commit history](remove_secrets_tutorial.md) and rest easy knowing we stopped the
secret from being leaked.

## Skip secret push protection

Sometimes you need to push a commit, even if secret push protection has identified a secret. This can happen when GitLab detects a false positive.
To demonstrate, we'll push our last commit to GitLab.

### With a push option

You can use a push option to skip secret detection:

- Push your commit with the `secret_detection.skip_all` option:

  ```shell
  git push -o secret_detection.skip_all
  ```

Secret detection is skipped, and the changes are pushed to the remote.

### With a commit message

If you don't have access to the command line, or you don't want to use a push option:

- Add the string `[skip secret push protection]` to the commit message. For example:

  ```shell
  git commit --amend -m "Add fake secret [skip secret push protection]"
  ```

You only need to add `[skip secret push protection]` to one of the commit messages in order to push your changes, even if there are multiple commits.

## Next steps

Consider enabling [pipeline secret detection](pipeline/_index.md) to further improve the security of your projects.
