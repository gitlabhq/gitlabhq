---
stage: Tenant Scale
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Cells
---

DETAILS:
**Offering:** GitLab.com
**Status:** Experiment

NOTE:
This feature is available for administrators of GitLab.com only. This feature is not available for GitLab Self-Managed or GitLab Dedicated instances.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.

NOTE:
Cells 1.0 is in development. For more information about the state of cell development, see [epic 12383](https://gitlab.com/groups/gitlab-org/-/epics/12383).

This page explains how to configure the GitLab Rails console for cell functionality. For more information on the proposed design and terminology, see the design document for [Cells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/).

## Configuration

The cells related configuration in `config/gitlab.yml` is in this format:

```yaml
  cell:
    id: 1
    database:
      skip_sequence_alteration: false
    topology_service:
      enabled: true
      address: topology-service.gitlab.example.com:443
      ca_file: /home/git/gitlab/config/topology-service-ca.pem
      certificate_file: /home/git/gitlab/config/topology-service-cert.pem
      private_key_file: /home/git/gitlab/config/topology-service-key.pem
```

| Configuration | Default value | Description                                                                                                                               |
| ------ |---------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `cell.id` | `nil`         | Unique integer identifier for the cell in a cluster. For use when the instance is part of a cell cluster. |
| `database.skip_sequence_alteration` | `false`       | When `true`, skips database sequence alteration for the cell. Enable for the legacy cell (`cell-1`) before the monolith cell is available for use, being tracked in this epic: [Phase 6: Monolith Cell](https://gitlab.com/groups/gitlab-org/-/epics/14513). |
| `topology_service.enabled` | `false`       | When `true`, enables the topology service client to connect to the topology service, which is required to be considered a cell. |
| `topology_service.address` | `nil`         | Address and port of the topology service.                                                                                                        |
| `topology_service.ca_file` | `nil`         | Path to the CA certificate file for secure communication.                                                                                                        |
| `topology_service.certificate_file` | `nil`         | Path to the client certificate file.                                                                                                        |
| `topology_service.private_key_file` | `nil`         | Path to the private key file.                                                                                                        |

## Related configuration

For information on how to configure other components of the cells architecture, see:

1. [Topology service configuration](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/main/docs/config.md?ref_type=heads)
1. [HTTP router configuration](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/config.md?ref_type=heads)
