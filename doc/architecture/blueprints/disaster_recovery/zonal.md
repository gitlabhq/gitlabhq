---
status: ongoing
creation-date: "2024-01-29"
authors: [ "@jarv" ]
coach:
approvers: [  ]
---

# Zonal Recovery

## Improving the Recovery Time Objective (RTO) and Recovery Point Objective (RPO) for Zonal Recovery

The following represents our current DR challenges and are candidates for problems that we should address in this architecture blueprint.

1. Postgres replicas run close to capacity and are scaled manually. New instances must go through Terraform CI pipelines and Chef configuration. Over-provisioning to absorb a zone failure would add significant cloud-spend (see proposal section at the end of the document for details).
1. HAProxy (load balancing) is scaled manually and must go through Terraform CI pipelines and Chef configuration.
1. CI runner managers are present in 2 availability zones and scaled close to capacity. New instances must go through Terraform CI pipelines and Chef configuration.
1. In a zone there are saturation limits, like the number of replicas that need to be manually adjusted if load is shifted away from a failed availability zone.
1. Gitaly `RPO` is limited by the frequency of disk snapshots, `RTO` is limited by the time it takes to provision and configure through Terraform CI pipelines and Chef configuration.
1. Monitoring infrastructure that collects metrics from Chef managed VMs is redundant across 2 availability zones and scaled manually. New instances must go through Terraform CI pipelines and Chef configuration.
1. The Chef server which is responsible for all configuration of Chef managed VMs is a single point of failure located in `us-central1`. It has a local Postgres database and files on local disk.
1. The infrastructure (`dev.gitlab.org`) that builds Docker images and packages is located in a single region, and is a single point of failure.

## Zonal recovery work-streams

Improvements around zonal recovery revolve around improving the time it takes to provision for fleets that do not automatically scale.
There is already work in-progress to completely eliminate statically allocated VMs like HAProxy.
Additionally efforts can be made to shorten launch and configuration times for fleets that are not able to automatically scale like Gitaly, PostgreSQL and Redis.

### Over-provision to absorb a single zone failure

- Dependencies: None
- Teams: Ops, Scalability:Practices, Database Reliability

All of our Chef managed VM fleets run close to capacity and require manual scaling and provisioning using Terraform/Chef.
In the case of a zonal outage, it is necessary to provision more servers through Terraform which adds to our recovery time objective.
One way to avoid this is to over-provision so we have a full zone's worth of extra capacity.

1. Patroni Main (`n2-highmem-128` 6.5k/month): 3 additional nodes for +20k/month
1. Patroni CI (`n2-highmem-96` 5k/month): 3 additional nodes for +15k/month
1. HAProxy (`t2d-standard-8` 285/month): 20 additional nodes for +5k/month
1. CI Runner managers (`c2-standard-30` 1.3k/month) 60 additional nodes for +78k/month

The Kubernetes horizontal auto-scaler (`HPA`) has a maximum number of pods configured on front-end services.
It is configured to protect downstream dependencies like the database from saturation due to scaling events.
If we allow a zone to scale up rapidly, these limits need to be adjusted or re-evaluated in the context of disaster recovery.

### Remove HAProxy as a load balancing layer

- Dependencies: None
- Teams: Foundations

HAProxy is a fleet of Chef managed VMs that are statically allocated across 3 AZs in `us-east1`.
In the case of a zonal outage we would need to rapidly scale this fleet, adding to our RTO.

In FY24Q4 the Foundations team started working on a proof-of-concept to use [Istio in non-prod environments](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1157).
We anticipate in FY25 to have a replacement for HAProxy using Istio and [GKE Gateway](https://cloud.google.com/kubernetes-engine/docs/concepts/gateway-api).
Completing this work reduces the impact to our LoadBalancing layer for zonal outages, as it eliminates the need to manually scale the HAProxy fleet.
Additionally, we spend around 17k/month on HAProxy nodes, so there may be a cloud-spend reduction if we are able to reduce this footprint.

### Create an HA Chef server configuration to avoid an outage for a single zone failure

- Dependencies: None
- Teams: Ops

Chef is responsible for configuring VMs that have workloads outside of Kubernetes.
It is a single point of failure that resides in `us-central1-b`.
Data is persisted locally on disk, and we have not yet investigated moving it to a highly available setup.
In the case of a zonal outage of `us-central1-b` the server would need to be rebuilt from snapshot, losing up to 4 hours of data.

### Create an HA Packaging server (`dev.gitlab.org`) configuration to avoid an outage for a single zone failure

- Dependencies: None
- Teams: Ops

In the case of a zonal outage of `us-east1-c` the server would need to be rebuilt from snapshot, losing up to 4 hours of data.
The additional challenge of this host is that it is a GitLab-CE instance so we would be limited in features.
The best approach here would likely be to move packaging CI pipelines to `ops.gitlab.net`.

### Improve Chef provisioning time by using preconfigured golden OS images

- Dependencies: None
- Teams: Ops

For the [Gitaly fleet upgrade in 2022](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/601) a scheduled CI pipeline was created to build a golden OS images.
We can revive this work and start generating images for Gitaly and other VMs to shorten configuration time.
We estimate that using an image can reduce our recovery time by about 15 minutes to improve RTO for zonal failures.

### Eliminate X% Chef dependencies in Infra by moving infra away from Chef

- Dependencies: None
- Teams: Ops, Scalability:Observability, Scalability:Practices

Gitaly, Postgres, CI runner managers, HAProxy, Bastion, CustomersDot, Deploy, DB Lab, Prometheus, Redis, SD Exporter, and Console servers are managed by Chef.
To help improve the speed of recoveries, we can move this infrastructure into Kubernetes or Ansible for configuration management.

### Write-ahead-log for Gitaly snapshot restores

- Dependencies: None
- Teams: Gitaly

There is [work planned in FY25Q1](https://gitlab.com/gitlab-com/gitlab-OKRs/-/work_items/5710) that adds a transaction log for Gitaly to reduce RPO.
