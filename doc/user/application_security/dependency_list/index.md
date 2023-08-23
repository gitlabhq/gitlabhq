---
type: reference, howto
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Dependency list **(ULTIMATE ALL)**

> - System dependencies [introduced](https://gitlab.com/groups/gitlab-org/-/epics/6698) in GitLab 14.6.
> - Group-level dependency list [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8090) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `group_level_dependencies`. Disabled by default.

Use the dependency list to review your project or group's dependencies and key
details about those dependencies, including their known vulnerabilities. It is a collection of dependencies in your project, including existing and new findings.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Project Dependency](https://www.youtube.com/watch?v=ckqkn9Tnbw4).

To see the dependency list, go to your project or group and select **Secure > Dependency list**.

This information is sometimes referred to as a Software Bill of Materials, SBOM, or BOM.

## Prerequisites

To view your project's dependencies, ensure you meet the following requirements:

- The [Dependency Scanning](../dependency_scanning/index.md)
  or [Container Scanning](../container_scanning/index.md)
  CI job must be configured for your project.
- Your project uses at least one of the
  [languages and package managers](../dependency_scanning/index.md#supported-languages-and-package-managers)
  supported by Gemnasium.
- A successful pipeline was run on the default branch.
  You should not change the default behavior of allowing the
  [application security jobs](../../application_security/index.md#application-coverage) to fail.

## View a project's dependencies

![Dependency list](img/dependency_list_v13_11.png)

GitLab displays dependencies with the following information:

| Field     | Description |
|-----------|-------------|
| Component | The dependency's name and version. |
| Packager  | The packager used to install the dependency. |
| Location  | For system dependencies, this lists the image that was scanned. For application dependencies, this shows a link to the packager-specific lock file in your project that declared the dependency. It also shows the [dependency path](#dependency-paths) to a top-level dependency, if any, and if supported. |
| License   | Links to dependency's software licenses. |

Displayed dependencies are initially sorted by the severity of their known vulnerabilities, if any. They
can also be sorted by name or by the packager that installed them.

### Vulnerabilities

If a dependency has known vulnerabilities, view them by selecting the arrow next to the
dependency's name or the badge that indicates how many known vulnerabilities exist. For each
vulnerability, its severity and description appears below it. To view more details of a vulnerability,
select the vulnerability's description. The [vulnerability's details](../vulnerabilities) page is opened.

### Dependency paths

The dependency list shows the path between a dependency and a top-level dependency it's connected
to, if any. There are many possible paths connecting a transient dependency to top-level
dependencies, but the user interface shows only one of the shortest paths.

NOTE:
The dependency path is only displayed for dependencies that have vulnerabilities.

![Dependency path](img/yarn_dependency_path_v13_6.png)

Dependency paths are supported for the following package managers:

- [NuGet](https://www.nuget.org/)
- [Yarn 1.x](https://classic.yarnpkg.com/lang/en/)
- [sbt](https://www.scala-sbt.org)
- [Conan](https://conan.io)

### Licenses

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10536) in GitLab 12.3.

If the [Dependency Scanning](../../application_security/dependency_scanning/index.md) CI job is configured,
[discovered licenses](../../compliance/license_scanning_of_cyclonedx_files/index.md#enable-license-scanning) are displayed on this page.

## View a group's dependencies

FLAG:
On self-managed GitLab, and GitLab.com the feature is disabled by default. To show the feature, an administrator can [enable the feature flag](../../../administration/feature_flags.md) named `group_level_dependencies`.

![Dependency list](img/dependency_list_v16_3.png)

GitLab displays dependencies with the following information:

| Field     | Description |
|-----------|-------------|
| Component | The dependency's name and version. |
| Packager  | The packager used to install the dependency. |
| Location  | For operating system dependencies, this lists the image that was scanned. For application dependencies, this shows a link to the packager-specific lock file in your project that declared the dependency. It also shows the [dependency path](#dependency-paths) to a top-level dependency, if any, and if supported. If there are multiple locations, the total number of locations is displayed.  |
| Projects   | Links to the project related to the dependency. If there are multiple projects, the total number of projects is displayed. |

Displayed dependencies are initially sorted by packager. They
can also be sorted by name.

NOTE:
The project search feature is only supported on groups that have up to 600 occurrences within their group hierarchy.

## Downloading the dependency list

You can download the full list of dependencies and their details in
`JSON` format.

### In the UI

You can download your group's or project's list of dependencies and their details in JSON format by selecting the **Export** button. The dependency list only shows the results of the last successful pipeline to run on the default branch.

### Using the API

You can download your project's list of dependencies [using the API](../../../api/dependencies.md#list-project-dependencies). Note this only provides the dependencies identified by the [Gemnasium family of analyzers](../dependency_scanning/index.md#dependency-analyzers) and not any other of the GitLab dependency analyzers.
