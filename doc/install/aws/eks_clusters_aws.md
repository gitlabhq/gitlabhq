---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# EKS cluster provisioning best practices **(FREE SELF)**

GitLab can be used to provision an EKS cluster into AWS, however, it necessarily focuses on a basic EKS configuration. Using the AWS tools can help with advanced cluster configuration, automation, and maintenance.

This documentation is not for clusters for deployment of GitLab itself, but instead clusters purpose built for:

- EKS Clusters for GitLab Runners
- Application Deployment Clusters for GitLab review apps
- Application Deployment Cluster for production applications

Information on deploying GitLab onto EKS can be found in [Provisioning GitLab Cloud Native Hybrid on AWS EKS](gitlab_hybrid_on_aws.md).

## Use `eksctl`

Using `eksctl` enables the following when building an EKS Cluster:

- You have various cluster configuration options:
  - Selection of operating system: Amazon Linux 2, Windows, Bottlerocket
  - Selection of Hardware Architecture: x86, ARM, GPU
  - Selection of Kubernetes version (the GitLab-managed clusters for your project's applications have [specific Kubernetes version requirements](../../user/clusters/agent/index.md#gitlab-agent-for-kubernetes-supported-cluster-versions))
- It can deploy high value-add items to the cluster, including:
  - A bastion host to keep the cluster endpoint private and possible perform performance testing.
  - Prometheus and Grafana for monitoring.
- EKS Autoscaler for automatic K8s Node scaling.
- 2 or 3 Availability Zones (AZ) spread for balance between High Availability (HA) and cost control.
- Ability to specify spot compute.

Read more about Amazon EKS architecture quick start guide:

- [Landing page](https://aws.amazon.com/solutions/implementations/amazon-eks/)
- [Reference guide](https://aws-quickstart.github.io/quickstart-amazon-eks/)
- [Reference guide deployment steps](https://aws-quickstart.github.io/quickstart-amazon-eks/#_deployment_steps)
- [Reference guide parameter reference](https://aws-quickstart.github.io/quickstart-amazon-eks/#_parameter_reference)

## Inject GitLab configuration for integrating clusters

Read more how to [configure an App Deployment cluster](../../user/project/clusters/add_existing_cluster.md) and extract information from it to integrate it into GitLab.

## Provision GitLab Runners using Helm charts

Read how to [use the GitLab Runner Helm Chart](https://docs.gitlab.com/runner/install/kubernetes.html) to deploy a runner into a cluster.

## Runner Cache

Because the EKS Quick Start provides for EFS provisioning, the best approach is to use EFS for runner caching. Eventually we will publish information on using an S3 bucket for runner caching here.
