---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: Read through the GitLab installation methods.
type: index
---

# AWS implementation patterns **(FREE SELF)**

GitLab [Reference Architectures](../../administration/reference_architectures/index.md) give qualified and tested guidance on the recommended ways GitLab can be configured to meet the performance requirements of various workloads. Reference Architectures are purpose-designed to be non-implementation specific so they can be extrapolated to as many environments as possible. This generally means they have a highly-granular "machine" to "server role" specification and focus on system elements that impact performance. This is what enables Reference Architectures to be adaptable to the broadest number of supported implementations.

Implementation patterns are built on the foundational information and testing done for Reference Architectures and allow architects and implementers at GitLab, GitLab Customers, and GitLab Partners to build out deployments with less experimentation and a higher degree of confidence that the results will perform as expected. A more thorough discussion of implementation patterns is below in [Additional details on implementation patterns](#additional-details-on-implementation-patterns).

## AWS Implementation patterns information

The following are the currently available implementation patterns for GitLab when it is implemented on AWS.

### GitLab Site Reliability Engineering (SRE) for AWS

[GitLab Site Reliability Engineering (SRE) for AWS](gitlab_sre_for_aws.md) - information for planning, implementing, upgrading and long term management of GitLab instances and runners on AWS.

### Patterns to Install GitLab Cloud Native Hybrid on AWS EKS (HA)

[Provision GitLab Cloud Native Hybrid on AWS EKS (HA)](gitlab_hybrid_on_aws.md). This document includes instructions, patterns, and automation for installing GitLab Cloud Native Hybrid on AWS EKS. It also includes [Bill of Materials](https://en.wikipedia.org/wiki/Bill_of_materials) listings and links to Infrastructure as Code. GitLab Cloud Native Hybrid is the supported way to put as much of GitLab as possible into Kubernetes.

### Patterns to Install Omnibus GitLab on AWS EC2 (HA)

[Omnibus GitLab on AWS EC2 (HA)](manual_install_aws.md) - instructions for installing GitLab on EC2 instances. Manual instructions to build a GitLab instance or create your own Infrastructure as Code (IaC).

### Patterns for EKS cluster provisioning

[EKS Cluster Provisioning Patterns](eks_clusters_aws.md) - considerations for setting up EKS cluster for runners and for integrating.

### Patterns for Scaling HA GitLab Runner on AWS EC2 ASG

The following repository is self-contained in regard to enabling this pattern: [GitLab HA Scaling Runner Vending Machine for AWS EC2 ASG](https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/). The [feature list for this implementation pattern](https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/-/blob/main/FEATURES.md) is good to review to understand the complete value it can deliver.

## AWS known issues list

Known issues are gathered from within GitLab and from customer reported issues. Customers successfully implement GitLab with a variety of "as a Service" components that GitLab has not specifically been designed for, nor has ongoing testing for. While GitLab does take partner technologies very seriously, the highlighting of known issues here is a convenience for implementers and it does not imply that GitLab has targeted compatibility with, nor carries any type of guarantee of running on the partner technology where the issues occur. Please consult individual issues to understand GitLabs stance and plans on any given known issue.

See the [GitLab AWS known issues list](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues?label_name%5B%5D=AWS+Known+Issue) for a complete list.

## Additional details on implementation patterns

GitLab implementation patterns build upon [GitLab Reference Architectures](../../administration/reference_architectures/index.md) in the following ways.

### Cloud platform well architected compliance

Testing-backed architectural qualification is a fundamental concept behind implementation patterns:

- Implementation patterns maintain GitLab Reference Architecture compliance and provide [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) (gpt) reports to demonstrate adherence to them.
- Implementation patterns may be qualified by and/or contributed to by the technology vendor. For instance, an implementation pattern for AWS may be officially reviewed by AWS.
- Implementation patterns may specify and test Cloud Platform PaaS services for suitability for GitLab. This testing can be coordinated and help qualify these technologies for Reference Architectures. For instance, qualifying compatibility with and availability of runtime versions of top level PaaS such as those for PostgreSQL and Redis.
- Implementation patterns can provided qualified testing for platform limitations, for example, ensuring Gitaly Cluster can work correctly on specific Cloud Platform availability zone latency and throughput characteristics or qualifying what levels of available platform partner local disk performance is workable for Gitaly server to operate with integrity.

### Platform partner specificity

Implementation patterns enable platform-specific terminology, best practice architecture, and platform-specific build manifests:

- Implementation patterns are more vendor specific. For instance, advising specific compute instances / VMs / nodes instead of vCPUs or other generalized measures.
- Implementation patterns are oriented to implementing good architecture for the vendor in view.
- Implementation patterns are written to an audience who is familiar with building on the infrastructure that the implementation pattern targets. For example, if the implementation pattern is for GCP, the specific terminology of GCP is used - including using the specific names for PaaS services.
- Implementation patterns can test and qualify if the versions of PaaS available are compatible with GitLab (for example, PostgreSQL, Redis, etc.).

### Platform as a Service (PaaS) specification and usage

Platform as a Service options are a huge portion of the value provided by Cloud Platforms as they simplify operational complexity and reduce the SRE and security skilling required to operate advanced, highly available technology services. Implementation patterns can be prequalified against the partner PaaS options.

- Implementation patterns help implementers understand what PaaS options are known to work and how to choose between PaaS solutions when a single platform has more than one PaaS option for the same GitLab role.
- For instance, where reference architectures do not have a specific recommendation on what technology is leveraged for GitLab outbound email services or what the sizing should be - a Reference Implementation may advise using a cloud providers Email as a Service (PaaS) and possibly even with specific settings.

### Cost optimizing engineering

Cost engineering is a fundamental aspect of Cloud Architecture and frequently the savings capabilities available on a platform exert strong influence on how to build out scaled computing.

- Implementation patterns may define GPT tested autoscaling for various aspects of GitLab infrastructure, including minimum idling configurations and scaling speeds.
- Implementation patterns may provide GPT testing for advised configurations that go beyond the scope of reference architectures, for instance GPT tested elastic scaling configurations for Cloud Native Hybrid that enable lower resourcing during periods of lower usage (for example on the weekend).
- Implementation patterns may engineer specifically for the savings models available on a platform provider. An AWS example would be maximizing the occurrence of a specific instance type for taking advantage of reserved instances.
- Implementation patterns may leverage ephemeral compute where appropriate and with appropriate customer guidelines. For instance, a Kubernetes node group dedicated to runners on ephemeral compute (with appropriate GitLab Runner tagging to indicate the compute type).
- Implementation patterns may include vendor specific cost calculators.

### Actionability and automatability orientation

Implementation patterns are one step closer to specifics that can be used as a source for build instructions and automation code:

- Implementation patterns enable builders to generate a list of vendor specific resources required to implement GitLab for a given Reference Architecture.
- Implementation patterns enable builders to use manual instructions or to create automation to build out the reference implementation.

## Supplementary implementation patterns

Implementation patterns may also provide specialized implementations beyond the scope of reference architecture compliance, especially where the cost of enablement can be more appropriately managed.

For example:

- Small, self-contained GitLab instances for per-person administration training, perhaps on Kubernetes so that a deployment cluster is self-contained as well.
- GitLab Runner implementation patterns, including using platform-specific PaaS.

## Intended audiences and contributors

The primary audiences for and contributors to this information is the GitLab **Implementation Eco System** which consists of at least:

GitLab Implementation Community:

- Customers
- GitLab Channel Partners (Integrators)
- Platform Partners

GitLab Internal Implementation Teams:

- Quality / Distribution / Self-Managed
- Alliances
- Training
- Support
- Professional Services
- Public Sector
