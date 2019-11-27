# Packages **(PREMIUM)**

This document will guide you through adding another [package management system](../administration/packages/index.md) support to GitLab.

See already supported package types in [Packages documentation](../administration/packages/index.md)

Since GitLab packages' UI is pretty generic, it is possible to add basic new
package system support with solely backend changes. This guide is superficial and does
not cover the way the code should be written. However, you can find a good example
by looking at existing merge requests with Maven and NPM support:

- [NPM registry support](https://gitlab.com/gitlab-org/gitlab/merge_requests/8673).
- [Conan repository](https://gitlab.com/gitlab-org/gitlab/issues/8248).
- [Maven repository](https://gitlab.com/gitlab-org/gitlab/merge_requests/6607).
- [Instance level endpoint for Maven repository](https://gitlab.com/gitlab-org/gitlab/merge_requests/8757)

## Suggested contributions

The goal of the Package group is to build a set of features that, within three years, will allow ninety percent of our customers to store all of their packages in GitLab. To do that we need to ensure that we support the below package manager formats.

| Format | Use case |
| ------ | ------ |
| [Bower](https://gitlab.com/gitlab-org/gitlab/issues/36888) | Boost your front end development by hosting your own Bower components.  |
| [Chef](https://gitlab.com/gitlab-org/gitlab/issues/36889) | Configuration management with Chef using all the benefits of a repository manager. |
| [CocoaPods](https://gitlab.com/gitlab-org/gitlab/issues/36890) | Speed up development with Xcode and CocoaPods. |
| [Conan](https://docs.gitlab.com/ee/user/packages/conan_repository/) *12.6+* | A standardized way to share and version control C/C++ libraries across projects. |
| [Conda](https://gitlab.com/gitlab-org/gitlab/issues/36891) | Secure and private local Conda repositories. |
| [CRAN](https://gitlab.com/gitlab-org/gitlab/issues/36892) | Deploy and resolve CRAN packages for the R language. |
| [Debian](https://gitlab.com/gitlab-org/gitlab/issues/5835) | Host and provision Debian packages. |
| [Docker](https://docs.gitlab.com/ee/user/packages/container_registry/) *8.8+* | Host your own secure private Docker registries and proxy external Docker registries such as Docker Hub. |
| [Go](https://gitlab.com/gitlab-org/gitlab/issues/9773) | Resolve Go dependencies from and publish your Go packages to GitLab.  |
| [Helm](https://gitlab.com/gitlab-org/gitlab/issues/18997) | Manage your Helm Charts in GitLab and gain control over deployments to your Kubernetes cluster. |
| [Maven](https://docs.gitlab.com/ee/user/packages/maven_repository/index.html) *11.3+*| The GitLab Maven Repository enables every project in GitLab to have its own space to store Maven packages. |
| [npm](https://docs.gitlab.com/ee/user/packages/npm_registry/index.html) *11.7+* | Host your own node.js packages. |
| [NuGet](https://gitlab.com/gitlab-org/gitlab/issues/20050) *Planned for 12.7*| Host NuGet packages in GitLab, and pull libraries into your various Visual Studio .NET applications. |
| [Opkg](https://gitlab.com/gitlab-org/gitlab/issues/36894) | Optimize your work with OpenWrt using Opkg repositories. |
| [P2](https://gitlab.com/gitlab-org/gitlab/issues/36895) | Host all your Eclipse plugins in your own GitLab P2 repository. |
| [PHP Composer](https://gitlab.com/gitlab-org/gitlab/issues/15886) | Provision Composer packages from GitLab and access Packagist and other remote Composer metadata repositories. |
| [Puppet](https://gitlab.com/gitlab-org/gitlab/issues/36897) | Configuration management meets repository management with Puppet repositories. |
| [PyPi](https://gitlab.com/gitlab-org/gitlab/issues/10483) | Host PyPi distributions. |
| [RPM](https://gitlab.com/gitlab-org/gitlab/issues/5932) | Distribute RPMs directly from GitLab. |
| [RubyGems](https://gitlab.com/gitlab-org/gitlab/issues/803) | Use GitLab to host your own gems. |
| [SBT](https://gitlab.com/gitlab-org/gitlab/issues/36898) | Resolve dependencies from and deploy build output to SBT repositories when running SBT builds. |
| [Vagrant](https://gitlab.com/gitlab-org/gitlab/issues/36899) | Securely host your Vagrant boxes in local repositories. |

## General information

The existing database model requires the following:

- Every package belongs to a project.
- Every package file belongs to a package.
- A package can have one or more package files.
- The package model is based on storing information about the package and its version.

## API endpoints

Package systems work with GitLab via API. For example `ee/lib/api/npm_packages.rb`
implements API endpoints to work with NPM clients. So, the first thing to do is to
add a new `ee/lib/api/your_name_packages.rb` file with API endpoints that are
necessary to make the package system client to work. Usually that means having
endpoints like:

- GET package information.
- GET package file content.
- PUT upload package.

Since the packages belong to a project, it's expected to have project-level endpoint (remote)
for uploading and downloading them. For example:

```
GET https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
PUT https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
```

Group-level and instance-level endpoints are good to have but are optional.

## Naming conventions

To avoid name conflict for instance-level endpoints you will need to define a package naming convention
that gives a way to identify the project that the package belongs to. This generally involves using the project
id or full project path in the package name. See
[Conan's naming convention](../user/packages/conan_repository/index.md#package-recipe-naming-convention) as an example.

For group and project-level endpoints, naming can be less constrained, and it will be up to the group and project
members to be certain that there is no conflict between two package names, however the system should prevent
a user from reusing an existing name within a given scope.

Otherwise, naming should follow the package manager's naming conventions and include a validation in the `package.md`
model for that package type.

## File uploads

File uploads should be handled by GitLab Workhorse using object accelerated uploads. What this means is that
the workhorse proxy that checks all incoming requests to GitLab will intercept the upload request,
upload the file, and forward a request to the main GitLab codebase only containing the metadata
and file location rather than the file itself. An overview of this process can be found in the
[development documentation](uploads.md#workhorse-object-storage-acceleration).

In terms of code, this means a route will need to be added to the
[GitLab Workhorse project](https://gitlab.com/gitlab-org/gitlab-workhorse) for each level of remote being added
(instance, group, project). [This merge request](https://gitlab.com/gitlab-org/gitlab-workhorse/merge_requests/412/diffs)
demonstrates adding an instance-level endpoint for Conan to workhorse. You can also see the Maven project level endpoint
implemented in the same file.

Once the route has been added, you will need to add an additional `/authorize` version of the upload endpoint to your API file.
[Here is an example](https://gitlab.com/gitlab-org/gitlab/blob/398fef1ca26ae2b2c3dc89750f6b20455a1e5507/ee/lib/api/maven_packages.rb#L164)
of the additional endpoint added for Maven. The `/authorize` endpoint verifies and authorizes the request from workhorse,
then the normal upload endpoint is implemented below, consuming the metadata that workhorse provides in order to
create the package record. Workhorse provides a variety of file metadata such as type, size, and different checksum formats.

For testing purposes, you may want to [enable object storage](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/object_storage.md)
in your local development environment.

## Services and finders

Logic for performing tasks such as creating package or package file records or finding packages should not live
within the API file, but should live in services and finders. Existing services and finders should be used or
extended when possible to keep the common package logic grouped as much as possible.

## Configuration

GitLab has a `packages` section in its configuration file (`gitlab.rb`).
It applies to all package systems supported by GitLab. Usually you don't need
to add anything there.

Packages can be configured to use object storage, therefore your code must support it.

## Database and handling metadata

The current database model allows you to store a name and a version for each package.
Every time you upload a new package, you can either create a new record of `Package`
or add files to existing record. `PackageFile` should be able to store all file-related
information like the file `name`, `side`, `sha1`, etc.

If there is specific data necessary to be stored for only one package system support,
consider creating a separate metadata model. See `packages_maven_metadata` table
and `Packages::MavenMetadatum` model as an example for package specific data, and `packages_conan_file_metadata` table
and `Packages::ConanFileMetadatum` model as an example for package file specific data.

If there is package specific behavior for a given package manager, add those methods to the metadata models and
delegate from the package model.

Note that the existing package UI only displays information within the `packages_packages` and `packages_package_files`
tables. If the data stored in the metadata tables need to be displayed, a ~frontend change will be required.

## Authorization

There are project and group level permissions for `read_package`, `create_package`, and `destroy_package`. Each
endpoint should
[authorize the requesting user](https://gitlab.com/gitlab-org/gitlab/blob/398fef1ca26ae2b2c3dc89750f6b20455a1e5507/ee/lib/api/conan_packages.rb#L84)
against the project or group before continuing.

## Keep iterations small

When implementing a new package manager, it is easy to end up creating one large merge request containing all of the
necessary endpoints and services necessary to support basic usage. If this is the case, consider putting the
API endpoints behind a [feature flag](feature_flags/development.md) and
submitting each endpoint or behavior (download, upload, etc) in different merge requests to shorten the review
process.

### Potential MRs for any given package system

#### MVC MRs

These changes represent all that is needed to deliver a minimally usable package management system.

1. Empty file structure (API file, base service for this package)
1. Authentication system for 'logging in' to the package manager
1. Identify metadata and create applicable tables
1. Workhorse route for [object storage accelerated uploads](uploads.md#workhorse-object-storage-acceleration)
1. Endpoints required for upload/publish
1. Endpoints required for install/download
1. Endpoints required for remove/delete

#### Possible post-MVC MRs

These updates are not essential to be able to publish and consume packages, but may be desired as the system is
released for general use.

1. Endpoints required for search
1. Front end updates to display additional package information and metadata
1. Limits on file sizes
1. Tracking for metrics

## Exceptions

This documentation is just guidelines on how to implement a package manager to match the existing structure and logic
already present within GitLab. While the structure is intended to be extendable and flexible enough to allow for
any given package manager, if there is good reason to stray due to the constraints or needs of a given package
manager, then it should be raised and discussed within the implementation issue or merge request to work towards
the most efficient outcome.
