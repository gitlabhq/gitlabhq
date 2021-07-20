---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Using Git submodules with GitLab CI/CD **(FREE)**

Use [Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to keep
a Git repository as a subdirectory of another Git repository. You can clone another
repository into your project and keep your commits separate.

## Configure the `.gitmodules` file

When you use Git submodules, your project should have a file named `.gitmodules`.
You might need to modify it to work in a GitLab CI/CD job.

For example, your `.gitmodules` configuration might look like the following if:

- Your project is located at `https://gitlab.com/secret-group/my-project`.
- Your project depends on `https://gitlab.com/group/project`, which you want
  to include as a submodule.
- You check out your sources with an SSH address like `git@gitlab.com:secret-group/my-project.git`.

```ini
[submodule "project"]
  path = project
  url = ../../group/project.git
```

When your submodule is on the same GitLab server, you should use relative URLs in
your `.gitmodules` file. Then you can clone with HTTPS in all your CI/CD jobs. You
can also use SSH for all your local checkouts.

The above configuration instructs Git to automatically deduce the URL to
use when cloning sources. Git uses the same configuration for both HTTPS and SSH.
GitLab CI/CD uses HTTPS for cloning your sources, and you can continue to use SSH
to clone locally.

For submodules not located on the same GitLab server, use the full URL:

```ini
[submodule "project-x"]
  path = project-x
  url = https://gitserver.com/group/project-x.git
```

## Use Git submodules in CI/CD jobs

To make submodules work correctly in CI/CD jobs:

1. Make sure you use [relative URLs](#configure-the-gitmodules-file)
   for submodules located in the same GitLab server.
1. You can set the `GIT_SUBMODULE_STRATEGY` variable to either `normal` or `recursive`
   to tell the runner to [fetch your submodules before the job](runners/configure_runners.md#git-submodule-strategy):

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
   ```
