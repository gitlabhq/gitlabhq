---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Packages

This document guides you through adding another [package management system](../administration/packages/index.md) support to GitLab.

See already supported package types in [Packages documentation](../administration/packages/index.md)

Since GitLab packages' UI is pretty generic, it is possible to add basic new
package system support with solely backend changes. This guide is superficial and does
not cover the way the code should be written. However, you can find a good example
by looking at the following merge requests:

- [NPM registry support](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/8673).
- [Maven repository](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6607).
- [Composer repository for PHP dependencies](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22415).
- [Terraform modules registry](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834).
- [Instance-level endpoint for Maven repository](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/8757).

## General information

The existing database model requires the following:

- Every package belongs to a project.
- Every package file belongs to a package.
- A package can have one or more package files.
- The package model is based on storing information about the package and its version.

### API endpoints

Package systems work with GitLab via API. For example `lib/api/npm_packages.rb`
implements API endpoints to work with NPM clients. So, the first thing to do is to
add a new `lib/api/your_name_packages.rb` file with API endpoints that are
necessary to make the package system client to work. Usually that means having
endpoints like:

- GET package information.
- GET package file content.
- PUT upload package.

Since the packages belong to a project, it's expected to have project-level endpoint (remote)
for uploading and downloading them. For example:

```plaintext
GET https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
PUT https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
```

Group-level and instance-level endpoints are good to have but are optional.

#### Remote hierarchy

Packages are scoped within various levels of access, which is generally configured by setting your remote. A
remote endpoint may be set at the project level, meaning when installing packages, only packages belonging to that
project are visible. Alternatively, a group-level endpoint may be used to allow visibility to all packages
within a given group. Lastly, an instance-level endpoint can be used to allow visibility to all packages within an
entire GitLab instance.

Using group and project level endpoints allows for more flexibility in package naming, however, more remotes
have to be managed. Using instance level endpoints requires [stricter naming conventions](#naming-conventions).

The current state of existing package registries availability is:

| Repository Type  | Project Level | Group Level | Instance Level |
|------------------|---------------|-------------|----------------|
| Maven            | Yes           | Yes         | Yes            |
| Conan            | Yes           | No - [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/11679) | Yes |
| NPM              | No - [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/36853) | Yes | No - [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/36853) |
| NuGet            | Yes           | No - [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/36423) | No |
| PyPI             | Yes           | No          | No             |
| Go               | Yes           | No - [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/213900) | No - [open-issue](https://gitlab.com/gitlab-org/gitlab/-/issues/213902) |
| Composer         | Yes           | Yes         | No             |
| Generic | Yes           | No          | No             |

NOTE: **Note:**
NPM is currently a hybrid of the instance level and group level.
It is using the top-level group or namespace as the defining portion of the name
(for example, `@my-group-name/my-package-name`).

NOTE: **Note:**
Composer package naming scope is Instance Level.

### Naming conventions

To avoid name conflict for instance-level endpoints you must define a package naming convention
that gives a way to identify the project that the package belongs to. This generally involves using the project
ID or full project path in the package name. See
[Conan's naming convention](../user/packages/conan_repository/index.md#package-recipe-naming-convention-for-instance-remotes) as an example.

For group and project-level endpoints, naming can be less constrained and it is up to the group and project
members to be certain that there is no conflict between two package names. However, the system should prevent
a user from reusing an existing name within a given scope.

Otherwise, naming should follow the package manager's naming conventions and include a validation in the `package.md`
model for that package type.

### Services and finders

Logic for performing tasks such as creating package or package file records or finding packages should not live
within the API file, but should live in services and finders. Existing services and finders should be used or
extended when possible to keep the common package logic grouped as much as possible.

### Configuration

GitLab has a `packages` section in its configuration file (`gitlab.rb`).
It applies to all package systems supported by GitLab. Usually you don't need
to add anything there.

Packages can be configured to use object storage, therefore your code must support it.

## MVC Approach

The way new package systems are integrated in GitLab is using an [MVC](https://about.gitlab.com/handbook/values/#minimum-viable-change-mvc). Therefore, the first iteration should support the bare minimum user actions:

- Authentication
- Uploading a package
- Pulling a package
- Required actions

Required actions are all the additional requests that GitLab needs to handle so the corresponding package manager CLI can work properly. It could be a search feature or an endpoint providing meta information about a package. For example:

- For NuGet, the search request was implemented during the first MVC iteration, to support Visual Studio.
- For NPM, there is a metadata endpoint used by `npm` to get the tarball URL.

For the first MVC iteration, it's recommended to stay at the project level of the [remote hierarchy](#remote-hierarchy). Other levels can be tackled with [future Merge Requests](#future-work).

There are usually 2 phases for the MVC:

- [Analysis](#analysis)
- [Implementation](#implementation)

### Keep iterations small

When implementing a new package manager, it is tempting to create one large merge request containing all of the
necessary endpoints and services necessary to support basic usage. Instead, put the
API endpoints behind a [feature flag](feature_flags/development.md) and
submit each endpoint or behavior (download, upload, etc) in a different merge request to shorten the review
process.

### Analysis

During this phase, the idea is to collect as much information as possible about the API used by the package system. Here some aspects that can be useful to include:

- **Authentication**: What authentication mechanisms are available (OAuth, Basic
  Authorization, other). Keep in mind that GitLab users often want to use their
  [Personal Access Tokens](../user/profile/personal_access_tokens.md).
  Although not needed for the MVC first iteration, the [CI job tokens](../user/project/new_ci_build_permissions_model.md#job-token)
  have to be supported at some point in the future.
- **Requests**: Which requests are needed to have a working MVC. Ideally, produce
  a list of all the requests needed for the MVC (including required actions). Further
  investigation could provide an example for each request with the request and the response bodies.
- **Upload**: Carefully analyze how the upload process works. This is likely the most
  complex request to implement. A detailed analysis is desired here as uploads can be
  encoded in different ways (body or multipart) and can even be in a totally different
  format (for example, a JSON structure where the package file is a Base64 value of
  a particular field). These different encodings lead to slightly different implementations
  on GitLab and GitLab Workhorse. For more detailed information, review [file uploads](#file-uploads).
- **Endpoints**: Suggest a list of endpoint URLs to implement in GitLab.
- **Split work**: Suggest a list of changes to do to incrementally build the MVC.
  This gives a good idea of how much work there is to be done. Here is an example
  list that would need to be adapted on a case by case basis:
  1. Empty file structure (API file, base service for this package)
  1. Authentication system for "logging in" to the package manager
  1. Identify metadata and create applicable tables
  1. Workhorse route for [object storage direct upload](uploads.md#direct-upload)
  1. Endpoints required for upload/publish
  1. Endpoints required for install/download
  1. Endpoints required for required actions

The analysis usually takes a full milestone to complete, though it's not impossible to start the implementation in the same milestone.

In particular, the upload request can have some [requirements in the GitLab Workhorse project](#file-uploads). This project has a different release cycle than the rails backend. It's **strongly** recommended that you open an issue there as soon as the upload request analysis is done. This way GitLab Workhorse is already ready when the upload request is implemented on the rails backend.

### Implementation

The implementation of the different Merge Requests varies between different package system integrations. Contributors should take into account some important aspects of the implementation phase.

#### Authentication

The MVC must support [Personal Access Tokens](../user/profile/personal_access_tokens.md) right from the start. We currently support two options for these tokens: OAuth and Basic Access.

OAuth authentication is already supported. You can see an example in the [npm API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/npm_packages.rb).

[Basic Access authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
support is done by overriding a specific function in the API helpers, like
[this example in the Conan API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/conan_packages.rb).
For this authentication mechanism, keep in mind that some clients can send an unauthenticated
request first, wait for the 401 Unauthorized response with the [`WWW-Authenticate`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate)
field, then send an updated (authenticated) request. This case is more involved as
GitLab needs to handle the 401 Unauthorized response. The [Nuget API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/nuget_packages.rb)
supports this case.

#### Authorization

There are project and group level permissions for `read_package`, `create_package`, and `destroy_package`. Each
endpoint should
[authorize the requesting user](https://gitlab.com/gitlab-org/gitlab/blob/398fef1ca26ae2b2c3dc89750f6b20455a1e5507/ee/lib/api/conan_packages.rb)
against the project or group before continuing.

#### Database and handling metadata

The current database model allows you to store a name and a version for each package.
Every time you upload a new package, you can either create a new record of `Package`
or add files to existing record. `PackageFile` should be able to store all file-related
information like the file `name`, `side`, `sha1`, etc.

If there is specific data necessary to be stored for only one package system support,
consider creating a separate metadata model. See `packages_maven_metadata` table
and `Packages::Maven::Metadatum` model as an example for package specific data, and `packages_conan_file_metadata` table
and `Packages::Conan::FileMetadatum` model as an example for package file specific data.

If there is package specific behavior for a given package manager, add those methods to the metadata models and
delegate from the package model.

Note that the existing package UI only displays information within the `packages_packages` and `packages_package_files`
tables. If the data stored in the metadata tables need to be displayed, a ~frontend change is required.

#### File uploads

File uploads should be handled by GitLab Workhorse using object accelerated uploads. What this means is that
the workhorse proxy that checks all incoming requests to GitLab intercept the upload request,
upload the file, and forward a request to the main GitLab codebase only containing the metadata
and file location rather than the file itself. An overview of this process can be found in the
[development documentation](uploads.md#direct-upload).

In terms of code, this means a route must be added to the
[GitLab Workhorse project](https://gitlab.com/gitlab-org/gitlab-workhorse) for each upload endpoint being added
(instance, group, project). [This merge request](https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/412/diffs)
demonstrates adding an instance-level endpoint for Conan to workhorse. You can also see the Maven project level endpoint
implemented in the same file.

Once the route has been added, you must add an additional `/authorize` version of the upload endpoint to your API file.
[Here is an example](https://gitlab.com/gitlab-org/gitlab/blob/398fef1ca26ae2b2c3dc89750f6b20455a1e5507/ee/lib/api/maven_packages.rb#L164)
of the additional endpoint added for Maven. The `/authorize` endpoint verifies and authorizes the request from workhorse,
then the normal upload endpoint is implemented below, consuming the metadata that workhorse provides in order to
create the package record. Workhorse provides a variety of file metadata such as type, size, and different checksum formats.

For testing purposes, you may want to [enable object storage](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/object_storage.md)
in your local development environment.

### Future Work

While working on the MVC, contributors might find features that are not mandatory for the MVC but can provide a better user experience. It's generally a good idea to keep an eye on those and open issues.

Here are some examples

1. Endpoints required for search
1. Front end updates to display additional package information and metadata
1. Limits on file sizes
1. Tracking for metrics
1. Read more metadata fields from the package to make it available to the front end. For example, it's usual to be able to tag a package. Those tags can be read and saved by backend and then displayed on the packages UI.
1. Endpoints for the upper levels of the [remote hierarchy](#remote-hierarchy). This step might need to create a [naming convention](#naming-conventions)

## Exceptions

This documentation is just guidelines on how to implement a package manager to match the existing structure and logic
already present within GitLab. While the structure is intended to be extendable and flexible enough to allow for
any given package manager, if there is good reason to stray due to the constraints or needs of a given package
manager, then it should be raised and discussed within the implementation issue or merge request to work towards
the most efficient outcome.
