# Packages **[PREMIUM]**

This document will guide you through adding another [package management system](../administration/packages.md) support to GitLab.

See already supported package types in [Packages documentation](../administration/packages.md)

Since GitLab packages' UI is pretty generic, it is possible to add new
package system support by solely backend changes. This guide is superficial and does 
not cover the way the code should be written. However, you can find a good example 
by looking at existing merge requests with Maven and NPM support: 

- [NPM registry support](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/8673). 
- [Maven repository](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6607).
- [Instance level endpoint for Maven repository](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/8757)

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

Since the packages belong to a project, it's expected to have project-level endpoint
for uploading and downloading them. For example: 

```
GET https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
PUT https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
```

Group-level and instance-level endpoints are good to have but are optional. 

NOTE: **Note:**
To avoid name conflict for instance-level endpoints we use 
[the package naming convention](../user/project/packages/npm_registry.md#package-naming-convention)

## Configuration

GitLab has a `packages` section in its configuration file (`gitlab.rb`). 
It applies to all package systems supported by GitLab. Usually you don't need 
to add anything there. 

Packages can be configured to use object storage, therefore your code must support it. 

## Database

The current database model allows you to store a name and a version for each package.
Every time you upload a new package, you can either create a new record of `Package`
or add files to existing record. `PackageFile` should be able to store all file-related
information like the file `name`, `side`, `sha1`, etc.

If there is specific data necessary to be stored for only one package system support, 
consider creating a separate metadata model. See `packages_maven_metadata` table 
and `Packages::MavenMetadatum` model as example for package specific data.
