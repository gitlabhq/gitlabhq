---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Cells
description: Configure and test GitLab Cells functionality for GitLab.com administrators as part of functionality testing, including enabling Cell instances and configuring topology service clients.
---

{{< details >}}

- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< alert type="note" >}}

This feature is available for administrators of GitLab.com only. This feature is not available for GitLab Self-Managed or GitLab Dedicated instances.

{{< /alert >}}

{{< alert type="disclaimer" />}}

{{< alert type="note" >}}

Cells 1.0 is in development. For more information about the state of cell development, see [epic 12383](https://gitlab.com/groups/gitlab-org/-/epics/12383).

{{< /alert >}}

To test cell functionality, configure the GitLab Rails console.

## Configuration

To configure your GitLab instance as a Cell instance:

{{< tabs >}}

{{< tab title="Self-compiled (source)" >}}

The cells related configuration in `config/gitlab.yml` is in this format:

```yaml
  cell:
    enabled: true
    id: 1
    database:
      skip_sequence_alteration: false
    topology_service_client:
      address: topology-service.gitlab.example.com:443
      ca_file: /home/git/gitlab/config/topology-service-ca.pem
      certificate_file: /home/git/gitlab/config/topology-service-cert.pem
      private_key_file: /home/git/gitlab/config/topology-service-key.pem
```

{{< /tab >}}

{{< tab title="Linux Package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   gitlab_rails['cell'] = {
     enabled: true,
     id: 1,
     database: {
       skip_sequence_alteration: false
     },
     topology_service_client: {
       enabled: true,
       address: 'topology-service.gitlab.example.com:443',
       ca_file: 'path/to/your/ca/.pem',
       certificate_file: 'path/to/your/cert/.pem',
       private_key_file: 'path/to/your/key/.pem'
     }
   }
   ```

1. Reconfigure and restart GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helm chart" >}}

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       cell:
         enabled: true
         id: 1
         database:
           skipSequenceAlteration: false
         topologyServiceClient:
           address: "topology-service.gitlab.example.com:443"
           tls:
             enabled: true
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

| Configuration                                   | Default value                                         | Description                                                                                                                                                                                                                                                                                                                    |
|-------------------------------------------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cell.enabled`                                  | `false`                                               | To configure whether the instance is a Cell or not. `false` means all Cell features are disabled. `session_cookie_prefix_token` is not affected, and can be set separately.                                                                                                                                                    |
| `cell.id`                                       | `nil`                                                 | Required to be a positive integer when `cell.enabled` is `true`. Otherwise, it must be `nil`. This is the unique integer identifier for the cell in a cluster. This ID is used inside the routable tokens. When `cell.id` is `nil`, the other attributes inside the routable tokens, like `organization_id` will still be used |
| `cell.database.skip_sequence_alteration`        | `false`                                               | When `true`, skips database sequence alteration for the cell. Enable for the legacy cell (`cell-1`) before the monolith cell is available for use, being tracked in this epic: [Phase 6: Monolith Cell](https://gitlab.com/groups/gitlab-org/-/epics/14513).                                                                   |
| `cell.topology_service_client.address`          | `"topology-service.gitlab.example.com:443"`           | Required when `cell.enabled` is `true`. Address and port of the topology service server.                                                                                                                                                                                                                                       |
| `cell.topology_service_client.tls.enabled`      | `true`                                                | When `true`, enables mTLS for communication with the topology service. This requires the `cell.topology_service_client.tls.secret` to be properly configured. If set to `false`, the connection will be made without TLS encryption.                                                                                           |
| `cell.topology_service_client.tls.secret`       | `nil`                                                 | [Kubernetes TLS Secret](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/) name that contains the mTLS credentials. Required when TLS is enabled. The secret must include `tls.crt` and `tls.key` keys. If not explicitly set, defaults to `<release.name>-topology-tls`. This secret **must be created manually**; the Helm chart does not create it automatically.                |

## Related configuration

For information on how to configure other components of the cells architecture, see:

1. [Topology service configuration](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/main/docs/config.md?ref_type=heads)
1. [HTTP router configuration](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/config.md?ref_type=heads)
