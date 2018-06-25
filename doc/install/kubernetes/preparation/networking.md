# Networking Prerequisites

> **Note**: Amazon EKS utilizes Elastic Load Balancers, which are addressed by DNS name and cannot be known ahead of time. Skip this section.

The `gitlab` chart configures a GitLab server and Kubernetes cluster which can support dynamic [Review Apps](https://docs.gitlab.com/ee/ci/review_apps/index.html), as well as services like the integrated [Container Registry](https://docs.gitlab.com/ee/user/project/container_registry.html).

To support the GitLab services and dynamic environments, a wildcard DNS entry is required which resolves to the external IP.

## External IP

To provision an external IP on GCP and Azure, simply request a new address from the Networking section. Ensure that the region matches the region your container cluster is created in. Note, it is important that the IP is not assigned at this point in time. It will be automatically assigned once the Helm chart is installed, to the Load Balancer.

Set `global.hosts.externalIP` to this IP address when [deploying GitLab](../gitlab_chart.md#configuring-and-installing-gitlab).

Then, create a [wildcard DNS record](#wildcard-dns-entry) which resolves to this IP address.

### Creating an external IP on GCP

When creating the external IP, it is critical to create it in the same region as your cluster. Otherwise, the IP address will fail to bind to the Load Balancer.

1. Open the [web console](https://console.cloud.google.com)
1. In the sidebar, browse to `VPC Network > External IP addresses`
1. Click `Reserve static address`
1. Choose `Regional` and select the region of your cluster
1. Leave `Attached to` blank, as it will be automatically assigned during deployment

## Wildcard DNS entry

Now that an external IP address has been allocated, ensure that the wildcard DNS entry you would like to use resolves to this IP. Typically this would be an `A record` for `*`, resolving to the external IP above.

Please consult the documentation for your DNS service for more information on creating DNS records:

* [Google Domains](https://support.google.com/domains/answer/3290350?hl=en)
* [GoDaddy](https://www.godaddy.com/help/add-an-a-record-19238)

Set `global.hosts.domain` to this DNS name when [deploying GitLab](../gitlab_chart.md#configuring-and-installing-gitlab).
