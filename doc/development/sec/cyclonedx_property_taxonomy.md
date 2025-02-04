---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CycloneDX property taxonomy
---

This document defines the namespaces and properties used by the `gitlab` namespace
in the [CycloneDX Property Taxonomy](https://github.com/CycloneDX/cyclonedx-property-taxonomy).

NOTE:
Before making changes to this file, please reach out to the threat insights engineering team,
`@gitlab-org/govern/threat-insights`.

## Where properties should be located

The `Property of` column describes what object a property may be attached to.

- Properties attached to the `metadata` apply to all objects in the document.
- Properties attached to an individual object apply to that object and any others nested underneath it.
- Objects which may nest themselves (such as `components`) may only have properties applied to the top-level object.

## `gitlab` namespace taxonomy

| Namespace             | Description |
| --------------------- | ----------- |
| `meta`                | Namespace for data about the property schema. |
| `dependency_scanning` | Namespace for data related to dependency scanning. |
| `container_scanning`  | Namespace for data related to container scanning. |

## `gitlab:meta` namespace taxonomy

| Property                     | Description | Property of |
| ---------------------------- | ----------- | ----------- |
| `gitlab:meta:schema_version` | Used by GitLab to determine how to parse the properties in a report. Must be `1`. | `metadata` |

## `gitlab:dependency_scanning` namespace taxonomy

### Properties

| Property                                 | Description | Example values | Property of |
| ---------------------------------------- | ----------- | -------------- | ----------- |
| `gitlab:dependency_scanning:category`    | The name of the category or dependency group that the dependency belongs to. If no category is specified, `production` is used by default. | `production`, `development`, `test` | `components` |

### Namespaces

| Namespace                                    | Description |
| -------------------------------------------- | ----------- |
| `gitlab:dependency_scanning:input_file`      | Namespace for information about the input file analyzed to produce the dependency. |
| `gitlab:dependency_scanning:source_file`     | Namespace for information about the file you can edit to manage the dependency. |
| `gitlab:dependency_scanning:package_manager` | Namespace for information about the package manager associated with the dependency. |
| `gitlab:dependency_scanning:language`        | Namespace for information about the programming language associated with the dependency. |

## `gitlab:dependency_scanning:input_file` namespace taxonomy

| Property                                      | Description | Example values | Property of |
| --------------------------------------------- | ----------- | -------------- | ----------- |
| `gitlab:dependency_scanning:input_file:path` | The path, relative to the root of the repository, to the file analyzed to produce the dependency. Usually, the lock file. | `package-lock.json`, `Gemfile.lock`, `go.sum` | `metadata`, `component` |

## `gitlab:dependency_scanning:source_file` namespace taxonomy

| Property                                     | Description | Example values | Property of |
| -------------------------------------------- | ----------- | -------------- | ----------- |
| `gitlab:dependency_scanning:source_file:path` | The path, relative to the root of the repository, to the file you can edit to manage the dependency. | `package.json`, `Gemfile`, `go.mod` | `metadata`, `component` |

## `gitlab:dependency_scanning:package_manager` namespace taxonomy

| Property                                          | Description | Example values | Property of |
| ------------------------------------------------- | ----------- | -------------- | ----------- |
| `gitlab:dependency_scanning:package_manager:name` | The name of the package manager associated with the dependency | `npm`, `bundler`, `go` | `metadata`, `component` |

## `gitlab:dependency_scanning:language` namespace taxonomy

| Property                                   | Description | Example values | Property of |
| ------------------------------------------ | ----------- | -------------- | ----------- |
| `gitlab:dependency_scanning:language:name` | The name of the programming language associated with the dependency | `JavaScript`, `Ruby`, `Go` | `metadata`, `component` |

## `gitlab:container_scanning` namespace taxonomy

### Namespaces

| Namespace                                    | Description |
| -------------------------------------------- | ----------- |
| `gitlab:container_scanning:image`            | Namespace for information about the scanned image. |
| `gitlab:container_scanning:operating_system` | Namespace for information about the operating system associated with the scanned image. |

## `gitlab:container_scanning:image` namespace taxonomy

| Property                               | Description | Example values | Property of |
| ---------------------------------------| ----------- | -------------- | ----------- |
| `gitlab:container_scanning:image:name` | The name of the scanned image. | `registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium/tmp/main` | `metadata`, `component` |
| `gitlab:container_scanning:image:tag` | The tag of the scanned image.  | `91d61f07e0a4b3dd34b39d77f47f6f9bf48cde0a` | `metadata`, `component` |

## `gitlab:container_scanning:operating_system` namespace taxonomy

| Property                               | Description | Example values | Property of |
| ---------------------------------------| ----------- | -------------- | ----------- |
| `gitlab:container_scanning:operating_system:name`    | The name of the operation system.    | `alpine` | `metadata`, `component` |
| `gitlab:container_scanning:operating_system:version` | The version of the operation system. | `3.1.8` | `metadata`, `component` |
