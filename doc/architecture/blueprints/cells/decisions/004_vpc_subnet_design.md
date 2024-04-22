---
owning-stage: "~devops::data stores" # because Tenant Scale is under this
description: 'Cells ADR 004: One VPC per Cell, with Private Service Connect for internal communication between Cells'
---

# Cells ADR 004: One VPC per Cell, with Private Service Connect for internal communication between Cells

## Context

In [this issue](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25069) we discussed:

- Whether we should have multiple Cells in one VPC/subnet, or just a single one;
- Whether we should use [VPC Peering](https://cloud.google.com/vpc/docs/vpc-peering), [Shared VPC](https://cloud.google.com/vpc/docs/shared-vpc) or [Private Connect Service](https://cloud.google.com/vpc/docs/private-service-connect) for communication between Cells.

## Decision

It was decided that we should have a single VPC per Cell, with one subnet per region (excluding internal GKE subnets), and communication between Cells will be done through [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect) if necessary.

The motivating factor behind this decision is security and simplicity:

- The decision made in [ADR 002](002_gcp_project_boundary.md) to have one Cell per GCP project precludes the possibility of having multiple cells within the same VPC;
- Each Cell lives in its own isolated VPC without the need to set up firewall rules between them, and without IP address range conflicts;
- Each Cell exposes only the services that needs to be reachable from other Cells, again without IP address conflicts.

## Consequences

Having a single VPC per Cell will make provisioning and management of a Cell easier as there will be no need to worry about IP address space overlap issues, as well as make Cells secure by default as they will be fully isolated.

Private Service Connect will incur an [additional cost](https://cloud.google.com/vpc/pricing#internal-https-lb) because of Internal Application Load Balancer, which might or might not be significant depending on how much traffic there will be between Cells.

## Alternatives

VPC peering is [limited to 50 peerings per VPC by default](https://cloud.google.com/vpc/docs/quota#vpc-peering), and shared VPC is [limited to 100 host projects](https://cloud.google.com/vpc/docs/quota#shared-vpc), both of which limit how far Cells can scale as a result. They would also necessitate a unique IP address range per Cell to avoid overlaps, as well as additional security measures (eg. firewall rules) to isolate the different subnets between themselves.
