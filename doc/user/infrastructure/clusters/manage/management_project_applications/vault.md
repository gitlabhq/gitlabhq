---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install Vault with a cluster management project
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[HashiCorp Vault](https://www.vaultproject.io/) is a secrets management solution which
can be used to safely manage and store passwords, credentials, certificates, and more. A Vault
installation could be leveraged to provide a single secure data store for credentials
used in your applications, GitLab CI/CD jobs, and more. It could also serve as a way of
providing SSL/TLS certificates to systems and deployments in your infrastructure. Leveraging
Vault as a single source for all these credentials allows greater security by having
a single source of access, control, and auditability around all your sensitive
credentials and certificates. This feature requires giving GitLab the highest level of access and
control. Therefore, if GitLab is compromised, the security of this Vault instance is as well. To
avoid this security risk, GitLab recommends using your own HashiCorp Vault to leverage
[external secrets with CI](../../../../../ci/secrets/_index.md).

Assuming you already have a project created from a
[management project template](../../../../clusters/management_project_template.md), to install Vault you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/vault/helmfile.yaml
```

By default you receive a basic Vault setup with no scalable storage backend. This
is enough for simple testing and small-scale deployments, though has limits
to how much it can scale, and as it's a single instance deployment, upgrading the
Vault application causes downtime.

To optimally use Vault in a production environment, it's ideal to have a good understanding
of the internals of Vault and how to configure it. This can be done by reading
the [Vault Configuration guide](../../../../../ci/secrets/_index.md#configure-your-vault-server),
the [Vault documentation](https://developer.hashicorp.com/vault/docs/internals) and
the Vault Helm chart [`values.yaml` file](https://github.com/hashicorp/vault-helm/blob/v0.3.3/values.yaml).

At a minimum, most users set up:

- A [seal](https://developer.hashicorp.com/vault/docs/configuration/seal) for extra encryption
  of the main key.
- A [storage backend](https://developer.hashicorp.com/vault/docs/configuration/storage) that's
  suitable for environment and storage security requirements.
- [HA Mode](https://developer.hashicorp.com/vault/docs/concepts/ha).
- The [Vault UI](https://developer.hashicorp.com/vault/docs/configuration/ui).

The following is an example values file (`applications/vault/values.yaml`)
that configures Google Key Management Service for auto-unseal, using a Google Cloud Storage backend, enabling
the Vault UI, and enabling HA with 3 pod replicas. The `storage` and `seal` stanzas
below are examples and should be replaced with settings specific to your environment.

```yaml
# Enable the Vault WebUI
ui:
  enabled: true
server:
  # Disable the built in data storage volume as it's not safe for High Availability mode
  dataStorage:
    enabled: false
  # Enable High Availability Mode
  ha:
    enabled: true
    # Configure Vault to listen on port 8200 for normal traffic and port 8201 for inter-cluster traffic
    config: |
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      # Configure Vault to store its data in a GCS Bucket backend
      storage "gcs" {
        path = "gcs://my-vault-storage/vault-bucket"
        ha_enabled = "true"
      }
      # Configure Vault to unseal storage using a GKMS key
      seal "gcpckms" {
         project     = "vault-helm-dev-246514"
         region      = "global"
         key_ring    = "vault-helm-unseal-kr"
         crypto_key  = "vault-helm-unseal-key"
      }
```

After you have successfully installed Vault, you must
[initialize the Vault](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-deploy#initializing-the-vault)
and obtain the initial root token. You need access to your Kubernetes cluster that
Vault has been deployed into to do this. To initialize the Vault, get a
shell to one of the Vault pods running inside Kubernetes (typically this is done
by using the `kubectl` command-line tool). After you have a shell into the pod,
run the `vault operator init` command:

```shell
kubectl -n gitlab-managed-apps exec -it vault-0 sh
/ $ vault operator init
```

This should give you your unseal keys and initial root token. Make sure to note these down
and keep these safe, as they're required to unseal the Vault throughout its lifecycle.
