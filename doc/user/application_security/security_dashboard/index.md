---
type: reference, howto
stage: Secure
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Security Dashboard, Security Center, and Vulnerability Reports **(ULTIMATE)**

GitLab provides a comprehensive set of features for viewing and managing vulnerabilities:

- Security dashboards: An overview of the security status in your instance, [groups](#group-security-dashboard), and
  [projects](#project-security-dashboard).
- [Vulnerability reports](#vulnerability-report): Detailed lists of all vulnerabilities for the instance, group, project, or
  pipeline. This is where you triage and manage vulnerabilities.
- [Security Center](#instance-security-center): A dedicated area for vulnerability management at the instance level. This
  includes a security dashboard, vulnerability report, and settings.

You can also drill down into a vulnerability and get extra information on the
[Vulnerability Page](../vulnerabilities/index.md). This view includes the project it
comes from, any related file(s), and metadata that helps you analyze the risk it poses.
You can also confirm, dismiss, or resolve a vulnerability, create an issue for it,
and in some cases, generate a merge request to fix the vulnerability.

To benefit from these features, you must first configure one of the
[security scanners](../index.md).

## Supported reports

The vulnerability report displays vulnerabilities detected by scanners such as:

- [Container Scanning](../container_scanning/index.md)
- [Dynamic Application Security Testing](../dast/index.md)
- [Dependency Scanning](../dependency_scanning/index.md)
- [Static Application Security Testing](../sast/index.md)
- And [others](../index.md#security-scanning-tools)!

## Requirements

To use the security dashboards and vulnerability reports:

1. At least one project inside a group must be configured with at least one of
   the [supported reports](#supported-reports).
1. The configured jobs must use the [new `reports` syntax](../../../ci/pipelines/job_artifacts.md#artifactsreports).
1. [GitLab Runner](https://docs.gitlab.com/runner/) 11.5 or newer must be used.
   If you're using the shared runners on GitLab.com, this is already the case.

## Pipeline Security

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13496) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.3.

At the pipeline level, the Security section displays the vulnerabilities present in the branch of
the project the pipeline ran against.

![Pipeline Security Dashboard](img/pipeline_security_dashboard_v13_3.png)

Visit the page for any pipeline that ran any of the [supported reports](#supported-reports). To view
the pipeline's security findings, select the **Security** tab when viewing the pipeline.

A pipeline consists of multiple jobs, including SAST and DAST scanning. If any job fails to finish
for any reason, the security dashboard doesn't show SAST scanner output. For example, if the SAST
job finishes but the DAST job fails, the security dashboard doesn't show SAST results. On failure,
the analyzer outputs an
[exit code](../../../development/integrations/secure.md#exit-code).

## Project Security Dashboard

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235558) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.6.

At the project level, the Security Dashboard displays a chart with the number of vulnerabilities over time.
Access it by navigating to **Security & Compliance > Security Dashboard**. Currently, we display historical
data up to 365 days.

![Project Security Dashboard](img/project_security_dashboard_chart_v13_6.png)

Filter the historical data by clicking on the corresponding legend name. The image above, for example, shows
only the graph for vulnerabilities with **high** severity.

### Vulnerability Report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6165) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.1.

The vulnerabilities that exist in your project's
[default branch](../../project/repository/branches/index.md#default-branch) are accessed by navigating to
**Security & Compliance > Vulnerability Report**. By default, the Vulnerability Report is filtered to
display all detected and confirmed vulnerabilities.

The Vulnerability Report first displays the time at which the last pipeline completed on the project's
default branch. There's also a link to view this in more detail. In the case of any pipeline failures,
the number of failures is indicated. The failure notification takes you directly to
the **Failed jobs** tab of the pipeline page.

The Vulnerability Report next displays the total number of vulnerabilities by severity (for example,
Critical, High, Medium, Low, Info, Unknown). Below this, a table shows each vulnerability's status, severity,
and description. Clicking a vulnerability takes you to its [Vulnerability Details](../vulnerabilities)
page to view more information about that vulnerability.

![Project Vulnerability Report](img/project_security_dashboard_v13_5.png)

You can filter the vulnerabilities by one or more of the following:

| Filter | Available Options |
| --- | --- |
| Status | Detected, Confirmed, Dismissed, Resolved |
| Severity | Critical, High, Medium, Low, Info, Unknown |
| Scanner | [Available Scanners](../index.md#security-scanning-tools) |

You can also dismiss vulnerabilities in the table:

1. Select the checkbox for each vulnerability you want to dismiss.
1. In the menu that appears, select the reason for dismissal and click **Dismiss Selected**.

![Project Vulnerability Report](img/project_security_dashboard_dismissal_v13_4.png)

## Group Security Dashboard

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6709) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.5.

The group Security Dashboard gives an overview of the vulnerabilities found in the default branches of the
projects in a group and its subgroups. Access it by navigating to **Security > Security Dashboard**
after selecting your group. By default, the Security Dashboard displays all detected and confirmed
vulnerabilities. If you don't see the vulnerabilities over time graph, the likely cause is that you
have not selected a group.

Note that the Security Dashboard only shows projects with
[security reports](#supported-reports)
enabled in a group.

![Dashboard with action buttons and metrics](img/group_security_dashboard_v13_3.png)

There is a timeline chart that shows how many open
vulnerabilities your projects had at various points in time. You can display the vulnerability
trends over a 30, 60, or 90-day time frame (the default is 90 days). Hover over the chart to get
more details about the open vulnerabilities at a specific time. Aggregated data beyond 90 days can be accessed by querying our [VulnerabilitiesCountByDay GraphQL API](../../../api/graphql/reference/index.md#vulnerabilitiescountbyday). This data is retained for 365 days.

Next to the timeline chart is a list of projects, grouped and sorted by the severity of the vulnerability found:

| Grade | Description |
| F | One or more "critical" |
| D | One or more "high" or "unknown" |
| C | One or more "medium" |
| B | One or more "low" |
| A | Zero vulnerabilities |

Projects with no vulnerability tests configured don't appear in the list. Additionally, dismissed
vulnerabilities are excluded.

Navigate to the group's [vulnerability report](#vulnerability-report-1) to view the vulnerabilities found.

## Instance Security Center

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3426) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.4.

The Security Center is where you manage vulnerabilities for your instance. It displays the
vulnerabilities present in the default branches of all the projects you configure. It includes the
following:

- The [group security dashboard's](#group-security-dashboard) features.
- A [vulnerability report](#vulnerability-report).
- A dedicated settings area to configure which projects to display.

![Instance Security Dashboard with projects](img/instance_security_dashboard_v13_4.png)

You can access the Instance Security Center from the menu
bar at the top of the page. Under **More**, select **Security**.

![Instance Security Center navigation link](img/instance_security_dashboard_link_v12_4.png)

The dashboard and vulnerability report are empty before you add projects.

![Uninitialized Instance Security Center](img/instance_security_dashboard_empty_v13_4.png)

### Adding projects to the Security Center

To add projects to the Security Center:

1. Click **Settings** in the left navigation bar or click the **Add projects** button.
1. Search for and add one or more projects using the **Search your projects** field.
1. Click the **Add projects** button.

![Adding projects to Instance Security Center](img/instance_security_center_settings_v13_4.png)

After you add projects, the security dashboard and vulnerability report display the vulnerabilities
found in those projects' default branches.

## Export vulnerabilities

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213014) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.10.

You can export all your vulnerabilities in CSV (comma separated values) format by clicking the
**{upload}** **Export** button located at top right of the Security Dashboard. When the report is
ready, the CSV report downloads to your local machine. The report contains all vulnerabilities for
the projects defined in the Security Dashboard, as filters don't apply to the export function.

NOTE: **Note:**
It may take several minutes for the download to start if your project contains
thousands of vulnerabilities. Don't close the page until the download finishes.

The fields in the export include:

- Group Name
- Project Name
- Scanner Type
- Scanner Name
- Status
- Vulnerability
- Details
- Additional Info
- Severity
- [CVE](https://cve.mitre.org/) (Common Vulnerabilities and Exposures)
- [CWE](https://cwe.mitre.org/) (Common Weakness Enumeration)
- Other Identifiers

![Export vulnerabilities](img/instance_security_dashboard_export_csv_v13_4.png)

## Keeping the dashboards up to date

The Security Dashboard displays information from the results of the most recent
security scan on the [default branch](../../project/repository/branches/index.md#default-branch),
which means that security scans are performed every time the branch is updated.

If the default branch is updated infrequently, scans are run infrequently and the
information on the Security Dashboard can become outdated as new vulnerabilities
are discovered.

To ensure the information on the Security Dashboard is regularly updated,
[configure a scheduled pipeline](../../../ci/pipelines/schedules.md) to run a
daily security scan. This updates the information displayed on the Security
Dashboard regardless of how often the default branch is updated.

That way, reports are created even if no code change happens.

CAUTION: **Warning:**
Running Dependency Scanning from a scheduled pipeline might result in false negatives if your
project doesn't have a lock file and isn't configured for Continuous Delivery. A lock file is a file
that lists all transient dependencies and keeps track of their exact versions. The false negative
can occur because the dependency version resolved during the scan might differ from the ones
resolved when your project was built and released, in a previous pipeline. Java projects can't have
lock files. Python projects can have lock files, but GitLab Secure tools don't support them.

## Security scans using Auto DevOps

When using [Auto DevOps](../../../topics/autodevops/index.md), use
[special environment variables](../../../topics/autodevops/customize.md#environment-variables)
to configure daily security scans.

## Vulnerability report

Each vulnerability report contains vulnerabilities from the latest scans that were merged
into the default branch.

![Vulnerability Report](img/group_vulnerability_report_v13_7.png)

You can filter which vulnerabilities the vulnerability report displays by:

| Filter | Available Options |
| --- | --- |
| Status | Detected, Confirmed, Dismissed, Resolved |
| Severity | Critical, High, Medium, Low, Info, Unknown |
| Scanner | [Available Scanners](../index.md#security-scanning-tools) |
| Project | Projects configured in the Security Center settings |

Clicking any vulnerability in the table takes you to its
[Vulnerability Details](../vulnerabilities) page to see more information on that vulnerability.
To create an issue associated with the vulnerability, click the **Create Issue** button.

![Create an issue for the vulnerability](img/vulnerability_page_v13_1.png)

Once you create the issue, the linked issue icon in the vulnerability list:

- Indicates that an issue has been created for that vulnerability.
- Shows a tooltip that contains a link to the issue.

![Display attached issues](img/vulnerability_list_table_v13_4.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

Read more on how to [interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).
