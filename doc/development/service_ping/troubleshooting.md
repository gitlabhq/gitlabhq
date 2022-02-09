---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting

## Service Ping Payload drop

### Symptoms

You will be alerted by a [Sisense alert](https://app.periscopedata.com/app/gitlab/alert/Service-ping-payload-drop-Alert/5a5b8766b8af43b4a75d6e9c684a365f/edit) that is sent to `#g_product_intelligence` Slack channel

### Locating the problem

First you need to identify at which stage in Service Ping data pipeline the drop is occurring.

Start at [Service Ping Health Dashboard](https://app.periscopedata.com/app/gitlab/968489/Product-Intelligence---Service-Ping-Health) on Sisense.

The alert compares the current daily value with the daily value from previous week, excluding the last 48 hours as this is the interval where we export the data in GCP and get it into DWH.

You can use [this query](https://gitlab.com/gitlab-org/gitlab/-/issues/347298#note_836685350) as an example, to start detecting when the drop started.

### Troubleshooting GitLab application layer

For results about an investigation conducted into an unexpected drop in Service ping Payload events volume, see [this issue](https://gitlab.com/gitlab-data/analytics/-/issues/11071).

### Troubleshooting data warehouse layer

Reach out to the [Data team](https://about.gitlab.com/handbook/business-technology/data-team) to ask about current state of data warehouse. On their handbook page there is a [section with contact details](https://about.gitlab.com/handbook/business-technology/data-team/#how-to-connect-with-us).
