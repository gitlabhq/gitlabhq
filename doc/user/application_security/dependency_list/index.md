---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Dependency list **(ULTIMATE ALL)**

> - System dependencies [introduced](https://gitlab.com/groups/gitlab-org/-/epics/6698) in GitLab 14.6.
> - Group-level dependency list [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8090) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `group_level_dependencies`. Disabled by default.
> - Group-level dependency list [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/411257) in GitLab 16.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132015) in GitLab 16.5. Feature flag `group_level_dependencies` removed.

Use the dependency list to review your project or group's dependencies and key details about those
dependencies, including their known vulnerabilities. This list is a collection of dependencies in your
project, including existing and new findings. This information is sometimes referred to as a
Software Bill of Materials, SBOM, or BOM.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Project Dependency](https://www.youtube.com/watch?v=ckqkn9Tnbw4).

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

## View project dependencies

To view the dependencies of a project or all projects in a group:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
1. Select **Secure > Dependency list**.

Details of each dependency are listed, sorted by decreasing severity of vulnerabilities (if any). You can sort the list instead by component name or packager.

| Field     | Description |
|:----------|:-----------|
| Component | The dependency's name and version. |
| Packager  | The packager used to install the dependency. |
| Location  | For system dependencies, this lists the image that was scanned. For application dependencies, this shows a link to the packager-specific lock file in your project that declared the dependency. It also shows the [dependency path](#dependency-paths) to a top-level dependency, if any, and if supported. |
| License<sup>1</sup> | Links to dependency's software licenses. A warning badge that includes the number of vulnerabilities detected in the dependency. |
| Projects<sup>2</sup> | Links to the project with the dependency. If multiple projects have the same dependency, the total number of these projects is shown. To go to a project with this dependency, select the **Projects** number, then search for and select its name. The project search feature is supported only on groups that have up to 600 occurrences in their group hierarchy. |

<html>
<small>Footnotes:
  <ol>
    <li>Project-level only.</li>
    <li>Group-level only.</li>
  </ol>
</small>
</html>

![Dependency list](img/dependency_list_v16_3.png)

### Vulnerabilities

If a dependency has known vulnerabilities, view them by selecting the arrow next to the
dependency's name or the badge that indicates how many known vulnerabilities exist. For each
vulnerability, its severity and description appears below it. To view more details of a vulnerability,
select the vulnerability's description. The [vulnerability's details](../vulnerabilities) page is opened.

### Dependency paths

The dependency list shows the path between a dependency and a top-level dependency it's connected
to, if any. Multiple paths may connect a transient dependency to top-level
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

If the [Dependency Scanning](../../application_security/dependency_scanning/index.md) CI job is configured,
[discovered licenses](../../compliance/license_scanning_of_cyclonedx_files/index.md) are displayed on this page.

## Download the dependency list

You can download the full list of dependencies and their details in JSON format. The dependency
list shows only the results of the last successful pipeline that ran on the default branch.

To download the dependency list:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
1. Select **Secure > Dependency list**.
1. Select **Export**.
