---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Reference architectures **(FREE SELF)**

The GitLab Reference Architectures have been designed and tested by the
GitLab Quality Engineering and Support teams to provide recommended deployments at scale.

## Available reference architectures

The following Reference Architectures are available as recommended starting points for your environment.

The architectures are named in terms of user count, which in this case means the architecture is designed against
the _total_ load that comes with such a user count based on real data along with substantial headroom added to cover most scenarios such as CI or other automated workloads.

However, it should be noted that in some cases, known heavy scenarios such as [large monorepos](#large-monorepos) or notable [additional workloads](#additional-workloads) may require adjustments to be made.

For details about what each Reference Architecture has been tested against, see the "Testing Methodology" section of each page.

### GitLab package (Omnibus)

Below is a list of Linux package based architectures:

- [Up to 1,000 users](1k_users.md) <span style="color: darkgrey;">_API: 20 RPS, Web: 2 RPS, Git (Pull): 2 RPS, Git (Push): 1 RPS_</span>
- [Up to 2,000 users](2k_users.md) <span style="color: darkgrey;">_API: 40 RPS, Web: 4 RPS, Git (Pull): 4 RPS, Git (Push): 1 RPS_</span>
- [Up to 3,000 users](3k_users.md) <span style="color: darkgrey;">_API: 60 RPS, Web: 6 RPS, Git (Pull): 6 RPS, Git (Push): 1 RPS_</span>
- [Up to 5,000 users](5k_users.md) <span style="color: darkgrey;">_API: 100 RPS, Web: 10 RPS, Git (Pull): 10 RPS, Git (Push): 2 RPS_</span>
- [Up to 10,000 users](10k_users.md) <span style="color: darkgrey;">_API: 200 RPS, Web: 20 RPS, Git (Pull): 20 RPS, Git (Push): 4 RPS_</span>
- [Up to 25,000 users](25k_users.md) <span style="color: darkgrey;">_API: 500 RPS, Web: 50 RPS, Git (Pull): 50 RPS, Git (Push): 10 RPS_</span>
- [Up to 50,000 users](50k_users.md) <span style="color: darkgrey;">_API: 1000 RPS, Web: 100 RPS, Git (Pull): 100 RPS, Git (Push): 20 RPS_</span>

### Cloud native hybrid

Below is a list of Cloud Native Hybrid reference architectures, where select recommended components can be run in Kubernetes:

- [Up to 2,000 users](2k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) <span style="color: darkgrey;">_API: 40 RPS, Web: 4 RPS, Git (Pull): 4 RPS, Git (Push): 1 RPS_</span>
- [Up to 3,000 users](3k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) <span style="color: darkgrey;">_API: 60 RPS, Web: 6 RPS, Git (Pull): 6 RPS, Git (Push): 1 RPS_</span>
- [Up to 5,000 users](5k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) <span style="color: darkgrey;">_API: 100 RPS, Web: 10 RPS, Git (Pull): 10 RPS, Git (Push): 2 RPS_</span>
- [Up to 10,000 users](10k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) <span style="color: darkgrey;">_API: 200 RPS, Web: 20 RPS, Git (Pull): 20 RPS, Git (Push): 4 RPS_</span>
- [Up to 25,000 users](25k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) <span style="color: darkgrey;">_API: 500 RPS, Web: 50 RPS, Git (Pull): 50 RPS, Git (Push): 10 RPS_</span>
- [Up to 50,000 users](50k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) <span style="color: darkgrey;">_API: 1000 RPS, Web: 100 RPS, Git (Pull): 100 RPS, Git (Push): 20 RPS_</span>

## Before you start

The first choice to consider is whether a Self Managed approach is correct for you and your requirements.

Running any application in production is complex, and the same applies for GitLab. While we aim to make this as smooth as possible, there are still the general complexities. This depends on the design chosen, but typically you'll need to manage all aspects such as hardware, operating systems, networking, storage, security, GitLab itself, and more. This includes both the initial setup of the environment and the longer term maintenance.

As such, it's recommended that you have a working knowledge of running and maintaining applications in production when deciding on going down this route. If you aren't in this position, our [Professional Services](https://about.gitlab.com/services/#implementation-services) team offers implementation services, but for those who want a more managed solution long term, it's recommended to instead explore our other offerings such as [GitLab SaaS](../../subscriptions/gitlab_com/index.md) or [GitLab Dedicated](../../subscriptions/gitlab_dedicated/index.md).

If Self Managed is the approach you're considering, it's strongly encouraged to read through this page in full, in particular the [Deciding which architecture to use](#deciding-which-architecture-to-use), [Large monorepos](#large-monorepos) and [Additional workloads](#additional-workloads) sections.

## Deciding which architecture to use

The Reference Architectures are designed to strike a balance between two important factors--performance and resilience.

While they are designed to make it easier to set up GitLab at scale, it can still be a challenge to know which one meets your requirements.

As a general guide, **the more performant and/or resilient you want your environment to be, the more complex it is**.

This section explains the designs you can choose from. It begins with the least complexity, goes to the most, and ends with a decision tree.

### Expected Load (RPS)

The first thing to check is what the expected load is your environment would be expected to serve.

The Reference Architectures have been designed with substantial headroom by default, but it's recommended to also check the
load of what each architecture has been tested against under the "Testing Methodology" section found on each page,
comparing those values with what load you are expecting against your existing GitLab environment to help select the right Reference Architecture
size.

Load is given in terms of Requests per Second (RPS) for each endpoint type (API, Web, Git). This information on your existing infrastructure
can typically be surfaced by most reputable monitoring solutions or in some other ways such as load balancer metrics. For example, on existing GitLab environments,
[Prometheus metrics](../monitoring/prometheus/gitlab_metrics.md) such as `gitlab_transaction_duration_seconds` can be used to see this data.

### Standalone (non-HA)

For environments serving 2,000 or fewer users, we generally recommend a standalone approach by deploying a non-highly available single or multi-node environment. With this approach, you can employ strategies such as [automated backups](../../administration/backup_restore/backup_gitlab.md#configuring-cron-to-make-daily-backups) for recovery to provide a good level of RPO / RTO while avoiding the complexities that come with HA.

*[RTO]: Recovery time objective
*[RPO]: Recovery point objective

With standalone setups, especially single node environments, there are [various options available for installation](../../install/index.md) and management including [the ability to deploy directly via select cloud provider marketplaces](https://page.gitlab.com/cloud-partner-marketplaces.html) that reduce the complexity a little further.

### High Availability (HA)

High Availability ensures every component in the GitLab setup can handle failures through various mechanisms. However, to achieve this is complex, and the environments required can be sizable.

For environments serving 3,000 or more users we generally recommend that a HA strategy is used as at this level outages have a bigger impact against more users. All the architectures in this range have HA built in by design for this reason.

#### Do you need High Availability (HA)?

As mentioned above, achieving HA does come at a cost. The environment requirements are sizable as each component needs to be multiplied, which comes with additional actual and maintenance costs.

For a lot of our customers with fewer than 3,000 users, we've found a backup strategy is sufficient and even preferable. While this does have a slower recovery time, it also means you have a much smaller architecture and less maintenance costs as a result.

In general then, we'd only recommend you employ HA in the following scenarios:

- When you have 3,000 or more users.
- When GitLab being down would critically impact your workflow.

#### Scaled-down High Availability (HA) approaches

If you still need to have HA for a lower number of users, this can be achieved with an adjusted [3K architecture](3k_users.md#supported-modifications-for-lower-user-counts-ha).

#### Zero Downtime Upgrades

[Zero Downtime Upgrades](../../update/zero_downtime.md) are available for standard Reference Architecture environments with HA (Cloud Native Hybrid is [not supported](https://gitlab.com/groups/gitlab-org/cloud-native/-/epics/52)). This allows for an environment to stay up during an upgrade, but the process is more complex as a result and has some limitations as detailed in the documentation.

When going through this process it's worth noting that there may still be brief moments of downtime when the HA mechanisms take effect.

In most cases the downtime required for doing an upgrade shouldn't be substantial, so this is only recommended if it's a key requirement for you.

### Cloud Native Hybrid (Kubernetes HA)

As an additional layer of HA resilience you can deploy select components in Kubernetes, known as a Cloud Native Hybrid Reference Architecture. For stability
reasons, stateful components such as Gitaly [cannot be deployed in Kubernetes](#stateful-components-in-kubernetes).

This is an alternative and more **advanced** setup compared to a standard Reference Architecture. Running services in Kubernetes is well known to be complex. **This setup is only recommended** if you have strong working knowledge and experience in Kubernetes.

### GitLab Geo (Cross Regional Distribution / Disaster Recovery)

With [GitLab Geo](../geo/index.md), you can achieve distributed environments in
different regions with a full Disaster Recovery (DR) setup in place. GitLab Geo
requires at least two separate environments:

- One primary site.
- One or more secondary sites that serve as replicas.

If the primary site becomes unavailable, you can fail over to one of the secondary sites.

This **advanced and complex** setup should only be undertaken if DR is
a key requirement for your environment. You must also make additional decisions
on how each site is configured, such as if each secondary site would be the
same architecture as the primary, or if each site is configured for HA.

### Large monorepos / Additional workloads

If you have any [large monorepos](#large-monorepos) or significant [additional workloads](#additional-workloads), these can affect the performance of the environment notably and adjustments may be required depending on the context.

If either applies to you, it's encouraged for you to reach out to your [Customer Success Manager](https://handbook.gitlab.com/job-families/sales/customer-success-management/) or our [Support team](https://about.gitlab.com/support/)
for further guidance.

### Cloud provider services

For all the previously described strategies, you can run select GitLab components on equivalent cloud provider services such as the PostgreSQL database or Redis.

[For more information, see the recommended cloud providers and services](#recommended-cloud-providers-and-services).

### Decision Tree

Below you can find the above guidance in the form of a decision tree. It's recommended you read through the above guidance in full first before though.

```mermaid
%%{init: { 'theme': 'base' } }%%
graph TD
   L0A(<b>What Reference Architecture should I use?</b>)
   L1A(<b>What is your <a href=#expected-load-rps>expected load</a>?</b>)

   L2A("Equivalent to <a href=3k_users.md#testing-methodology>3,000 users</a> or more?")
   L2B("Equivalent to <a href=2k_users.md#testing-methodology>2,000 users</a> or less?")

   L3A("<a href=#do-you-need-high-availability-ha>Do you need HA?</a><br>(or Zero-Downtime Upgrades)")
   L3B[Do you have experience with<br/>and want additional resilience<br/>with select components in Kubernetes?]

   L4A><b>Recommendation</b><br><br>3K architecture with HA<br>and supported reductions]
   L4B><b>Recommendation</b><br><br>Architecture closest to user<br>count with HA]
   L4C><b>Recommendation</b><br><br>Cloud Native Hybrid architecture<br>closest to user count]
   L4D>"<b>Recommendation</b><br><br>Standalone 1K or 2K<br/>architecture with Backups"]

   L0A --> L1A
   L1A --> L2A
   L1A --> L2B
   L2A -->|Yes| L3B
   L3B -->|Yes| L4C
   L3B -->|No| L4B

   L2B --> L3A
   L3A -->|Yes| L4A
   L3A -->|No| L4D
   L5A("<a href=#gitlab-geo-cross-regional-distribution-disaster--recovery>Do you need cross regional distribution</br> or disaster recovery?"</a>) --> |Yes| L6A><b>Additional Recommendation</b><br><br> GitLab Geo]
   L4A ~~~ L5A
   L4B ~~~ L5A
   L4C ~~~ L5A
   L4D ~~~ L5A

   L5B("Do you have <a href=#large-monorepos>Large Monorepos</a> or expect</br> to have substantial <a href=#additional-workloads>additional workloads</a>?") --> |Yes| L6B><b>Additional Recommendation</b><br><br> Contact Customer Success Manager or Support]
   L4A ~~~ L5B
   L4B ~~~ L5B
   L4C ~~~ L5B
   L4D ~~~ L5B

classDef default fill:#FCA326
linkStyle default fill:none,stroke:#7759C2
```

## Requirements

Before implementing a reference architecture, refer to the following requirements and guidance.

### Supported CPUs

These reference architectures were built and tested on Google Cloud Platform (GCP) using the
[Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
CPU platform as the lowest common denominator baseline ([Sysbench benchmark](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks)).
Newer, similarly-sized CPUs are supported and may have improved performance as a result.

ARM CPUs are supported for Linux package environments as well as for any [Cloud Provider services](#cloud-provider-services) where applicable.

NOTE:
Any "burstable" instance types are not recommended due to inconsistent performance.

### Supported disk types

As a general guidance, most standard disk types are expected to work for GitLab, but be aware of the following specific call-outs:

- [Gitaly](../gitaly/index.md#disk-requirements) requires at least 8,000 input/output operations per second (IOPS) for read operations, and 2,000 IOPS for write operations.
- We don't recommend the use of any disk types that are "burstable" due to inconsistent performance.

Outside the above standard, disk types are expected to work for GitLab and the choice of each depends on your specific requirements around areas, such as durability or costs.

### Supported infrastructure

As a general guidance, GitLab should run on most infrastructure such as reputable Cloud Providers (AWS, GCP, Azure) and
their services, or self-managed (ESXi) that meet both:

- The specifications detailed in each reference architecture.
- Any requirements in this section.

However, this does not constitute a guarantee for every potential permutation.

See [Recommended cloud providers and services](index.md#recommended-cloud-providers-and-services) for more information.

### Large Monorepos

The reference architectures were tested with repositories of varying sizes that follow best practices.

**However, [large monorepos](../../user/project/repository/monorepos/index.md) (several gigabytes or more) can significantly impact the performance of Git and in turn the environment itself.**
Their presence, as well as how they are used, can put a significant strain on the entire system from Gitaly through to the underlying infrastructure.

WARNING:
If this applies to you, we strongly recommended referring to the linked documentation as well as reaching out to your [Customer Success Manager](https://handbook.gitlab.com/job-families/sales/customer-success-management/) or our [Support team](https://about.gitlab.com/support/) for further guidance.

As such, large monorepos come with notable cost. If you have such a repository we strongly recommend
the following guidance is followed to ensure the best chance of good performance and to keep costs in check:

- [Optimize the large monorepo](../../user/project/repository/monorepos/index.md#optimize-gitlab-settings). Using features such as
  [LFS](../../user/project/repository/monorepos/index.md#use-lfs-for-large-blobs) to not store binaries, and other approaches for reducing repository size, can
  dramatically improve performance and reduce costs.
- Depending on the monorepo, increased environment specifications may be required to compensate. Gitaly in particular will likely require additional resources along with Praefect, GitLab Rails, and Load Balancers. This depends notably on the monorepo itself and the usage against it.
- When the monorepo is significantly large (20 gigabytes or more) further additional strategies maybe required such as even further increased specifications or in some cases a separate Gitaly backend for the monorepo alone.
- Network and disk bandwidth is another potential consideration with large monorepos. In very heavy cases, it's possible to see bandwidth saturation if there's a high amount of concurrent clones (such as with CI). It's strongly recommended [reducing full clones wherever possible](../../user/project/repository/monorepos/index.md#reduce-concurrent-clones-in-cicd) in this scenario. Otherwise, additional environment specifications may be required to increase bandwidth, but this differs between cloud providers.

### Additional workloads

These reference architectures have been [designed and tested](index.md#validation-and-test-results) for standard GitLab
setups with good headroom in mind to cover most scenarios.

However, additional workloads can multiply the impact of operations by triggering follow-up actions.
You may need to adjust the suggested specifications to compensate if you use, for example:

- Security software on the nodes.
- Hundreds of concurrent CI jobs for [large repositories](../../user/project/repository/monorepos/index.md).
- Custom scripts that [run at high frequency](../logs/log_parsing.md#print-top-api-user-agents).
- [Integrations](../../integration/index.md) in many large projects.
- [Server hooks](../server_hooks.md).
- [System hooks](../system_hooks.md).

As a general rule, you should have robust monitoring in place to measure the impact of any additional workloads to
inform any changes needed to be made. It's also strongly encouraged for you to reach out to your [Customer Success Manager](https://handbook.gitlab.com/job-families/sales/customer-success-management/) or our [Support team](https://about.gitlab.com/support/)
for further guidance.

### No swap

Swap is not recommended in the reference architectures. It's a failsafe that impacts performance greatly. The
reference architectures are designed to have memory headroom to avoid needing swap.

### Praefect PostgreSQL

[Praefect requires its own database server](../gitaly/praefect.md#postgresql) and
that to achieve full High Availability, a third-party PostgreSQL database solution is required.

We hope to offer a built-in solution for these restrictions in the future. In the meantime, a non-HA PostgreSQL server
can be set up using the Linux package as the specifications reflect. Refer to the following issues for more information:

- [`omnibus-gitlab#7292`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7292).
- [`gitaly#3398`](https://gitlab.com/gitlab-org/gitaly/-/issues/3398).

## Recommended cloud providers and services

NOTE:
The following lists are non-exhaustive. Generally, other cloud providers not listed
here likely work with the same specs, but this hasn't been validated.
Additionally, when it comes to other cloud provider services not listed here,
it's advised to be cautious as each implementation can be notably different
and should be tested thoroughly before production use.

Through testing and real life usage, the Reference Architectures are validated and supported on the following cloud providers:

<table>
<thead>
  <tr>
    <th>Reference Architecture</th>
    <th>GCP</th>
    <th>AWS</th>
    <th>Azure</th>
    <th>Bare Metal</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Linux package</td>
    <td>🟢</td>
    <td>🟢</td>
    <td>🟡<sup>1</sup></td>
    <td>🟢</td>
  </tr>
  <tr>
    <td>Cloud Native Hybrid</td>
    <td>🟢</td>
    <td>🟢</td>
    <td></td>
    <td></td>
  </tr>
</tbody>
</table>

1. We only recommend smaller setups (up to 2k) at this time on Azure due to performance issues at larger scales. See the [Recommendation Notes for Azure](#recommendation-notes-for-azure) section for more info.

Additionally, the following cloud provider services are validated and supported for use as part of the Reference Architectures:

<table>
<thead>
  <tr>
    <th>Cloud Service</th>
    <th>GCP</th>
    <th>AWS</th>
    <th>Bare Metal</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Object Storage</td>
    <td>🟢 &nbsp; <a href="https://cloud.google.com/storage" target="_blank">Cloud Storage</a></td>
    <td>🟢 &nbsp; <a href="https://aws.amazon.com/s3/" target="_blank">S3</a></td>
    <td>🟢 &nbsp; <a href="https://min.io/" target="_blank">MinIO</a></td>
  </tr>
  <tr>
    <td>Database</td>
    <td>🟢 &nbsp; <a href="https://cloud.google.com/sql" target="_blank" rel="noopener noreferrer">Cloud SQL</a></td>
    <td>🟢 &nbsp; <a href="https://aws.amazon.com/rds/" target="_blank" rel="noopener noreferrer">RDS</a></td>
    <td></td>
  </tr>
  <tr>
    <td>Redis</td>
    <td>🟢 &nbsp; <a href="https://cloud.google.com/memorystore" target="_blank" rel="noopener noreferrer">Memorystore</a></td>
    <td>🟢 &nbsp; <a href="https://aws.amazon.com/elasticache/" target="_blank" rel="noopener noreferrer">ElastiCache</a></td>
    <td></td>
  </tr>
</tbody>
</table>

### Recommendation notes for the database services

[When selecting to use an external database service](../postgresql/external.md), it should run a standard, performant, and [supported version](../../install/requirements.md#postgresql-requirements).

If you choose to use a third party external service:

1. Note that the HA Linux package PostgreSQL setup encompasses PostgreSQL, PgBouncer and Consul. All of these components would no longer be required when using a third party external service.
1. The number of nodes required to achieve HA may differ depending on the service compared to the Linux package and doesn't need to match accordingly.
1. However, if [Database Load Balancing](../postgresql/database_load_balancing.md) via Read Replicas is desired for further improved performance it's recommended to follow the node count for the Reference Architecture.
1. If [GitLab Geo](../geo/index.md) is to be used the service will need to support Cross Region replication

### Recommendation notes for the Redis services

[When selecting to use an external Redis service](../redis/replication_and_failover_external.md#redis-as-a-managed-service-in-a-cloud-provider), it should run a standard, performant, and supported version.

Redis is primarily single threaded. For the 10,000 user and above Reference Architectures, separate out the instances as specified into Cache and Persistent data to achieve optimum performance at this scale.

### Recommendation notes for Object Storage

GitLab has been tested against [various Object Storage providers](../object_storage.md#supported-object-storage-providers) that are expected to work.

As a general guidance, it's recommended to use a reputable solution that has full S3 compatibility.

#### Unsupported database services

Several database cloud provider services are known not to support the above or have been found to have other issues and aren't recommended:

- [Amazon Aurora](https://aws.amazon.com/rds/aurora/) is incompatible and not supported. See [14.4.0](../../update/versions/gitlab_14_changes.md#1440) for more details.
- [Azure Database for PostgreSQL Single Server](https://azure.microsoft.com/en-gb/products/postgresql/#overview) is not supported for use due to notable performance / stability issues or missing functionality. See [Recommendation Notes for Azure](#recommendation-notes-for-azure) for more details.
- [Google AlloyDB](https://cloud.google.com/alloydb) and [Amazon RDS Multi-AZ DB cluster](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/multi-az-db-clusters-concepts.html) have not been tested and are not recommended. Both solutions are specifically not expected to work with GitLab Geo.
  - [Amazon RDS Multi-AZ DB instance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html) is a separate product and is supported.

### Recommendation notes for Azure

Due to performance issues that we found with several key Azure services, we only recommend smaller architectures (up to 2k) to be deployed to Azure. For larger architectures, we recommend using another cloud provider.

In addition to the above, you should be aware of the additional specific guidance for Azure:

- [Azure Database for PostgreSQL Single Server](https://azure.microsoft.com/en-gb/products/postgresql/#overview) is not supported for use due to notable performance / stability issues or missing functionality.
- A new service, [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/) has been released. [Internal testing](https://gitlab.com/gitlab-org/quality/reference-architectures/-/issues/91) has shown that it does look to perform as expected, but this hasn't been validated in production, so generally isn't recommended at this time. Additionally, as it's a new service, you may find that it's missing some functionality depending on your requirements.
  - Only standard Postgres authentication is supported at this time with this service. Microsoft Azure Active Directory (Azure AD) is not compatible.
- [Azure Blob Storage](https://azure.microsoft.com/en-gb/products/storage/blobs/) has been found to have [performance limits that can impact production use at certain times](https://gitlab.com/gitlab-org/gitlab/-/issues/344861). However, this has only been seen in our largest architectures (25k+) so far.

## Deviating from the suggested reference architectures

As a general guideline, the further away you move from the reference architectures,
the harder it is to get support for it. With any deviation, you're introducing
a layer of complexity that adds challenges to finding out where potential
issues might lie.

The reference architectures use the official Linux packages or [Helm Charts](https://docs.gitlab.com/charts/) to
install and configure the various components. The components are
installed on separate machines (virtualized or bare metal), with machine hardware
requirements listed in the "Configuration" column and equivalent VM standard sizes listed
in GCP/AWS/Azure columns of each [available reference architecture](#available-reference-architectures).

Running components on Docker (including Docker Compose) with the same specs should be fine, as Docker is well known in terms of support.
However, it is still an additional layer and may still add some support complexities, such as not being able to run `strace` easily in containers.

### Unsupported designs

While we endeavour to try and have a good range of support for GitLab environment designs, there are certain approaches we know definitively not to work, and as a result are not supported. Those approaches are detailed in the following sections.

#### Stateful components in Kubernetes

[Running stateful components in Kubernetes, such as Gitaly Cluster, is not supported](https://docs.gitlab.com/charts/installation/#configure-the-helm-chart-to-use-external-stateful-data).

Gitaly Cluster is only supported on conventional virtual machines. Kubernetes enforces strict memory restrictions, but Git memory usage is unpredictable, which
can cause sporadic OOM termination of Gitaly pods, leading to significant disruptions and potential data loss. For this reason and others, Gitaly is not tested
or supported in Kubernetes. For more information, see [epic 6127](https://gitlab.com/groups/gitlab-org/-/epics/6127).

This also applies to other third-party stateful components such as Postgres and Redis, but you can explore other third-party solutions for those components if desired such as supported Cloud Provider services unless called out specifically as unsupported.

#### Autoscaling of stateful nodes

As a general guidance, only _stateless_ components of GitLab can be run in Autoscaling groups, namely GitLab Rails
and Sidekiq.

Other components that have state, such as Gitaly, are not supported in this fashion (for more information, see [issue 2997](https://gitlab.com/gitlab-org/gitaly/-/issues/2997)).

This also applies to other third-party stateful components such as Postgres and Redis, but you can explore other third-party solutions for those components if desired such as supported Cloud Provider services unless called out specifically as unsupported.

#### Spreading one environment over multiple data centers

Deploying one GitLab environment over multiple data centers is not supported due to potential split brain edge cases
if a data center were to go down. For example, several components of the GitLab setup, namely Consul, Redis Sentinel and Praefect require an odd number quorum to function correctly and splitting over multiple data centers can impact this notably.

For deploying GitLab over multiple data centers or regions we offer [GitLab Geo](https://about.gitlab.com/solutions/geo/) as a comprehensive solution.

## Validation and test results

The [Quality Engineering team](https://about.gitlab.com/handbook/engineering/quality/quality-engineering/)
does regular smoke and performance tests for the reference architectures to ensure they
remain compliant.

### Why we perform the tests

The Quality Department has a focus on measuring and improving the performance
of GitLab, as well as creating and validating reference architectures that
self-managed customers can rely on as performant configurations.

For more information, see our [handbook page](https://about.gitlab.com/handbook/engineering/quality/performance-and-scalability/).

### How we perform the tests

Testing occurs against all reference architectures and cloud providers in an automated and ad-hoc fashion. This is done by two tools:

- The [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) Terraform and Ansible scripts for building the environments.
- The [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) for performance testing.

Network latency on the test environments between components on all Cloud Providers were measured at <5 ms. This is shared as an observation and not as an implicit recommendation.

We aim to have a "test smart" approach where architectures tested have a good range that can also apply to others. Testing focuses on a 10k Linux package
installation on GCP as the testing has shown this is a good bellwether for the other architectures and cloud providers as well as Cloud Native Hybrids.

The Standard Reference Architectures are designed to be platform-agnostic, with everything being run on VMs through [the Linux package](https://docs.gitlab.com/omnibus/). While testing occurs primarily on GCP, ad-hoc testing has shown that they perform similarly on hardware with equivalent specs on other Cloud Providers or if run on premises (bare-metal).

Testing on these reference architectures is performed with the
[GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance)
at specific coded workloads, and the throughputs used for testing are
calculated based on sample customer data. Select the
[reference architecture](#available-reference-architectures) that matches your scale.

Each endpoint type is tested with the following number of requests per second (RPS)
per 1,000 users:

- API: 20 RPS
- Web: 2 RPS
- Git (Pull): 2 RPS
- Git (Push): 0.4 RPS (rounded to the nearest integer)

### How to interpret the results

NOTE:
Read our blog post on [how our QA team leverages GitLab performance testing tool](https://about.gitlab.com/blog/2020/02/18/how-were-building-up-performance-testing-of-gitlab/).

Testing is done publicly, and all results are shared.

The following table details the testing done against the reference architectures along with the frequency and results. Additional testing is continuously evaluated, and the table is updated accordingly.

<style>
table.test-coverage td {
    border-top: 1px solid #dbdbdb;
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.test-coverage th {
    border-top: 1px solid #dbdbdb;
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}
</style>

<table class="test-coverage">
  <col>
  <colgroup span="2"></colgroup>
  <colgroup span="2"></colgroup>
  <tr>
    <th rowspan="2">Reference<br/>Architecture</th>
    <th style="text-align: center" colspan="2" scope="colgroup">GCP (* also proxy for Bare-Metal)</th>
    <th style="text-align: center" colspan="2" scope="colgroup">AWS</th>
    <th style="text-align: center" colspan="2" scope="colgroup">Azure</th>
  </tr>
  <tr>
    <th scope="col">Linux package</th>
    <th scope="col">Cloud Native Hybrid</th>
    <th scope="col">Linux package</th>
    <th scope="col">Cloud Native Hybrid</th>
    <th scope="col">Linux package</th>
  </tr>
    <tr>
    <th scope="row">1k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/1k">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
  </tr>
  <tr>
    <th scope="row">2k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/2k">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td><i>Planned</i></td>
  </tr>
  <tr>
    <th scope="row">3k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/3k">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/3k_hybrid_aws_services">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
  </tr>
  <tr>
    <th scope="row">5k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/5k">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
  </tr>
  <tr>
    <th scope="row">10k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/10k">Daily</a></td>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/10k_hybrid">Weekly</a></td>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/10k_aws">Weekly</a></td>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/10k_hybrid_aws_services">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
  </tr>
  <tr>
    <th scope="row">25k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/25k">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
  </tr>
  <tr>
    <th scope="row">50k</th>
    <td><a href="https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/50k">Weekly</a></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
    <td style="background-color:lightgrey"></td>
  </tr>
</table>

## Cost to run

As a starting point, the following table details initial costs for the different reference architectures across GCP, AWS, and Azure through the Linux package.

NOTE:
Due to the nature of Cloud Native Hybrid, it's not possible to give a static cost calculation.
Bare-metal costs are also not included here as it varies widely depending on each configuration.

<table class="test-coverage">
  <col>
  <colgroup span="2"></colgroup>
  <colgroup span="2"></colgroup>
  <tr>
    <th rowspan="2">Reference<br/>Architecture</th>
    <th style="text-align: center" scope="colgroup">GCP</th>
    <th style="text-align: center" scope="colgroup">AWS</th>
    <th style="text-align: center" scope="colgroup">Azure</th>
  </tr>
  <tr>
    <th scope="col">Linux package</th>
    <th scope="col">Linux package</th>
    <th scope="col">Linux package</th>
  </tr>
    <tr>
    <th scope="row">1k</th>
    <td><a href="https://cloud.google.com/products/calculator#id=a6d6a94a-c7dc-4c22-85c4-7c5747f272ed">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=b51f178f4403b69a63f6eb33ea425f82de3bf249">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=1adf30bef7e34ceba9efa97c4470417b">Calculated cost</a></td>
  </tr>
  <tr>
    <th scope="row">2k</th>
    <td><a href="https://cloud.google.com/products/calculator#id=0d3aff1f-ea3d-43f9-aa59-df49d27c35ca">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=3b3e3b81953737132789591d3a5179521943f1c0">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=25f66c35ba454bb98fb4034a8a50bb8c">Calculated cost</a></td>
  </tr>
  <tr>
    <th scope="row">3k</th>
    <td><a href="https://cloud.google.com/products/calculator/#id=15fc2bd9-5b1c-479d-bc46-d5ce096b8107">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=7e94eb8712f6845fdeb05e61f459598a91dac3cb">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=24ac11fd947a4985ae9c9a5142649ad3">Calculated cost</a></td>
  </tr>
  <tr>
    <th scope="row">5k</th>
    <td><a href="https://cloud.google.com/products/calculator/#id=9a798136-53f2-4c35-be43-8e1e975a6663">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=ad4c9db623a214c92d780cd9dff33f444d62cf02">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=bcf23017ddfd40649fdc885cacd08d0c">Calculated cost</a></td>
  </tr>
  <tr>
    <th scope="row">10k</th>
    <td><a href="https://cloud.google.com/products/calculator#id=cbe61840-31a1-487f-88fa-631251c2fde5">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=3e2970f919915a6337acea76a9f07655a1ecda4a">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=5748068be4864af6a34efb1cde685fa1">Calculated cost</a></td>
  </tr>
  <tr>
    <th scope="row">25k</th>
    <td><a href="https://cloud.google.com/products/calculator#id=b4b8b587-508a-4433-adc8-dc506bbe924f">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=32acaeaa93366110cd5fbf98a66a8a141db7adcb">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=24f878f20ee64b5cb64de459d34c8128">Calculate cost</a></td>
  </tr>
  <tr>
    <th scope="row">50k</th>
    <td><a href="https://cloud.google.com/products/calculator/#id=48b4d817-d6cd-44b8-b069-0ba9a5d123ea">Calculated cost</a></td>
    <td><a href="https://calculator.aws/#/estimate?id=5a0bba1338e3577d627ec97833dbc80ac9615562">Calculated cost</a></td>
    <td><a href="https://azure.microsoft.com/en-us/pricing/calculator/?shared-estimate=4dd065eea2194d70b44d6d897e81f460">Calculated cost</a></td>
  </tr>
</table>

## Maintaining a Reference Architecture environment

Maintaining a Reference Architecture environment is generally the same as any other GitLab environment is generally covered in other sections of this documentation.

In this section you'll find links to documentation for relevant areas as well as any specific Reference Architecture notes.

### Upgrades

Upgrades for a Reference Architecture environment is the same as any other GitLab environment.
The main [Upgrade GitLab](../../update/index.md) section has detailed steps on how to approach this.

[Zero-downtime upgrades](#zero-downtime-upgrades) are also available.

NOTE:
You should upgrade a Reference Architecture in the same order as you created it.

### Scaling an environment

Scaling a GitLab environment is designed to be as flexible and seamless as possible.

This can be done iteratively or wholesale to the next size of architecture depending on your circumstances.
For example, if any of your GitLab Rails, Sidekiq, Gitaly, Redis or PostgreSQL nodes are consistently oversaturated, then increase their resources accordingly while leaving the rest of the environment as is.

If expecting a large increase in users, you may elect to scale up the whole environment to the next
size of architecture.

If the overall design is being followed, you can scale the environment vertically as required.

If robust metrics are in place that show the environment is over-provisioned, you can apply the same process for
scaling downwards. You should take an iterative approach when scaling downwards to ensure there are no issues.

#### Scaling from a non-HA to an HA architecture

While in most cases vertical scaling is only required to increase an environment's resources, if you are moving to an HA environment,
there may be some additional steps required as shown below:

- If you're scaling from a non-HA environment to an HA environment, various components are recommended to be deployed in their HA forms:
  - [Redis to multi-node Redis w/ Redis Sentinel](../redis/replication_and_failover.md#switching-from-an-existing-single-machine-installation)
  - [Postgres to multi-node Postgres w/ Consul + PgBouncer](../postgresql/moving.md)
  - [Gitaly to Gitaly Cluster w/ Praefect](../gitaly/index.md#migrate-to-gitaly-cluster)
- From 10k users and higher, Redis is recommended to be split into multiple HA servers as it's single threaded.

Conversely, if you have robust metrics in place that show the environment is over-provisioned, you can apply the same process for
scaling downwards. You should take an iterative approach when scaling downwards, however, to ensure there are no issues.

### Monitoring

There are numerous options available to monitor your infrastructure, as well as [GitLab itself](../monitoring/index.md), and you should refer to your selected monitoring solution's documentation for more information.

Of note, the GitLab application is bundled with [Prometheus as well as various Prometheus compatible exporters](../monitoring/prometheus/index.md) that could be hooked into your solution.

## Update history

Below is a history of notable updates for the Reference Architectures (2021-01-01 onward, ascending order), which we aim to keep updated at least once per quarter.

You can find a full history of changes [on the GitLab project](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&label_name%5B%5D=Reference%20Architecture&label_name%5B%5D=documentation).

**2023:**

- [2023-12-12](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133457): Updated notes on Load Balancers to be more reflective that any reputable offering is expected to work.
- [2023-11-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133457): Expanded details on what each Reference Architecture is designed for, the testing methodology used as well as added details on how to scale environments.
- [2023-11-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134518): Added expanded notes on disk types, object storage and monitoring.
- [2023-10-25](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134518): Adjusted Sidekiq configuration example to use Linux Package role.
- [2023-10-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133835): Adjusted the Sidekiq recommendations to include a separate node for 2k and tweaks to instance type and counts for 3k and 5k.
- [2023-10-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132270): Added more expanded notes throughout to warn about the use of Large Monorepos and their impacts for increased awareness.
- [2023-10-04](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133258): Updated name of Task Runner pod to its new name of Toolbox.
- [2023-10-02](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132961): Expanded guidance on using an external service for Redis further, in particular for separated Cache and Persistent services with 10k and up.
- [2023-09-21](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132289): Expanded details on the challenges of running Gitaly in Kubernetes.
- [2023-09-20](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132275): Removed references to Grafana after deprecation and removal.
- [2023-08-30](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130470): Expanded section on Geo under the Decision Tree.
- [2023-08-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128529): Switch config example to use the Sidekiq role for Linux package.
- [2023-08-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128374): Fixed an AWS Machine type typo for the 50k architecture.
- [2023-11-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133457): Expand details on what each Reference Architecture is designed for, the testing methodology used as well as added details on how to scale environments.
- [2023-11-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134518): Add expanded notes on disk types, object storage and monitoring.
- [2023-10-25](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134518): Adjust Sidekiq configuration example to use Linux Package role.
- [2023-10-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133835): Adjust the Sidekiq recommendations to include a separate node for 2k and tweaks to instance type and counts for 3k and 5k.
- [2023-10-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132270): Add more expanded notes throughout to warn about the use of Large Monorepos and their impacts for increased awareness.
- [2023-10-04](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133258): Update name of Task Runner pod to its new name of Toolbox.
- [2023-10-02](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132961): Expand guidance on using an external service for Redis further, in particular for separated Cache and Persistent services with 10k and up.
- [2023-09-21](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132289): Expand details on the challenges of running Gitaly in Kubernetes.
- [2023-09-20](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132275): Remove references to Grafana after deprecation and removal.
- [2023-08-30](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130470): Expand section on Geo under the Decision Tree.
- [2023-08-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128529): Switch configuration example to use the Sidekiq role for Linux package.
- [2023-08-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128374): Fix an AWS Machine type typo for the 50k architecture.
- [2023-06-30](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125017): Update PostgreSQL configuration examples to remove a now unneeded setting to instead use the Linux package default.
- [2023-06-30](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125017): Add explicit example on main page that reflects Google Memorystore is recommended.
- [2023-06-11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122063): Fix IP examples for the 3k and 5k architectures.
- [2023-05-25](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121545): Expand notes on usage of external Cloud Provider Services and the recommendation of separated Redis servers for 10k environments and up.
- [2023-05-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119224): Update documentation to reflect correct requirement of Redis 6 instead of 5.
- [2023-04-28](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114877): Add a note that the Azure Active Directory authentication method is not supported for use with Azure PostgreSQL Flexible service.
- [2023-03-23](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114877): Add more details about known unsupported designs.
- [2023-03-16](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114872): Update Redis configuration examples for multi-node to have correct config to ensure all components can connect.
- [2023-03-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110784): Update Gitaly configuration examples to the new format.
- [2023-03-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114495): Update cost estimates to no longer include NFS VMs.
- [2023-02-17](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110379): Update Praefect configuration examples to the new format.
- [2023-02-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109798): Add examples of what automations may be considered additional workloads.
- [2023-02-13](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111018): Add a new 'Before you Start' section that gives more context about what's involved with running production software self-managed. Also added more details for Standalone setups and Cloud Provider services in the Decision Tree section.
- [2023-02-01](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110641): Switch to use more common "complex" terminology instead of less known "involved".
- [2023-01-31](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110328): Expand and centralize the requirements' section on the main page.
- [2023-01-26](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110183): Add notes on migrating Git Data from NFS, that object data is still supported on NFS and handling SSH keys correctly across multiple Rails nodes.

**2022:**

- [2022-12-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105451): Remove guidance for using NFS for Git data as support for this is now ended with `15.6` onwards.
- [2022-12-12](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106826): Add note to clarify difference between Amazon RDS Multi-AZ DB _cluster_ and _instance_, with the latter being supported. Also increase PostgreSQL max connections setting to new default of `500`.
- [2022-12-12](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106695): Update Sidekiq max concurrency configuration to match new default of `20`.
- [2022-11-16](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104236): Correct guidance for Praefect and Gitaly in reduced 3k architecture section that an odd number quorum is required.
- [2022-11-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103623): Add guidance on how to handle GitLab Secrets in Cloud Native Hybrids and further links to the GitLab Charts documentation.
- [2022-11-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103767): Fix a typo with Sidekiq configuration for the 10k architecture.
- [2022-11-09](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102746): Add guidance on large monorepos and additional workloads impact on performance. Also expanded Load Balancer guidance around SSL and a recommendation for least connection based routing methods.
- [2022-10-18](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100826): Adjust Object Storage guidance to make it clearer it's recommended over NFS.
- [2022-10-11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100305): Update guidance for Azure to recommend up to 2k only due to performance issues.
- [2022-09-27](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98204): Add Decision Tree section to help users better decide what architecture to use.
- [2022-09-22](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98263): Add explicit step to enable Incremental Logging when only Object Storage is being used.
- [2022-09-22](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98184): Expand guidance on recommended cloud providers and services.
- [2022-09-09](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97245): Expand Object Storage guidance and updated that NFS support for Git data ends with `15.6`.
- [2022-08-24](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96150): Add clearer note that Gitaly Cluster is not supported in Kubernetes.
- [2022-08-24](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96021): Add section on supported CPUs and types.
- [2022-08-18](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95713): Update architecture tables to be clearer for Object Storage support.
- [2022-08-17](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95185): Increase Cloud Native Hybrid pool specs for 2k architecture to ensure enough resources present for pods. Also increased Sidekiq worker count.
- [2022-08-02](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93493): Add note to use newer Gitaly check command from GitLab 15 and later.
- [2022-07-25](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93141): Move troubleshooting section to a more general location.
- [2022-07-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92144): Add guidance that Amazon Aurora is no longer compatible and not supported from GitLab 14.4.0 and later.
- [2022-07-07](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91943): Add call out not to remove the `default` section from Gitaly storages config as it's required.
- [2022-06-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86812): Move Incremental Logging guidance to separate section.
- [2022-04-29](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85856): Expand testing results' section with new regular pipelines.
- [2022-04-26](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85833): Update Praefect configuration to reflect setting name changes.
- [2022-04-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85231): Add missing setting to enable Object Storage correctly.
- [2022-04-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85107): Expand Cloud Native Hybrid guidance with AWS machine types.
- [2022-04-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84389): Add cost estimates for AWS and Azure.
- [2022-04-06](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84483): Update configuration examples for most components to be correctly included for Prometheus monitoring auto discovery.
- [2022-03-30](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81538): Expand validation and testing result's section with more clearly language and more detail.
- [2022-03-21](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83019): Add note that additional specs may be needed for Gitaly in some scenarios.
- [2022-03-04](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82087): Add guidance for preventing the GitLab KAS service running on nodes where not required.
- [2022-03-01](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81814): Fix a typo for Praefect TLS port in configuration examples.
- [2022-02-22](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81247): Add guidance to enable the Gitaly Pack-objects cache.
- [2022-02-22](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80892): Add a general section on recommended Cloud Providers and services.
- [2022-02-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80521): Link to blog post about GPT testing added.
- [2022-01-26](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78705): Merge testing process and cost estimates into one section with expanded details.
- [2022-01-13](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77968): Expand guidance on recommended Kubernetes platforms.

**2021:**

- [2021-12-31](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77437): Fix typo for 25k Redis AWS machine size.
- [2021-12-28](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77243): Add Cloud Provider breakdowns to testing process & results section.
- [2021-12-17](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77039): Add more detail to testing process and results section.
- [2021-12-17](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77002): Add note on Database Load Balancing requirements when using a modified 3k architecture.
- [2021-12-17](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76236): Add diagram for 1k architecture (single node).
- [2021-12-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76748): Add sections on estimated costs (GCP), testing process and results and further Cloud Provider service details.
- [2021-12-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76226): Expand external database service guidance for components and what Cloud Provider services are recommended.
- [2021-11-24](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74612): Add recommendations for Database Load Balancing.
- [2021-11-04](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73634): Add more detail about testing targets used for the architectures.
- [2021-10-13](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72052): Add guidance around optionally enabling Incremental Logging via Redis.
- [2021-10-07](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71784): Update Sidekiq config to include required `external_url` setting.
- [2021-10-02](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71576): Expand guidance around Gitaly Cluster and Gitaly Sharded.
- [2021-09-29](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70625): Add note on what Cloud Native Hybrid architecture to use with small user counts.
- [2021-09-27](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70602): Change guidance to now co-locate Redis Sentinel beside Redis on the same node.
- [2021-08-18](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67778): Add 2k Cloud Native Hybrid architecture.
- [2021-08-04](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67463): Add links to performance test results for each architecture.
- [2021-07-30](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67231): Fix the replication settings in PostgreSQL configuration examples to have correct values.
- [2021-07-22](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66185): Add 3k Cloud Native Hybrid architecture.
- [2021-07-16](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66278): Update architecture diagrams to correctly reflect no direct connection between Rails and Sidekiq.
- [2021-07-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65373): Update Patroni configuration to include Rest API authentication settings.
- [2021-07-15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65992): Add 5k Cloud Native Hybrid architecture.
- [2021-07-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65154): Add 25k Cloud Native Hybrid architecture.
- [2021-06-29](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64711): Add 50k Cloud Native Hybrid architecture.
- [2021-06-23](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64612): Make additions to main page for Cloud Native Hybrid and reduce 3k architecture.
- [2021-06-16](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63580): Update PostgreSQL steps and configuration to use the latest roles and prep for any Geo replication.
- [2021-06-14](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63857): Update configuration examples for Monitoring node to follow latest.
- [2021-06-11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62316): Expand notes on external services with more detail.
- [2021-06-09](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63504): Add additional guidance and expand on how to correctly manage GitLab secrets and database migrations.
- [2021-06-09](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63443): Update Praefect configuration examples to follow the new storages format.
- [2021-06-03](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61923): Removed references for the Unicorn webserver, which has been replaced by Puma.
- [2021-04-23](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59471): Update Sidekiq configuration examples to show how to correctly configure multiple workers on each node.
- [2021-04-23](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59283): Add initial guidance on how to modify the 3k Reference Architecture for lower user counts.
- [2021-04-13](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59259): Add further clarification on using external services (PostgreSQL, Redis).
- [2021-04-12](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59139): Add additional guidance on using Load Balancers and their routing methods.
- [2021-04-08](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58885): Add additional guidance on how to correctly configure only one node to do database migrations for Praefect.
- [2021-04-06](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57476): Expand 10k Cloud Native Hybrid documentation with more details and clear naming.
- [2021-03-04](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54454): Expand Gitaly Cluster documentation to all other applicable Reference Architecture sizes.
- [2021-02-19](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54244): Add additional Object Storage guidance of using separated buckets for different data types as per recommendations.
- [2021-02-12](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50852): Add documentation for setting up Object Storage with Rails and Sidekiq.
- [2021-02-12](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51928): Add documentation for setting up Gitaly Cluster for the 10k Reference Architecture.
- [2021-02-09](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52249): Add the first iteration of the 10k Cloud Native Hybrid reference architecture.
- [2021-01-07](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50573): Add documentation for using Patroni as PostgreSQL replication manager.
