---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency list
description: Vulnerabilities, licenses, filtering, and exporting.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Dependency list [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8090) for groups in GitLab 16.2 [with a flag](../../../administration/feature_flags/_index.md) named `group_level_dependencies`. Disabled by default.
- Dependency list for groups [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/411257) in GitLab 16.4.
- Dependency list for groups [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132015) in GitLab 16.5. Feature flag `group_level_dependencies` removed.

{{< /history >}}

Use the dependency list to review your project or group's dependencies and key details about those
dependencies, including their known vulnerabilities. This list is a collection of dependencies in your
project, including existing and new findings. This information is sometimes referred to as a
Software Bill of Materials, SBOM, or BOM.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Project Dependency - Advanced Security Testing](https://www.youtube.com/watch?v=ckqkn9Tnbw4).

## Set up the dependency list

To list your project's dependencies, run [dependency scanning](../dependency_scanning/_index.md)
or [container scanning](../container_scanning/_index.md) on the default branch of your project.

The dependency list also shows dependencies from any
[CycloneDX reports](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) uploaded from the
latest default branch pipeline.
The CycloneDX reports must comply with [the CycloneDX specification](https://github.com/CycloneDX/specification) version `1.4`, `1.5`, or `1.6`.
You can use the [CycloneDX Web Tool](https://cyclonedx.github.io/cyclonedx-web-tool/validate) to validate CycloneDX reports.

{{< alert type="note" >}}

Although this is not mandatory for populating the dependency list, the SBOM document must include and comply with the
GitLab CycloneDX property taxonomy to provide some properties and to enable some security features.

{{< /alert >}}

## View project dependencies

{{< history >}}

- In GitLab 17.2, the `location` field no longer links to the commit where the dependency was last detected when the feature flag `skip_sbom_occurrences_update_on_pipeline_id_change` is enabled. The flag is disabled by default.
- In GitLab 17.3 the `location` field always links to the commit where the dependency was first detected. Feature flag `skip_sbom_occurrences_update_on_pipeline_id_change` removed.
- View dependency paths option [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519965) in GitLab 17.11 [with a flag](../../../administration/feature_flags/_index.md) named `dependency_paths`. Disabled by default.
- View dependency paths option [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197224) in GitLab 18.2. Feature flag `dependency_paths` enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

To view the dependencies of a project or all projects in a group:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Dependency list**.
1. Optional. If there are transitive dependencies, you can also view all of the dependency paths:
   - For a project, in the **Location** column, select **View dependency paths**.
   - For a group, in the **Location** column, select the location, then select **View dependency paths**.

Details of each dependency are listed, sorted by decreasing severity of vulnerabilities (if any). You can sort the list instead by component name, packager, or license.

| Field                       | Description |
|-----------------------------|-------------|
| Component                   | The dependency's name and version. |
| Packager                    | The package manager used to install the dependency. Displays as "unknown" for unsupported package managers. |
| Location                    | For system dependencies, this field lists the image that was scanned. For application dependencies, this field shows a link to the packager-specific lock file in your project that declared the dependency. It also shows the direct [dependents](#dependency-paths), if any. If there are transitive dependencies, selecting **View dependency paths** shows the full path of all dependents. Transitive dependencies are indirect dependents that have a direct dependent as an ancestor. |
| License (for projects only) | Links to dependency's software licenses. A warning badge that includes the number of vulnerabilities detected in the dependency. |
| Projects (for groups only)  | Links to the project with the dependency. If multiple projects have the same dependency, the total number of these projects is shown. To go to a project with this dependency, select the **Projects** number, then search for and select its name. |

## Filter dependency list

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422356) dependency filtering for groups in GitLab 16.7 [with a flag](../../../administration/feature_flags/_index.md) named `group_level_dependencies_filtering`. Disabled by default.
- Dependency filtering for group [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/422356) in GitLab 16.10. Feature flag `group_level_dependencies_filtering` removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513320) dependency filtering for projects in GitLab 17.9 with a flag named [`project_component_filter`](../../../administration/feature_flags/_index.md). Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/513321) in GitLab 17.10. Feature flag `project_component_filter` removed.
- Dependency version filtering introduced for [projects](https://gitlab.com/gitlab-org/gitlab/-/issues/520771) and [groups](https://gitlab.com/gitlab-org/gitlab/-/issues/523061) in GitLab 18.0 with [flags](../../../administration/feature_flags/_index.md) named `version_filtering_on_project_level_dependency_list` and `version_filtering_on_group_level_dependency_list`. Disabled by default.
- Dependency version filtering [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192291) on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in GitLab 18.1.
- Feature flags `version_filtering_on_project_level_dependency_list` and `version_filtering_on_group_level_dependency_list` removed.

{{< /history >}}

You can filter the dependency list to focus on only a subset of dependencies. The dependency
list is available for groups and projects.

For groups, you can filter by:

- Project
- License
- Components
- Component version

For projects, you can filter by:

- Components
- Component version

To filter by component version, you must filter by exactly one component first.

To filter the dependency list:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Dependency list**.
1. Select the filter bar.
1. Select a filter, then from the dropdown list select one or more criteria.
   To close the dropdown list, select outside of it. To add more filters, repeat this step.
1. To apply the selected filters, press <kbd>Enter</kbd>.

The dependency list shows only dependencies that match your filters.

## Vulnerabilities

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/500551) in GitLab 17.9 [with a flag](../../../administration/feature_flags/_index.md) named `update_sbom_occurrences_vulnerabilities_on_cvs`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/514223) in GitLab 17.9.
- A change to make the dependency list display only `detected` and `confirmed` states introduced in GitLab 18.5.

{{< /history >}}

{{< alert type="flag" >}}

The availability of support for vulnerabilities associated with [SBOM-based dependency scanning](../dependency_scanning/dependency_scanning_sbom/_index.md) is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

If a dependency has known vulnerabilities, view them by selecting the arrow next to the
dependency's name or the badge that indicates how many known vulnerabilities exist. For each
vulnerability, its severity and description appears below it. To view more details of a vulnerability,
select the vulnerability's description. The [vulnerability's details](../vulnerabilities/_index.md) page is opened.
The dependency list shows only vulnerabilities in the `detected` and `confirmed` states.
When a vulnerability's state changes, the changes are not reflected on the dependency list
until a new pipeline runs on the default branch containing an SBoM.

## Dependency paths

{{< history >}}

- Dependency path information from CycloneDX SBOM was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393061) in GitLab 16.9 [with a flag](../../../administration/feature_flags/_index.md) named `project_level_sbom_occurrences`. Disabled by default.
- Dependency path information from CycloneDX SBOM was [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/434371) in GitLab 17.0.
- Dependency path information from CycloneDX SBOM [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/457633) in GitLab 17.4. Feature flag `project_level_sbom_occurrences` removed.

{{< /history >}}

The dependency path shows the direct dependents of a listed component if the component is transient
and belongs to a supported package manager. The dependency path is only displayed for dependencies
that have vulnerabilities.

Dependency paths are supported for the following package managers:

- [Conan](https://conan.io)
- [NuGet](https://www.nuget.org/)
- [sbt](https://www.scala-sbt.org)
- [Yarn 1.x](https://classic.yarnpkg.com/lang/en/)

Dependency paths are supported for the following package managers only when using the [`dependency-scanning`](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) component:

- [Gradle](https://gradle.org/)
- [Maven](https://maven.apache.org/)
- [NPM](https://www.npmjs.com/)
- [Pipenv](https://pipenv.pypa.io/en/latest/)
- [pip-tools](https://pip-tools.readthedocs.io/en/latest/)
- [pnpm](https://pnpm.io/)
- [Poetry](https://python-poetry.org/)

### Licenses

If the [dependency scanning](../dependency_scanning/_index.md) CI/CD job is configured,
[discovered licenses](../../compliance/license_scanning_of_cyclonedx_files/_index.md) are displayed on this page.

## Export

You can export the dependency list in:

- JSON
- CSV
- CycloneDX format (for projects only)

To export the dependency list:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Dependency list**.
1. Select **Export** and then select the file format.

The dependency list is sent to your email address. To download the dependency list, select the
link in the email.

## Troubleshooting

When working with the dependency list, you might encounter the following issues.

### License appears as 'unknown'

The license for a specific dependency might show up as `unknown` for a few possible reasons. This section describes how to determine whether a specific dependency's license shows up as `unknown` for a known reason.

#### License is 'unknown' upstream

Check the license specified for the dependency upstream:

- For C/C++ packages, check [Conancenter](https://conan.io/center).
- For npm packages, check [npmjs.com](https://www.npmjs.com/).
- For Python packages, check [PyPI](https://pypi.org/).
- For NuGet packages, check [Nuget](https://www.nuget.org/packages).
- For Go packages, check [pkg.go.dev](https://pkg.go.dev/).

If the license appears as `unknown` upstream, it is expected that GitLab will show the **License** for that dependency to be `unknown` as well.

#### License includes SPDX license expression

[SPDX license expressions](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/) are not supported. Dependencies with SPDX license expressions appear with a **License** that is `unknown`. An example of an SPDX license expression is `(MIT OR CC0-1.0)`. Read more in [issue 336878](https://gitlab.com/gitlab-org/gitlab/-/issues/336878).

#### Package version not in Package Metadata DB

The specific version of the dependency package must exist in the [Package Metadata Database](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database). If it doesn't, the **License** for that dependency appears as `unknown`. Read more in [issue 440218](https://gitlab.com/gitlab-org/gitlab/-/issues/440218) about Go modules.

#### Package name contains special characters

If the name of the dependency package contains a hyphen (`-`) the **License** may appear as `unknown`. This can happen when packages are added manually to `requirements.txt` or when `pip-compile` is used. This happens because GitLab does not normalize Python package names in accordance with the guidance on [normalized names in PEP 503](https://peps.python.org/pep-0503/#normalized-names) when ingesting information about dependencies. Read more in [issue 440391](https://gitlab.com/gitlab-org/gitlab/-/issues/440391).
