---
type: reference, howto
stage: Secure
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Vulnerability Pages **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13561) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.0.

Each vulnerability in a project has a Vulnerability Page. This page contains details of the
vulnerability. The details included vary according to the type of vulnerability. Details of each
vulnerability include:

- Description
- When it was detected
- Current status
- Available actions
- Linked issues
- Actions log

On the vulnerability's page, you can:

- [Change the vulnerability's status](#change-vulnerability-status).
- [Create an issue](#create-an-issue-for-a-vulnerability).
- [Link issues to the vulnerability](#linked-issues).
- [Resolve a vulnerability](#resolve-a-vulnerability), if a solution is
  available.

## Vulnerability status values

A vulnerability's status can be one of the following:

| Status    | Description |
|:----------|:------------|
| Detected  | The default state for a newly discovered vulnerability. |
| Confirmed | A user has seen this vulnerability and confirmed it to be accurate. |
| Dismissed | A user has seen this vulnerability and dismissed it because it is not accurate or otherwise not to be resolved. |
| Resolved  | The vulnerability has been fixed and is no longer valid. |

## Change vulnerability status

To change a vulnerability's status, select a new value from the **Status** dropdown then select
**Change status**. Optionally, add a comment to the log entry at the bottom of the page.

## Create an issue for a vulnerability

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

1. In GitLab, go to the vulnerability's page.
1. Select **Create issue**.

An issue is created in the project, pre-populated with information from the vulnerability report.
The issue is then opened so you can take further action.

### Create a Jira issue for a vulnerability

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4677) in GitLab 13.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/283850) in GitLab 13.12.

Prerequisites:

- [Enable Jira integration](../../project/integrations/jira.md).
  The **Enable Jira issues creation from vulnerabilities** option must be selected as part of the configuration.
- Each user must have a personal Jira user account with permission to create issues in the target project.

To create a Jira issue for a vulnerability:

1. Go to the vulnerability's page.
1. Select **Create Jira issue**.
1. If you're not already logged in to Jira, log in.

The Jira issue is created and opened in a new browser tab. The **Summary** and **Description**
fields are pre-populated from the vulnerability's details.

Unlike GitLab issues, the status of whether a Jira issue is open or closed does not display in the GitLab user interface.

## Linked issues

NOTE:
If Jira issue support is enabled, GitLab issues are disabled so this feature is not available.

You can link one or more existing GitLab issues to a vulnerability. Adding a link helps track
the issue that resolves or mitigates a vulnerability.

Issues linked to a vulnerability are shown in the Vulnerability Report and the vulnerability's page.

Be aware of the following conditions between a vulnerability and a linked issue:

- The vulnerability page shows related issues, but the issue page doesn't show the vulnerability it's related to.
- An issue can only be related to one vulnerability at a time.
- Issues can be linked across groups and projects.

## Link to existing issues

To link a vulnerability to existing issues:

1. Go to the vulnerability's page.
1. In the **Linked issues** section, select the plus icon (**{plus}**).
1. For each issue to be linked, either:
   - Paste a link to the issue.
   - Enter the issue's ID (prefixed with a hash `#`).
1. Select **Add**.

The selected issues are added to the **Linked issues** section, and the linked issues counter is updated.

## Resolve a vulnerability

For some vulnerabilities a solution is already known. In those instances, a vulnerability's page
includes a **Resolve with merge request** option.

To resolve a vulnerability, you can either:

- [Resolve a vulnerability with a merge request](#resolve-a-vulnerability-with-a-merge-request).
- [Resolve a vulnerability manually](#resolve-a-vulnerability-manually).

The following scanners are supported:

- [Dependency Scanning](../dependency_scanning/index.md).
  Automatic Patch creation is only available for Node.js projects managed with
  `yarn`.
- [Container Scanning](../container_scanning/index.md).

![Create merge request from vulnerability](img/create_mr_from_vulnerability_v13_4.png)

### Resolve a vulnerability with a merge request

To resolve the vulnerability with a merge request, go to the vulnerability's page and from the
**Resolve with merge request** dropdown select **Resolve with merge request**.

A merge request is created which applies the patch required to resolve the vulnerability.
Process the merge request according to your standard workflow.

### Resolve a vulnerability manually

To manually apply the patch that GitLab generated for a vulnerability:

1. Go to the vulnerability's page and from the **Resolve with merge request** dropdown select
   **Download patch to resolve**.
1. Ensure your local project has the same commit checked out that was used to generate the patch.
1. Run `git apply remediation.patch`.
1. Verify and commit the changes to your branch.

## Vulnerability scanner maintenance

The following vulnerability scanners and their databases are regularly updated:

| Secure scanning tool                                            | Vulnerabilities database updates |
|:----------------------------------------------------------------|----------------------------------|
| [Container Scanning](../container_scanning/index.md)            | A job runs on a daily basis to build new images with the latest vulnerability database updates from the upstream scanner. |
| [Dependency Scanning](../dependency_scanning/index.md)          | Relies on `bundler-audit` (for Ruby gems), `retire.js` (for npm packages), and `gemnasium` (the GitLab tool for all libraries). Both `bundler-audit` and `retire.js` fetch their vulnerabilities data from GitHub repositories, so vulnerabilities added to `ruby-advisory-db` and `retire.js` are immediately available. The tools themselves are updated once per month if there's a new version. The [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db) is updated at least once a week. See our [current measurement of time from CVE being issued to our product being updated](https://about.gitlab.com/handbook/engineering/development/performance-indicators/#cve-issue-to-update). |
| [Dynamic Application Security Testing (DAST)](../dast/index.md) | The scanning engine is updated on a periodic basis. See the [version of the underlying tool `zaproxy`](https://gitlab.com/gitlab-org/security-products/dast/blob/main/Dockerfile#L1). The scanning rules are downloaded at scan runtime. |
| [Static Application Security Testing (SAST)](../sast/index.md)  | Relies exclusively on [the tools GitLab wraps](../sast/index.md#supported-languages-and-frameworks). The underlying analyzers are updated at least once per month if a relevant update is available. The vulnerabilities database is updated by the upstream tools. |

You do not have to update GitLab to benefit from the latest vulnerabilities definitions.
The security tools are released as Docker images. The vendored job definitions that enable them use
major release tags according to [semantic versioning](https://semver.org/). Each new release of the
tools overrides these tags.
The Docker images are updated to match the previous GitLab releases. Although
you automatically get the latest versions of the scanning tools,
there are some [known issues](https://gitlab.com/gitlab-org/gitlab/-/issues/9725)
with this approach.
