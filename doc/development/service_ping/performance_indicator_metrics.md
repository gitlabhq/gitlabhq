---
stage: Analytics
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Performance Indicator Metrics guide

This guide describes how to use metrics definitions to define [performance indicator](https://about.gitlab.com/handbook/product/product-intelligence-guide/#implementing-product-performance-indicators) metrics.

To use a metric definition to manage a performance indicator:

1. Create a new issue and use the [Performance Indicator Metric issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Performance%20Indicator%20Metric).
1. Use labels `~"product intelligence"`, `"~Data Warehouse::Impact Check"`.
1. Create a merge request that includes changes related only to the metric performance indicator.
1. Update the metric definition `performance_indicator_type` [field](metrics_dictionary.md#metrics-definition-and-validation).
1. Create an issue in GitLab Data Team project with the [Product Performance Indicator template](https://gitlab.com/gitlab-data/analytics/-/issues/new?issuable_template=Product%20Performance%20Indicator%20Template).
