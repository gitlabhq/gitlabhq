---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Store all of your packages in one GitLab project
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Store packages from multiple sources in one project's package registry and configure your remote repositories to
point to this project in GitLab.

Use this approach when you want to:

- Publish packages to GitLab in a different project than where your code is stored.
- Group packages together in one project (for example, all npm packages, all packages for a specific
  department, or all private packages in the same project).
- Use one remote repository when installing packages for other projects.
- Migrate packages from a third-party package registry to a single location in GitLab.
- Have CI/CD pipelines build all packages to one project so you can manage packages in the same location.

## Example walkthrough

Use each package management system
to publish different package types in the same place.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  Watch a video of how to add Maven, npm, and Conan packages to [the same project](https://youtu.be/ui2nNBwN35c).
- [View an example project](https://gitlab.com/sabrams/my-package-registry/-/packages).

## Store different package types in one GitLab project

Let's take a look at how you might create one project to host all of your packages:

1. Create a new project in GitLab. The project doesn't require any code or content.
1. On the left sidebar, select **Project overview**, and note the project ID.
1. Create an access token for authentication. All package types in the package registry can be published by using:

   - A [personal access token](../../profile/personal_access_tokens.md).
   - A [group access token](../../../user/group/settings/group_access_tokens.md) or [project access token](../../../user/project/settings/project_access_tokens.md).
   - A [CI/CD job token](../../../ci/jobs/ci_job_token.md) (`CI_JOB_TOKEN`) in a CI/CD job.
     The project's [job token allowlist](../../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) should list any projects publishing to this project's registry.

   If the project is private, downloading packages requires authentication as well.

1. Configure your local project and publish the package.

You can upload all package types to the same project, or
split up packages based on package type or visibility level.

### npm

For npm packages:

- Create an [`.npmrc` file](../npm_registry/_index.md#with-the-npmrc-file) to configure the registry URL.
- Scope your packages with the `publishConfig` option in the `package.json` file of your project.
- Publish packages with `npm publish`.

For more information, see [npm packages in the package registry](../npm_registry/_index.md).

### Maven

For Maven packages:

1. Update your `pom.xml` file with `repository` and `distributionManagement` sections to configure the registry URL.
1. Add a `settings.xml` file and include your access token.
1. Publish packages with `mvn deploy`.

For more information, see [Maven packages in the package registry](../maven_repository/_index.md).

### Conan 1

For Conan 1:

- Add the GitLab package registry as a Conan registry remote.
- [Create your Conan 1 package](build_packages.md#build-a-conan-1-package) using the plus-separated (`+`) project path as your Conan user. For example,
  if your project is located at `https://gitlab.com/foo/bar/my-proj`,
  create your Conan package using `conan create . foo+bar+my-proj/channel`. `channel` is the package channel, such as `beta` or `stable`:

   ```shell
   CONAN_LOGIN_USERNAME=<gitlab-username> CONAN_PASSWORD=<personal_access_token> conan upload MyPackage/1.0.0@foo+bar+my-proj/channel --all --remote=gitlab
   ```

- Publish your package with `conan upload` or your package recipe.

For more information, see [Conan 1 packages in the package registry](../conan_1_repository/_index.md).

### Conan 2

For Conan 2:

- Add the GitLab package registry as a Conan registry remote.
- [Create your Conan 2 package](build_packages.md#conan-2).
- Publish your package with `conan upload` or your package recipe.

For more information, see [Conan 2 packages in the package registry](../conan_2_repository/_index.md).

### Composer

You can't publish a Composer package outside of its project. Support for publishing Composer packages
in other projects is proposed in [issue 250633](https://gitlab.com/gitlab-org/gitlab/-/issues/250633).

### All other package types

[All package types supported by GitLab](../_index.md) can be published in
the same GitLab project. In previous releases, not all package types could
be published in the same project.
