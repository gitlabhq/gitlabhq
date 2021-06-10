---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Store all of your packages in one GitLab project **(FREE)**

You can store all of your packages in one project's Package Registry. Rather than using
a GitLab repository to store code, you can use the repository to store all your packages.
Then you can configure your remote repositories to point to the project in GitLab.

You might want to do this because:

- You want to publish your packages in GitLab, but to a different project from where your code is stored.
- You want to group packages together in one project. For example, you might want to put all npm packages,
  or all packages for a specific department, or all private packages in the same project.
- When you install packages for other projects, you want to use one remote.
- You want to migrate your packages from a third-party package registry to a single place in GitLab and do not
  want to worry about setting up separate projects for each package.
- You want to have your CI/CD pipelines build all of your packages to one project, so the person responsible for
  validating packages can manage them all in one place.

## Example walkthrough

No functionality is specific to this feature. Instead, we're taking advantage of the functionality
of each package management system to publish different package types to the same place.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  Watch a video of how to add Maven, npm, and Conan packages to [the same project](https://youtu.be/ui2nNBwN35c).
- [View an example project](https://gitlab.com/sabrams/my-package-registry/-/packages).

## Store different package types in one GitLab project

Let's take a look at how you might create a public place to hold all of your public packages.

1. Create a new project in GitLab. The project doesn't require any code or content.
1. On the left sidebar, select **Project information**, and note the project ID.
1. Create an access token. All package types in the Package Registry are accessible by using
   [GitLab personal access tokens](../../profile/personal_access_tokens.md).
   If you're using CI/CD, you can use CI job tokens (`CI_JOB_TOKEN`) to authenticate.
1. Configure your local project and publish the package.

You can upload all types of packages to the same project, or
split things up based on package type or package visibility level.

### npm

If you're using npm, create an `.npmrc` file. Add the appropriate URL for publishing
packages to your project. Finally, add a section to your `package.json` file.

Follow the instructions in the
[GitLab Package Registry npm documentation](../npm_registry/index.md#authenticate-to-the-package-registry). After
you do this, you can publish your npm package to your project using `npm publish`, as described in the
[publishing packages](../npm_registry/index.md#publish-an-npm-package) section.

### Maven

If you are using Maven, you update your `pom.xml` file with distribution sections. These updates include the
appropriate URL for your project, as described in the [GitLab Maven Repository documentation](../maven_repository/index.md#project-level-maven-endpoint).
Then, you need to add a `settings.xml` file and [include your access token](../maven_repository/index.md#authenticate-with-a-personal-access-token-in-maven).
Now you can [publish Maven packages](../maven_repository/index.md#publish-a-package) to your project.

### Conan

For Conan, you need to add GitLab as a Conan registry remote. Follow the instructions in the
[GitLab Conan Repository docs](../conan_repository/index.md#add-the-package-registry-as-a-conan-remote).
Then, create your package using the plus-separated (`+`) project path as your Conan user. For example,
if your project is located at `https://gitlab.com/foo/bar/my-proj`,
[create your Conan package](../conan_repository/index.md) using `conan create . foo+bar+my-proj/channel`.
`channel` is your package channel (such as `stable` or `beta`).

After you create your package, you're ready to [publish your package](../conan_repository/index.md#publish-a-conan-package),
depending on your final package recipe. For example:

```shell
CONAN_LOGIN_USERNAME=<gitlab-username> CONAN_PASSWORD=<personal_access_token> conan upload MyPackage/1.0.0@foo+bar+my-proj/channel --all --remote=gitlab
```

### Composer

You can't publish a Composer package outside of its project. An [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/250633)
exists to implement functionality that allows you to publish such packages to other projects.

### All other package types

[All package types supported by GitLab](../index.md) can be published in
the same GitLab project. In previous releases, not all package types could
be published in the same project.
