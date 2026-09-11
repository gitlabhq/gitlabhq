---
title: Aggregated scanner coverage in security inventory
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/security_inventory/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22124
categories: [ Security Asset Inventories ]
---

You can now view scanner coverage for an entire group hierarchy from one page. In previous
versions of GitLab, the [Security Inventory](../../../user/application_security/security_inventory/_index.md)
showed coverage per subgroup, but no total for the entire group. A coverage widget now aggregates
scanner coverage across every project in the group and its subgroups, and shows the
percentage and number of projects where each scanner is enabled, not enabled, failing, or
stale. To focus on one scanner, such as SAST or Dependency Scanning, use the scanner dropdown list.
Then select a status to filter the project list, and turn on scanners for the projects that aren't
covered.

The Security Inventory also now lets you control which columns are shown. To show or hide the
**Vulnerabilities**, **Tool coverage**, and **Security attributes** columns, select **Display**.
