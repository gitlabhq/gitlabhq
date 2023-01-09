---
stage: Govern
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Vulnerability Page **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13561) in GitLab 13.0.

Each vulnerability in a project has a Vulnerability Page, containing details of the
vulnerability. The details included vary according to the type of vulnerability.

Details of each vulnerability include:

- Description
- When it was detected
- Current status
- Available actions
- Linked issues
- Actions log

In GitLab 14.3 and later, if the scanner determined the vulnerability to be a false positive, an
alert message is included at the top of the vulnerability's page.

On the vulnerability's page, you can:

- [Change the vulnerability's status](#change-status-of-a-vulnerability).
- [Create an issue](#creating-an-issue-for-a-vulnerability).
- [Link issues to the vulnerability](#linking-a-vulnerability-to-issues).
- [Resolve the vulnerability](#resolve-a-vulnerability) if a solution is
  available.
- [View security training specific to the detected vulnerability](#view-security-training-for-a-vulnerability).

## Vulnerability status values

A vulnerability's status can be:

- **Detected**: The default state for a newly discovered vulnerability. Appears as "Needs triage" in the UI.
- **Confirmed**: A user has seen this vulnerability and confirmed it to be accurate.
- **Dismissed**: A user has seen this vulnerability and dismissed it because it is not accurate or otherwise not to be resolved.
- **Resolved**: The vulnerability has been fixed or is no longer present.

Dismissed vulnerabilities are ignored if detected in subsequent scans. Resolved vulnerabilities that
are reintroduced and detected by subsequent scans have a _new_ vulnerability record created. When an
existing vulnerability is no longer detected in a project's `default` branch, you should change its
status to **Resolved**. This ensures that if it is accidentally reintroduced in a future merge, it
is reported again as a new record. You can use the Vulnerability Report's
[Activity filter](../vulnerability_report/index.md#activity-filter) to select all vulnerabilities that are
no longer detected, and change their status.

## Change status of a vulnerability

To change a vulnerability's status from its Vulnerability Page:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability's description.
1. From the **Status** dropdown list select a status, then select **Change status**.
1. Optionally, at the bottom of the page, add a comment to the log entry.

The Actions log records each status change along with which user changed the status and the time of the change.

## Creating an issue for a vulnerability

From a vulnerability's page you can create an issue to track all action taken to resolve or
mitigate it.

You can create either:

- [A GitLab issue](#create-a-gitlab-issue-for-a-vulnerability) (default).
- [A Jira issue](#create-a-jira-issue-for-a-vulnerability).

Creating a Jira issue requires that
[Jira integration](../../../integration/jira/index.md) is enabled on the project. Note
that when Jira integration is enabled, the GitLab issue feature is not available.

### Create a GitLab issue for a vulnerability

To create a GitLab issue for a vulnerability:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability's description.
1. Select **Create issue**.

An issue is created in the project, pre-populated with information from the vulnerability report.
The issue is then opened so you can take further action.

### Create a Jira issue for a vulnerability

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4677) in GitLab 13.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/283850) in GitLab 13.12.

Prerequisites:

- [Enable Jira integration](../../../integration/jira/index.md). The **Enable Jira issue creation
  from vulnerabilities** option must be selected as part of the configuration.
- Each user must have a personal Jira user account with permission to create issues in the target
  project.

To create a Jira issue for a vulnerability:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability's description.
1. Select **Create Jira issue**.
1. If you're not already logged in to Jira, sign in.

The Jira issue is created and opened in a new browser tab. The **Summary** and **Description**
fields are pre-populated from the vulnerability's details.

Unlike GitLab issues, the status of whether a Jira issue is open or closed does not display in the
GitLab user interface.

## Linking a vulnerability to issues

NOTE:
If Jira issue support is enabled, GitLab issues are disabled so this feature is not available.

You can link a vulnerability to one or more existing GitLab issues. Adding a link helps track
the issue that resolves or mitigates a vulnerability.

Issues linked to a vulnerability are shown in the Vulnerability Report and the vulnerability's page.

Be aware of the following conditions between a vulnerability and a linked issue:

- The vulnerability page shows related issues, but the issue page doesn't show the vulnerability
  it's related to.
- An issue can only be related to one vulnerability at a time.
- Issues can be linked across groups and projects.

## Link a vulnerability to existing issues

To link a vulnerability to existing issues:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability's description.
1. In the **Linked issues** section, select the plus icon (**{plus}**).
1. For each issue to be linked, either:
   - Paste a link to the issue.
   - Enter the issue's ID (prefixed with a hash `#`).
1. Select **Add**.

The selected issues are added to the **Linked issues** section, and the linked issues counter is
updated.

## Resolve a vulnerability

For some vulnerabilities a solution is already known. In those instances, a vulnerability's page
includes a **Resolve with merge request** option.

The following scanners are supported by this feature:

- [Dependency Scanning](../dependency_scanning/index.md).
  Automatic patch creation is only available for Node.js projects managed with
  `yarn`. Also, Automatic patch creation is only supported when [FIPS mode](../../../development/fips_compliance.md#enable-fips-mode) is disabled.
- [Container Scanning](../container_scanning/index.md).

To resolve a vulnerability, you can either:

- [Resolve a vulnerability with a merge request](#resolve-a-vulnerability-with-a-merge-request).
- [Resolve a vulnerability manually](#resolve-a-vulnerability-manually).

![Create merge request from vulnerability](img/create_mr_from_vulnerability_v13_4.png)

### Resolve a vulnerability with a merge request

To resolve the vulnerability with a merge request:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability's description.
1. From the **Resolve with merge request** dropdown list, select **Resolve with merge request**.

A merge request is created which applies the patch required to resolve the vulnerability.
Process the merge request according to your standard workflow.

### Resolve a vulnerability manually

To manually apply the patch that GitLab generated for a vulnerability:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability's description.
1. From the **Resolve with merge request** dropdown list, select **Download patch to resolve**.
1. Ensure your local project has the same commit checked out that was used to generate the patch.
1. Run `git apply remediation.patch`.
1. Verify and commit the changes to your branch.
1. Create a merge request to apply the changes to your main branch.
1. Process the merge request according to your standard workflow.

## Enable security training for vulnerabilities

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6176) in GitLab 14.9.

Security training helps your developers learn how to fix vulnerabilities. Developers can view security training from selected educational providers, relevant to the detected vulnerability.

To enable security training for vulnerabilities in your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. On the tab bar, select **Vulnerability Management**.
1. To enable a security training provider, turn on the toggle.

Security training uses content from third-party vendors. You must have an internet connection to use this feature.

## View security training for a vulnerability

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6176) in GitLab 14.9.

The vulnerability page may include a training link relevant to the detected vulnerability if security training is enabled.
The availability of training depends on whether the enabled training vendor has content matching the particular vulnerability.
Training content is requested based on the [vulnerability identifiers](../../../development/integrations/secure.md#identifiers).
The identifier given to a vulnerability will vary from one vulnerability to the next. The available training
content varies between vendors. This means some vulnerabilities will display no training content.
Vulnerabilities with a CWE are most likely to return a training result.

To view the security training for a vulnerability:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Vulnerability report**.
1. Select the vulnerability for which you want to view security training.
1. Select **View training**.
