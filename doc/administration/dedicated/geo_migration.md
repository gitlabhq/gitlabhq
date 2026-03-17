---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Migrate from GitLab Self-Managed to GitLab Dedicated with Geo.
title: Migrate to GitLab Dedicated with Geo
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Geo migration requires secrets from your GitLab Self-Managed primary instance so that GitLab
Dedicated can decrypt your data after migration. These secrets include database encryption keys,
CI/CD variables, and other sensitive configuration details.

SSH host keys are optional, but strongly recommended. Preserving them prevents SSH host key
verification failures when users run `git clone` or `git pull` over SSH after migration.
They are especially important if you plan to use your own domain.

The collection scripts use [age](https://github.com/FiloSottile/age), a file encryption tool,
to securely encrypt your secrets before you upload them to Switchboard.

## Collect and upload migration secrets

Collect and upload Geo migration secrets when you [create your GitLab Dedicated instance](create_instance/_index.md#create-your-instance).

Prerequisites:

- Administrative access to your GitLab Self-Managed primary instance
- Python 3.x
- The `age` public key from the **Geo migration secrets** page in Switchboard
- `kubectl` configured with access to your GitLab cluster (Kubernetes installations only)

To collect and upload migration secrets:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. On the **Geo migration secrets** page, download the appropriate collection script for your installation type.
1. Optional. For offline environments, embed the `age` binary into the collection script before
   running it. For more information, see [offline environments](#offline-environments).
1. Run the collection script for your installation type, and replace `<age_public_key>` with
   the key displayed on the page:

   - For Linux package installations, run the following command on a Rails node:

     ```shell
     python3 collect_secrets_linux_package.py <age_public_key>
     ```

     It requires read access to `/etc/gitlab/gitlab-secrets.json`, `/var/opt/gitlab/gitlab-rails/etc/database.yml`, and `/etc/ssh/`.

   - For Kubernetes installations, run the following command from a workstation with `kubectl` access:

     ```shell
     python3 collect_secrets_k8s.py <age_public_key>
     ```

     To override default values, you can pass additional flags. For more information,
     see [Kubernetes collection script flags](#kubernetes-collection-script-flags).

1. Optional. To collect SSH host keys only, add the `--hostkeys-only` flag to the command.

   The script generates:

   - `migration_secrets.json.age`: GitLab secrets (required)
   - `ssh_host_keys.json.age`: SSH host keys (optional but recommended)

1. Upload your `migration_secrets.json.age` file.
1. Optional. Upload your `ssh_host_keys.json.age` file.
1. Wait for validation to complete. Validation takes approximately 10-20 seconds per file.
1. Verify the filename and fingerprint displayed match your uploaded files.

> [!note]
> Validation checks that files are properly encrypted and contain the expected structure.
> It does not decrypt or expose the contents of your files.

After uploading your secrets, complete the remaining steps to create your tenant.

### Kubernetes collection script flags

Use these optional flags with `collect_secrets_k8s.py` to override default values:

| Flag                     | Default         | Description |
|--------------------------|-----------------|-------------|
| `--namespace NAME`       | Current context | Kubernetes namespace. |
| `--release NAME`         | `gitlab`        | Helm release name prefix. |
| `--rails-secret NAME`    | None            | Rails secrets secret name. |
| `--registry-secret NAME` | None            | Registry secret name. |
| `--postgres-secret NAME` | None            | Postgres password secret name. |
| `--hostkeys-secret NAME` | None            | SSH host keys secret name. |

### Offline environments

If your GitLab Self-Managed instance doesn't have internet access,
download the `age` binary manually before running the collection script.

To set up the collection script for offline environments:

1. On a machine with internet access, download the `age` binary:

   ```shell
   python3 download_age_binaries.py
   ```

   This generates an `age_binaries.tar.gz` file that contains the `age` binary for multiple platforms.

1. Transfer the `age_binaries.tar.gz` file to your offline environment.
1. Embed the binary into the collection script:

   ```shell
   python3 embed_age_binary.py --binaries age_binaries.tar.gz
   ```

   This creates a self-contained script that includes the `age` binary.

1. Run the embedded script on your GitLab Self-Managed instance as described in [collect and upload migration secrets](#collect-and-upload-migration-secrets).

The embedded script automatically extracts and uses the included `age` binary.

## Troubleshooting

When working with Geo migration, you might encounter the following issues.

### Error: `Permission denied` when running the collection script

You might get a permission error when the collection script tries to access GitLab configuration files.

This issue occurs when the script runs without sufficient privileges to read the required files.

To resolve this issue:

1. For Linux package installations, run the script as the `root` user or use `sudo`.
1. For Kubernetes installations, ensure your `kubectl` context has access to the GitLab namespace.
1. Verify the required files exist at the expected paths.

### Collection script cannot find GitLab installation

You might get an error that the script cannot locate your GitLab installation or configuration files.

This issue occurs in the following scenarios:

- The script runs on a machine without GitLab installed.
- GitLab is installed in a non-standard location.
- Required configuration files are missing or moved.

Common error messages include:

- Linux package: `Error: database.yml not found: /var/opt/gitlab/gitlab-rails/etc/database.yml` followed by `✗ Failed to collect GitLab secrets`
- Kubernetes: `Error: Could not retrieve gitlab-rails-secrets`

To resolve this issue:

1. Verify the script runs on the correct machine (a Rails node for Linux package installations).
1. Check that GitLab is properly installed and configured.
1. If GitLab is installed in a non-standard location, verify the configuration file paths match your installation.
1. If required files are missing or corrupted, contact Professional Services to perform a health check of your installation before proceeding with the migration.
