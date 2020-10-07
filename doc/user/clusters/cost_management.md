---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Cluster cost management

Cluster cost management provides insights into cluster resource usage. GitLab provides an example
[`kubecost-cost-model`](https://gitlab.com/gitlab-examples/kubecost-cost-model/)
project that uses GitLab's Prometheus integration and
[Kubecost's `cost-model`](https://github.com/kubecost/cost-model) to provide cluster cost
insights within GitLab:

![Example dashboard](img/kubecost_v13_5.png)

## Configure cluster cost management

To get started with cluster cost management, you need [Maintainer](../permissions.md)
permissions in a project or group.

1. Clone the [`kubecost-cost-model`](https://gitlab.com/gitlab-examples/kubecost-cost-model/)
   example repository, which contains minor modifications to the upstream Kubecost
   `cost-model` project:
   - Configures your Prometheus endpoint to the GitLab-managed Prometheus. You may
     need to change this value if you use a non-managed Prometheus.
   - Adds the necessary annotations to the deployment manifest to be scraped by
     GitLab-managed Prometheus.
   - Changes the Google Pricing API access key to GitLab's access key.
   - Contains definitions for a custom GitLab Metrics dashboard to show the cost insights.
1. Connect GitLab with Prometheus, depending on your configuration:
   - *If Prometheus is already configured,* navigate to **Settings > Integrations > Prometheus**
     to provide the API endpoint of your Prometheus server.
   - *For GitLab-managed Prometheus,* navigate to your cluster's **Details** page,
     select the **Applications** tab, and install Prometheus. The integration is
     auto-configured for you.
1. Set up the Prometheus integration on the cloned example project.
1. Add the Kubecost `cost-model` to your cluster:
   - *For non-managed clusters*, deploy it with GitLab CI/CD.
   - *To deploy it manually*, use the following commands:

     ```shell
     kubectl create namespace cost-model
     kubectl apply -f kubernetes/ --namespace cost-model
     ```

To access the cost insights, navigate to **Operations > Metrics** and select
the `default_costs.yml` dashboard. You can [customize](#customize-the-cost-dashboard)
this dashboard.

### Customize the cost dashboard

You can customize the cost dashboard by editing the `.gitlab/dashboards/default_costs.yml`
file or creating similar dashboard configuration files. To learn more, read about
[customizing dashboards in our documentation](/ee/operations/metrics/dashboards/).
