# Project as a package registry

Using the features of the package registry, it is possible to use one project to store all of your packages.

This guide mirrors the creation of [this package registry](https://gitlab.com/sabrams/my-package-registry).

For the video version, see [Single Project Package Registry Demo](https://youtu.be/ui2nNBwN35c).

## How does this work?

You might be wondering "how is it possible to upload two packages from different codebases to the same project on GitLab?".

It is easy to forget that a package on GitLab belongs to a project, but a project does not have to be a code repository.
The code used to build your packages can be stored anywhere - maybe it is another project on GitLab, or maybe a completely
different system altogether. All that matters is that when you configure your remote repositories for those packages, you
point them at the same project on GitLab.

## Why would I do this?

There are a few reasons you might want to publish all your packages to one project on GitLab:

1. You want to publish your packages on GitLab, but to a project that is different from where your code is stored.
1. You would like to group packages together in ways that make sense for your usage (all NPM packages in one project,
   all packages being used by a specific department in one project, all private packages in one project, etc.)
1. You want to use one remote for all of your packages when installing them into other projects.
1. You would like to migrate your packages to a single place on GitLab from a third-party package registry and do not
   want to worry about setting up separate projects for each package.
1. You want to have your CI pipelines build all of your packages to one project so the individual responsible for
validating packages can manage them all in one place.

## Example walkthrough

There is no functionality specific to this feature. All we are doing is taking advantage of functionality available in each
of the package management systems to publish packages of different types to the same place.

Let's take a look at how you might create a public place to hold all of your public packages.

### Create a project

First, create a new project on GitLab. It does not have to have any code or content. Make note of the project ID
displayed on the project overview page, as you will need this later.

### Create an access token

All of the package repositories available on the GitLab package registry are accessible using [GitLab personal access
tokens](../../profile/personal_access_tokens.md).

While using CI, you can alternatively use CI job tokens (`CI_JOB_TOKEN`) to authenticate.

### Configure your local project for the GitLab registry and upload

There are many ways to use this feature. You can upload all types of packages to the same project,
split things up based on package type, or package visibility level.

The purpose of this tutorial is to demonstrate the root idea that one project can hold many unrelated
packages, and to allow you to discover the best way to use this functionality yourself.

#### NPM

If you are using NPM, this involves creating an `.npmrc` file and adding the appropriate URL for uploading packages
to your project using your project ID, then adding a section to your `package.json` file with a similar URL.

Follow
the instructions in the [GitLab NPM Registry documentation](../npm_registry/index.md#authenticating-to-the-gitlab-npm-registry). Once
you do this, you will be able to push your NPM package to your project using `npm publish`, as described in the
[uploading packages](../npm_registry/index.md#uploading-packages) section of the docs.

#### Maven

If you are using Maven, this involves updating your `pom.xml` file with distribution sections, including the
appropriate URL for your project, as described in the [GitLab Maven Repository documentation](../maven_repository/index.md#project-level-maven-endpoint).
Then, you need to add a `settings.xml` file and [include your access token](../maven_repository/index.md#authenticating-with-a-personal-access-token).
Now you can [deploy Maven packages](../maven_repository/index.md#uploading-packages) to your project.

#### Conan

For Conan, first you need to add GitLab as a Conan registry remote. Follow the instructions in the [GitLab Conan Repository docs](../conan_repository/index.md#adding-the-gitlab-package-registry-as-a-conan-remote)
to do so. Then, create your package using the plus-separated (`+`) project path as your Conan user. For example,
if your project is located at `https://gitlab.com/foo/bar/my-proj`, then you can [create your Conan package](../conan_repository/index.md)
using `conan create . foo+bar+my-proj/channel`, where `channel` is your package channel (`stable`, `beta`, etc.). Once your package
is created, you are ready to [upload your package](../conan_repository/index.md#uploading-a-package) depending on your final package recipe. For example:

```sh
CONAN_LOGIN_USERNAME=<gitlab-username> CONAN_PASSWORD=<personal_access_token> conan upload MyPackage/1.0.0@foo+bar+my-proj/channel --all --remote=gitlab
```
