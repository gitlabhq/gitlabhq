---
stage: Analyze
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Product analytics **(ULTIMATE)** **Alpha**

> Introduced in GitLab 15.4 [with a flag](../../administration/feature_flags.md) named `cube_api_proxy`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `cube_api_proxy`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

## Overview

You can view the [product category](https://about.gitlab.com/direction/analytics/product-analytics/) page for more information about our direction. This page is a work in progress and will be updated as we add more features.

## Product analytics dashboards

Each project can define an unlimited number of dashboards. These dashboards are defined using our YAML schema and stored
in the `.gitlab/product_analytics/dashboards/` directory. The name of the file is the name of the dashboard, and visualizations are shared across dashboards..

Project maintainers can enforce approval rules on dashboard changes, and dashboards can be versioned in source control.

### Define a dashboard

To define a dashboard:

1. In `.gitlab/product_analytics/dashboards/`, create a directory named like the dashboard. Each dashboard should have its own directory.
1. In the new directory, create a `.yaml` file with the same name as the directory. This file contains the dashboard definition, and must conform to the JSON schema defined in `ee/app/validators/json_schemas/product_analytics_dashboard.json`.
1. In the `.gitlab/product_analytics/dashboards/visualizations/` directory, create a `yaml` file. This file defines the visualization type for the dashboard, and must conform to the schema in 
`ee/app/validators/json_schemas/product_analytics_visualization.json`.

The example below includes three dashboards and one visualization that applies to all dashboards.

```plaintext
.gitlab/product_analytics/dashboards
├── conversion_funnels
│  └── conversion_funnels.yaml
├── demographic_breakdown
│  └── demographic_breakdown.yaml
├── north_star_metrics
|  └── north_star_metrics.yaml
├── visualizations
│  └── example_line_chart.yaml
```
