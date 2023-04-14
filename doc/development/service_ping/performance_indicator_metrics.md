---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Performance Indicator Metrics guide

This guide describes how to use metrics definitions to define [performance indicator](https://about.gitlab.com/handbook/product/product-intelligence-guide/#implementing-product-performance-indicators) metrics.

To use a metric definition to manage a performance indicator:

1. Create a merge request that includes related changes.
1. Use labels `~"product intelligence"`, `"~Data Warehouse::Impact Check"`.
1. Update the metric definition `performance_indicator_type` [field](metrics_dictionary.md#metrics-definition-and-validation).
1. Create an issue in GitLab Product Data Insights project with the [PI Chart Help template](https://gitlab.com/gitlab-data/product-analytics/-/issues/new?issuable_template=PI%20Chart%20Help) to have the new metric visualized.
