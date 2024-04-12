---
stage: core platform
group: Tenant Scale
description: 'Cells: Infrastructure'
authors: [ "@skarbek" ]
coach: "@andrewn"
status:
---

<!-- vale gitlab.FutureTense = NO -->

# Cells Difference with Dedicated

## Existing Reads

1. [Cell Iteration](../index.md#cells-iterations), specifically Cell 1.0
1. [GitLab Dedicated](https://about.gitlab.com/dedicated/)
1. [GitLab Dedicated technical documentation](https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/)

## GitLab Dedicated Diff

GitLab Dedicated had a chance to start from a blank slate and only run stable services.
GitLab.com is running beta features or auxiliary that GitLab Dedicated doesn't have too.

### Advanced Search

**What is GitLab Dedicated Doing:**

Dedicated relies on the GET tooling to provision AWS OpenSearch for tenants.
The application is automatically configured by GET to configure the application to leverage this feature.

**What is GitLab.com doing right now:**

GitLab.com leverages two items, one is under heavy development by `group::Global Search`.
We have an Elasticsearch cluster which provides application level search capabilities for the vast majority of our customer base.
This is currently used for code search as well as searching anything else capable of being searched inside of the GitLab application.
The Global Search team are testing the use of Zoekt as an addition to eventually replace code search capabilities.

**What will GitLab.com Cells do:**

[Accompanying issue in Dedicated](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4111)

### Capacity Planning

**What is GitLab Dedicated Doing:**

[Tamland](https://gitlab-com.gitlab.io/gl-infra/tamland/) is used.

**What is GitLab.com doing right now:**

[Tamland](https://gitlab-com.gitlab.io/gl-infra/tamland/) is used.

**What will GitLab.com Cells do:**

[Tamland](https://gitlab-com.gitlab.io/gl-infra/tamland/) will be leveraged the same.
The [work for Dedicated](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1118) is complete.
Minor work may need to be accomplished to enable for Cells

### Redis

**What is GitLab Dedicated Doing:**

Dedicated leverages [GCP Memorystore](https://cloud.google.com/memorystore) product for Redis.
_This work is a work in progress, but is supported by the GitLab Environment Toolkit._

**What is GitLab.com doing right now:**

At the .com scale, we have approximately 13 deployments of Redis all with targeted configurations pending their responsibility and role.
These Redis deployments also differ between standard Redis deployments with replicas and Redis Clusters.
We have a mix and match based on prioritized work that resolved various pain points as we scaled this service to suite our needs.

**What will GitLab.com Cells do:**

As Cells are a far smaller installation of GitLab, there should be no need to expand our Redis infrastructure as vast as we have for .com.
The chosen reference architecture should deploy a sufficiently sized Redis deployment to suit our needs.
Observability into the behavior of Redis when our first set of Cells receive customer traffic will need to be monitored closely to determine what areas of improvement we need to bring in.

### Secret Management

**What is GitLab Dedicated Doing:**

Dedicated leverages Google Secret Manager for Secret Management.
Two types of secrets are leveraged in Dedicated, secrets which are unique per tenant and secrets which are shared per environment.
The latter being used strictly for management of tenants, such as with Amp.
Thus each GitLab installation has their own set of secrets and some configuration items are stored using that cloud providers secrets service.
Instrumentor, the Dedicated tenant provisioning tool is aware of and shares only the necessary secrets between various stages.

**What is GitLab.com doing right now:**

.com leverages KMS already for simplistic items for as well as a wrapper for secrets management for Chef runs on Virtual Machines.
Most secrets are pushed into HashiCorp Vault and various chunks of our infrastructure use this service for items that are shared between Virtual Machines and our Kubernetes installations.

**What will GitLab.com Cells do:**

The provisioning secrets and shared infrastructure secrets will be managed in Hashicorp Vault, both to be used strictly for management of tenants (Amp, CI, ...).
Each cell will have their own set of unique secrets which will be managed in Google Secret Manager.
The Kubernetes secrets will be synced from Google Secret Manager by the [External Secrets operator](https://external-secrets.io/).

[Being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25076).

### HAProxy

**What is GitLab Dedicated Doing:**

HAProxy is not used.
Instead we rely on the ingresses that are deployed as part of the GitLab Helm Chart which leverages the cloud load balancer to direct traffic to the appropriate underlying resources.
Each tenant has their own installation, thus a segregated endpoint for which customer traffic is routed too.

The deployments to handle frontend workloads are handled by a single service, known as `webservice` which is managed and deployed with our Helm Chart.

Further below, we mention the introduction of CloudFlare in the future, where this will eventually provide various WAF capabilities without the need for HAProxy.

**What is GitLab.com doing right now:**

HAProxy sits behind CloudFlare and behind a set of Google Load Balancers.
The primary purpose is to provide traffic routing to target clusters for frontend traffic, and provides a large swath of rules for traffic management.
Some of this management are throttling or request blocking based on various criterion.
We have a few sets of HAProxy fleets that handle dedicated endpoints, such as `registry.gitlab.com`, the Pages endpoint, and CI traffic.

We leverage an advanced feature of our Helm Chart to deploy a multitude of frontend `webservice`s, these are split into groups that serve target traffic.
HAProxy is configured to divide these groupings of traffic with a myriad of rules.
These groups are known today as `api`, `git`, `internal-api`, `web` and `websockets`.

**What will GitLab.com Cells do:**

GitLab Cells introduces a new layer where requests need to be routed.
It is slated that the [routing-service](../routing-service.md) will intercept all requests to direct clients to the appropriate cluster.
This layer is above that of our current HAProxy setup.
Behind the [routing-service](../routing-service.md) we plan to leverage existing Ingress methods deployed as part of the GitLab Helm Chart.
Requests will then go directly to the Ingress configurations of our frontend.
We'll need to evaluate the various traffic rules which are configured in HAProxy to determine if they can be set inside of CloudFlare as firewall rules where necessary and able.
Ideally, HAProxy goes away in Cells Architecture.

The Helm Chart is used to deploy the frontend Pods, only a single one will be deployed, mimicking what Dedicated does today.

### Assets Routing

**What is GitLab Dedicated Doing:**

Assets are served by the frontend service, known as the `webservice`.
`webservice` Pods deployed by the GitLab Helm Chart.

**What is GitLab.com doing right now:**

Assets are deployed into a Google Cloud Storage bucket as part of the deployment procedure owned by Team Delivery. Assets are then served by a specific routing configuration that is managed by CloudFlare.
This removes our `webservice` deployment from needing to service static assets and allow those services to focus their load on processing requests.

**What will GitLab.com Cells do:**

The deployment of assets shall not change. This process will remain the same with CloudFlare.

### Cloudflare

**What is GitLab Dedicated Doing:**

CloudFlare is not involved yet.
Work is in progress to bring a WAF solution to Dedicated.

**What is GitLab.com doing right now:**

CloudFlare is our first line of defense to provide us native and custom Firewall, DNS, and traffic routing management.

**What will GitLab.com Cells do:**

Our use of CloudFlare will technically expand with the use of the [routing-service](../routing-service.md).
The .com entrypoint does not change, there should be no change to this service outside of the addition of the [routing-service](../routing-service.md).

### Container Registry

**What is GitLab Dedicated Doing:**

Dedicated leverages our Helm Chart to deploy and configure the GitLab Registry Service.
The Registry Service is backed by a storage bucket managed by the GitLab Environment Toolkit.

**What is GitLab.com doing right now:**

.com Leverages the same GitLab Helm chart to deploy and configure the Container Registry service.
The backing storage is configured by our own terraform mechanism in the [`config-mgmt`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt) repository.

Container Registry uses PostgesSQL Database for [online garbage collection](../../../../administration/packages/container_registry_metadata_database.md) where the database migrations are managed by a [Kubernetes Job](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/8a6a34b8db7a41eaff463d0353a2e876ebc41458/charts/registry/templates/migrations-job.yaml) with possibility to manually rollback.

The Container Registry also uses Redis as a caching layer.

**What will GitLab.com Cells do:**

[Being Discussed](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4130)

### Mail Delivery

**What is GitLab Dedicated Doing:**

_work in progress._  [See Issue 2481](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/2481)

- Outgoing: It is slated that we leverage the [AWS `SES` product](https://aws.amazon.com/ses/) and geared towards outgoing email.
- Incoming: [Incoming email](../../../../administration/incoming_email.md) is unsupported.

**What is GitLab.com doing right now:**

- Outgoing: Mail is handled by a third party, [Mailgun](https://www.mailgun.com/).
- Incoming: Email is handled by the GitLab application with [webhook delivery method](../../email_ingestion/index.md#webhook-delivery-method-recommended) which watches for email sitting on a configured inbox and directing this appropriately to Sidekiq workers.

**What will GitLab.com Cells do:**

Outgoing: Continue use Mailgun because we have a strong relationship with the provider, and no desire to change.
The Dedicated Provisioner can support Mailgun/Third-party outgoing mail gateways with minimal configuration change.
Incoming: [Being discussed](https://gitlab.com/gitlab-org/gitlab/-/issues/442161)

### PostgreSQL

**What is GitLab Dedicated Doing:**

A single RDS instance is deployed.

**What is GitLab.com doing right now:**

To handle the scale of some functions of our GitLab Rails codebase, the database was split into three PostgreSQL Clusters.
The `main` cluster which handles most of the data storage, the `ci` which handles all the CI related data, and finally, the `embedding` database.
We are also evaluating to [further decompose](https://gitlab.com/gitlab-org/gitlab/-/issues/427973) to another PostgreSQL cluster.

In front of each database we have a set of PgBouncer as a connection pooler.

**What will GitLab.com Cells do:**

What we'll do is being worked on in a separate [blueprint](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144238)

### Embedding Database

**What is GitLab Dedicated Doing:**

GitLab Dedicated is not using the embedding database, it's still in the experimental phase.

**What is GitLab.com doing right now:**

A PostgreSQL cluster deployed running [pgvector](https://github.com/pgvector/pgvector).
The embedding data is to vectorize GitLab content (issues, epics, merge requests) and store that data in a place where it can be used for search, recommendations, anomaly detection, classification, backlog cleanup, deduplication, and other AI adjacent things.

**What will GitLab.com Cells do:**

Embedding Database is still considered experimental we will not support this in Cells to reduce scope for Cells 1.0.

### GitLab Pages

**What is GitLab Dedicated Doing:**

Just recently released!

**What is GitLab.com doing right now:**

GitLab Pages is an active feature of .com.

**What will GitLab.com Cells do:**

We will not enable GitLab Pages for [Cells 1.0](https://gitlab.com/gitlab-org/gitlab/-/blob/cfc0b476301097580d348e054b0ba4f721d4a9df/doc/architecture/blueprints/cells/iterations/cells-1.0.md#L476-479) so it's out of scope at the moment.

### VM Configuration Management

**What is GitLab Dedicated Doing:**

Management of the VMs is all handled by GitLab Environment Toolkit.
It uses Terraform for provisioning the machines and Ansible to configure the VM.

**What is GitLab.com doing right now:**

.com leverages Chef for configuration management with integrations into Vault for secrets management and a complex role structure built into Chef for managing configurations.

**What will GitLab.com Cells do:**

Reuse the GitLab Dedicated tooling, meaning that chef will be removed.

### Disaster Recovery

**What is GitLab Dedicated Doing:**

Reference existing documentation:

- [RTO/RPO from backups](https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/engineering/restore-from-backups-rto-rpo.html)
- [Recovery Guides](https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/runbooks/regional-failure-recovery.html)

**What is GitLab.com doing right now:**

Reference existing documentation:

- [Runbooks](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/disaster-recovery)

**What will GitLab.com Cells do:**

A blueprint will be created at a [later point in time](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25118).

### Feature Flags

**What is GitLab Dedicated Doing:**

Feature Flags are not heavily leveraged and actively discouraged.
An override mechanism exists for special use-cases.
Note that this is a business decision and not a technical limitation.

**What is GitLab.com doing right now:**

We have a fairly complex [process](https://gitlab.com/gitlab-org/gitlab/-/blob/b6336d771249dbee6da5cf65fa49b85834d493e3/doc/development/feature_flags/index.md) to allow engineers to rollout out changes safely.

**What will GitLab.com Cells do:**

ChatOps will eventually be expanded upon to support Cells.
[Epic 12797](https://gitlab.com/groups/gitlab-org/-/epics/12797) has been created to provide any added functionality.
No work will occur for Iteration Cells 1.0.

### Deployment

**What is GitLab Dedicated Doing:**

All components which feed into a tenant install are versioned.
Per contract, a maintenance window is defined and agreed upon with a customer that provides an opportunity for any maintenance, whether it be a version upgrade, change to infrastructure, or configuration change to the application is performed.
The tooling leveraged by this runs through extensive testing beforehand on non-production tenants.

**What is GitLab.com doing right now:**

A dedicated team, [Delivery](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/delivery/) is responsible for a set of tooling which manages and deploys new versions of GitLab a multiple times per day.
Multiple stages, Canary and Main, are leveraged to help with risk management of deployments.

**What will GitLab.com Cells do:**

[Delivery](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/delivery/) remains responsible for initial development of this.
[The current blueprint](../application-deployment.md) that surrounds this work introduces a concept of Ring deployments to manage risk.

### Subnets

**What is GitLab Dedicated Doing:**

Dedicated uses a static list of IP CIDRs that intentionally overlap for all tenants.
Subnets are configurable in the case of a need from a customer.

**What is GitLab.com doing right now:**

A very tightly and carefully managed dance is performed to ensure documentation, terraform code, and VPC peering all work in a cohesive manner across various GCP projects, and environments.

**What will GitLab.com Cells do:**

[Being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25069)

### Kubernetes

**What is GitLab Dedicated Doing:**

Managed by the GitLab Environment Toolkit, a single Kubernetes Cluster is spun up.
Managed by the GitLab Helm Chart, an entire GitLab installation is deployed.
Instrumentor contains the tooling for the observability stack that is installed into the same cluster.

**What is GitLab.com doing right now:**

Clusters are manually configured with Terraform through the `config-mgmt` repository.
Deployments of anything to these clusters are managed through at least three repositories that deploy various tools required to manage, maintain, and observe the GitLab application workloads that are deployed.

**What will GitLab.com Cells do:**

[Being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25068)

### SRE root access to machines

**What is GitLab Dedicated Doing:**

VMs:

Managed by Ansible: A mixture of [SSH](<https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/runbooks/tenant-ssh.html>] (internal link) with the use of [Identify-Aware Proxy](https://cloud.google.com/compute/docs/connect/ssh-using-iap).
This must be used with the [Break glass procedure](https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/engineering/breaking_glass.html) (internal link).

Kubernetes:

`kubectl`: [Break glass procedure](https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/engineering/breaking_glass.html) (internal link).

**What is GitLab.com doing right now:**

VMs:

- VMs manged by Chef: Users and SSH keys are managed by Chef and require a bastion to be able to SSH inside of machines with root access.
- Rails Console: We use [Teleport](https://gitlab.com/gitlab-com/runbooks/-/blob/8197f6cdb6aa8e7230600a9e59ee4f447a8543f5/docs/teleport/Connect_to_Rails_Console_via_Teleport.md) to spin up a rails console for read-only access.
- `psql`: We use [Teleport](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/teleport/Connect_to_Database_Console_via_Teleport.md?ref_type=heads)

Kubernetes:

- `kubectl`: A bastion server where the keys are managed by Chef and then setting up [`gcloud`](https://gitlab.com/gitlab-com/runbooks/-/blob/8197f6cdb6aa8e7230600a9e59ee4f447a8543f5/docs/kube/k8s-oncall-setup.md#kubernetes-api-access)
- GKE VMs: We use [Google's OS Login](https://cloud.google.com/compute/docs/oslogin) to access the nodes.

**What will GitLab.com Cells do:**

VMs:

- Managed by Ansible: Same as GitLab Dedicated
- Rails Console: [Being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25124)
- `psql`: [Being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25124)

Kubernetes:

- `kubectl`: Same as GitLab Dedicated
- GKE VMs: Same as GitLab Dedicated

### Observability

**What is GitLab Dedicated Doing:**

An observability stack which consumes the same set of metrics we leverage for .com are bundled into Instrumentor and deployed to the observability stack installed into a tenant's Kubernetes Cluster.
This includes all the appropriate rules for alerting, paging, provides dashboards, and forecasting.
Some metrics are lacking, but are being worked on to bring full coverage where lacking.

There does not exist a global view of metrics for all tenants.

Logging is managed by way of using AWS OpenSearch for AWS tenants, and Google Cloud Logging for GCP tenants.

**What is GitLab.com doing right now:**

A large installation of the Prometheus and Thanos across a multitude of GCP projects are managed through various means.
We leverage the Runbooks repository to configure all of our Dashboards, Alerts, and Pages.

We inherently are provided a global view as our Grafana installation talks to a large Thanos configuration which is able to distribute queries across all necessary environments.

Logs are managed by way of `fluentd` on both our Virtual Machines and Kubernetes clusters sending data to PubSub which are then brought into Elasticsearch where Kibana is used for viewing.
Some services dump too much data, such as CloudFlare, GKE, and HAProxy, where we rely on Google's Logging solution, either Stackdriver, or BigQuery.

**What will GitLab.com Cells do:**

[Being discussed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143672)

### Camoproxy

**What is GitLab Dedicated Doing:**

Unused.

**What is GitLab.com doing right now:**

[go-camo](https://github.com/cactus/go-camo?tab=readme-ov-file#how-it-works) is deployed by a custom [Helm chart](https://gitlab.com/gitlab-com/gl-infra/charts/-/tree/main/gitlab/camoproxy?ref_type=heads). `go-camo` used to serve images from HTTP based resources to HTTPS.

**What will GitLab.com Cells do:**

[Being discussed](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25125)

### Certificates

**What is GitLab Dedicated Doing:**

GitLab Dedicated uses [`cert-manager`](https://cert-manager.io/), Let's Encrypt and NGINX to issue and [manage certificates](https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/team/runbooks/certmanager.html).

**What is GitLab.com doing right now:**

GitLab.com uses Cloudflare for [certificates](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/certificates/cloudflare.md) and mixture of `cert-manager` and GCP certificates for auxiliary services such as Grafana.

**What will GitLab.com Cells do:**

For the GitLab.com we will still use Cloudflare so we can continue using the certificates from Cloudflare.

### osquery

**What is GitLab Dedicated Doing:**

It doesn't install osquery.

**What is GitLab.com doing right now:**

We have a [chef cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-osquery) to manage our osquery installation.

**What will GitLab.com Cells do:**

Tooling will need to be developed that is compatible with deployment methods being leveraged to deploy to the Cell architecture.

**What will be covered by osquery:**

osquery would cover all the Virtual Machines; some of the examples today covered are bastion nodes, HA Proxy nodes, etc.

**Why we require osquery:**

1. **Visibility:** Notably, we still have very little visibility over what is happening inside our VMs and Kubernetes Clusters.
1. **Compliance Requirements:** Compliance requires us to have clear insights into actions in environments like Kubernetes or the Legacy VMs.
1. **Incidents Investigation:** Incidents reported in the past are left with few missing investigations due to a lack of detection and investigation of the commands executed before and after the malicious commands.

### Wiz Runtime Sensor

**What is GitLab Dedicated Doing:**

Wiz is not used.

**What is GitLab.com doing right now:**

Wiz Runtime Sensor is a new tool being introduced into .com. Wiz Runtime Sensor is a lightweight eBPF-based agent which is listens to syscalls and generates the findings on the suspicious actions executed by the applications/workloads. Follow Wiz Runtime [Internal Handbook Page](https://internal.gitlab.com/handbook/security/infrastructure_security/tooling/wiz-sensor/) for more details.

As of this writing, it has not been deployed into the production environment and is still being tested in our staging environment. Currently, it is deployed using the [Helm chart](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/wiz-sensor?ref_type=heads)

**What will GitLab.com Cells do:**

If this tool is to be leveraged, we will need to recreate a method of deployment suitable for Cells.
The current deployment method being leveraged will not suffice for Cellular architecture.

**What will be covered by Wiz Runtime Sensor:**

Wiz Runtime Sensor would be deployed in the Kubernetes clusters as a `DaemonSet`. `DaemonSet` would add the sensor to all the nodes; Wiz Runtime Sensor would observe the syscalls for any malicious actions like malicious script executed, sensitive files accessed/modified, and container escape attempts.

**Why we require Wiz Runtime Sensor:**

1. **Visibility:** Notably, we still have very little visibility over what is happening inside our VMs and Kubernetes Clusters.
1. **Compliance Requirements:** Compliance requires us to have clear insights into actions in environments like Kubernetes or the Legacy VMs.
1. **Incidents Investigation:** Incidents reported in the past are left with few missing investigations due to a lack of detection and investigation of the commands executed before and after the malicious commands.
