---
type: reference, howto
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Compliance Dashboard **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36524) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.8.

The Compliance Dashboard gives you the ability to see a group's Merge Request activity
by providing a high-level view for all projects in the group. For example, code approved
for merging into production.

## Overview

To access the Compliance Dashboard for a group, navigate to **{shield}** **Security & Compliance > Compliance** on the group's menu.

![Compliance Dashboard](img/compliance_dashboard_v12_10.png)

## Use cases

This feature is for people who care about the compliance status of projects within their group.

You can use the dashboard to:

- Get an overview of the latest Merge Request for each project.
- See if Merge Requests were approved and by whom.
- See the latest [CI Pipeline](../../../ci/pipelines/index.md) result for each Merge Request.

## Permissions

- On [GitLab Ultimate](https://about.gitlab.com/pricing/) tier.
- By **Administrators** and **Group Owners**.
