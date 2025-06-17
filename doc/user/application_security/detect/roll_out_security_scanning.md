---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Roll out security scanning
---

You can roll out security scanning to individual projects, subgroups, and groups. You should start
with individual projects, then increase the scope in increments. An incremental roll out allows you
to evaluate the results at each point and adjust as needed.

To enable security scanning of individual projects:

- Enable individual security scanners.
- Enable all security scanners by using AutoDevOps.

To enable security scanning of multiple projects, subgroups, or groups, use one of the following
methods:

- [Scan execution policy](../policies/scan_execution_policies.md)
- [Pipeline execution policy](../policies/pipeline_execution_policies.md)
- [Compliance framework](../../compliance/compliance_frameworks/_index.md)
