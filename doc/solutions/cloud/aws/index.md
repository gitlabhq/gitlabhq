---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
---

# AWS Solutions

This documentation covers solutions relating to GitLab and Amazon Web Services (AWS).

[GitLab AWS Integration Index](gitlab_aws_integration.md)
[GitLab Instances on AWS EKS](gitlab_instance_on_aws.md)
[SRE Considerations Gitaly on AWS](gitaly_sre_for_aws.md)
[Provision GitLab on a single EC2 instance in AWS](gitlab_single_box_on_aws.md)

## Cloud platform well architected compliance

Testing-backed architectural qualification is a fundamental concept behind implementation patterns:

- Implementation patterns maintain GitLab Reference Architecture compliance and provide [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) (GPT) reports to demonstrate adherence to them.
- Implementation patterns may be qualified by and/or contributed to by the technology vendor. For instance, an implementation pattern for AWS may be officially reviewed by AWS.
- Implementation patterns may specify and test Cloud Platform PaaS services for suitability for GitLab. This testing can be coordinated and help qualify these technologies for Reference Architectures. For instance, qualifying compatibility with and availability of runtime versions of top level PaaS such as those for PostgreSQL and Redis.
- Implementation patterns can provided qualified testing for platform limitations, for example, ensuring Gitaly Cluster can work correctly on specific Cloud Platform availability zone latency and throughput characteristics or qualifying what levels of available platform partner local disk performance is workable for Gitaly server to operate with integrity.

## AWS known issues list

Known issues are gathered from within GitLab and from customer reported issues. Customers successfully implement GitLab with a variety of “as a Service” components that GitLab has not specifically been designed for, nor has ongoing testing for. While GitLab does take partner technologies very seriously, the highlighting of known issues here is a convenience for implementers and it does not imply that GitLab has targeted compatibility with, nor carries any type of guarantee of running on the partner technology where the issues occur. Consult individual issues to understand the GitLab stance and plans on any given known issue.

See the [GitLab AWS known issues list](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues?label_name[]=AWS+Known+Issue) for a complete list.

## Patterns with working code examples for using GitLab with AWS

[The Guided Explorations' subgroup for AWS](https://gitlab.com/guided-explorations/aws) contains a variety of working example projects.

## Platform partner specificity

Implementation patterns enable platform-specific terminology, best practice architecture, and platform-specific build manifests:

- Implementation patterns are more vendor specific. For instance, advising specific compute instances / VMs / nodes instead of vCPUs or other generalized measures.
- Implementation patterns are oriented to implementing good architecture for the vendor in view.
- Implementation patterns are written to an audience who is familiar with building on the infrastructure that the implementation pattern targets. For example, if the implementation pattern is for GCP, the specific terminology of GCP is used - including using the specific names for PaaS services.
- Implementation patterns can test and qualify if the versions of PaaS available are compatible with GitLab (for example, PostgreSQL, Redis, etc.).

## Platform as a Service (PaaS) specification and usage

Platform as a Service options are a huge portion of the value provided by Cloud Platforms as they simplify operational complexity and reduce the SRE and security skilling required to operate advanced, highly available technology services. Implementation patterns can be pre-qualified against the partner PaaS options.

- Implementation patterns help implementers understand what PaaS options are known to work and how to choose between PaaS solutions when a single platform has more than one PaaS option for the same GitLab role.
- For instance, where reference architectures do not have a specific recommendation on what technology is leveraged for GitLab outbound email services or what the sizing should be - a Reference Implementation may advise using a cloud providers Email as a Service (PaaS) and possibly even with specific settings.

## Cost optimizing engineering

Cost engineering is a fundamental aspect of Cloud Architecture and frequently the savings capabilities available on a platform exert strong influence on how to build out scaled computing.

- Implementation patterns may engineer specifically for the savings models available on a platform provider. An AWS example would be maximizing the occurrence of a specific instance type for taking advantage of reserved instances.
- Implementation patterns may leverage ephemeral compute where appropriate and with appropriate customer guidelines. For instance, a Kubernetes node group dedicated to runners on ephemeral compute (with appropriate GitLab Runner tagging to indicate the compute type).
- Implementation patterns may include vendor specific cost calculators.

## Actionability and automatability orientation

Implementation patterns are one step closer to specifics that can be used as a source for build instructions and automation code:

- Implementation patterns enable builders to generate a list of vendor specific resources required to implement GitLab for a given Reference Architecture.
- Implementation patterns enable builders to use manual instructions or to create automation to build out the reference implementation.

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
