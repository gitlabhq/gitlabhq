---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 19 upgrade notes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This page contains upgrade information for minor and patch versions of GitLab 19.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For additional information for Helm chart installations, see
[the Helm chart 10.0 upgrade notes](https://docs.gitlab.com/charts/releases/10_0/).

## Required upgrade stops

To provide a predictable upgrade schedule for instance administrators,
required upgrade stops occur at versions:

- `19.2`
- `19.5`
- `19.8`
- `19.11`

## Upgrade notes reference

The following is a reference list of upgrade notes for each minor GitLab version.
Each list item points to a specific section that holds more information.

Items marked with an installation method, like `(Geo)` or `(Linux package)`,
apply only to that method. All other items apply to all installation methods.

### Upgrade to 19.0

Before upgrading to GitLab 19.0, review the following:

- [19.0.0 - 19.0.1] - [Container registry metadata database enabled by default in prefer mode](#container-registry-metadata-database-enabled-by-default-in-prefer-mode) (Linux package, self-compiled)
- [19.0.0] - [Container registry S3 storage driver replaced by s3_v2](#container-registry-s3-storage-driver-replaced-by-s3_v2) (Linux package, self-compiled)
- [19.0.0] - [PostgreSQL 17 minimum requirement](#postgresql-17-minimum-requirement)
- [19.0.0] - [Linux package support for Ubuntu 20.04 discontinued](#linux-package-support-for-ubuntu-2004-discontinued) (Linux package)
- [19.0.0] - [Redis 6 support removed](#redis-6-support-removed) (Linux package)
- [19.0.0] - [Mattermost removed from the Linux package](#mattermost-removed-from-the-linux-package) (Linux package)
- [19.0.0] - [Linux package support for SUSE distributions discontinued](#linux-package-support-for-suse-distributions-discontinued) (Linux package)
- [19.0.0] - [Spamcheck removed from Linux package and GitLab Helm chart](#spamcheck-removed-from-linux-package-and-gitlab-helm-chart) (Linux package, Helm chart)
- [19.0.0] - [NGINX Ingress replaced by Gateway API with Envoy Gateway](#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway) (Helm chart)
- [19.0.0] - [Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart](#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart) (Helm chart)
- [19.0.0 - 19.0.1] - [Geo container repository sync silently skips OCI image index tags](#geo-container-repository-sync-silently-skips-oci-image-index-tags) (Geo)
- [16.0.0 - 19.0.1] - [Geo design management replication `NoMethodError` when project is `nil`](#geo-design-management-replication-nomethoderror-when-project-is-nil) (Geo)

## Upgrade notes

Specific upgrade notes for GitLab 19.

### Container registry metadata database enabled by default in prefer mode

- Affects: Linux package, self-compiled
- Affected versions: 19.0.0, 19.0.1

In GitLab 19.0, the container registry metadata database defaults to `prefer` mode for
existing installations that do not have `registry['database']['enabled']` explicitly set
in `/etc/gitlab/gitlab.rb`. In prefer mode, the registry attempts to use the metadata
database. If the existing registry data has not been imported into the database, the
registry falls back to legacy filesystem metadata at startup.

Due to a bug ([issue 600955](https://gitlab.com/gitlab-org/gitlab/-/work_items/600955)),
the registry router was initialized before the prefer-fallback detection ran. This caused
nil pointer dereference panics on all `/gitlab/v1/` routes, resulting in `HTTP 500` errors
when the registry UI polls for group-level storage size. The actual Docker push and pull
protocol (`/v2/`) is not affected by this bug.

The bug is fixed in GitLab 19.0.2, which includes container registry `v4.40.1-gitlab`.

If you are running 19.0.0 or 19.0.1 and see repeated
`runtime error: invalid memory address or nil pointer dereference` panics in
`/var/log/gitlab/registry/current` at `handlers.(*repositoryHandler).HandleGetRepository`,
apply the following workaround:

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['database'] = {
     'enabled' => false
   }
   ```

1. Reconfigure and restart the registry:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart registry
   ```

After upgrading to 19.0.2 or later, remove the override and reconfigure again to restore
default behavior.

For more information, see
[the container registry metadata database documentation](../../administration/packages/container_registry_metadata_database.md).

### Container registry S3 storage driver replaced by s3_v2

- Affects: Linux package, self-compiled
- Affected versions: 19.0.0

In GitLab 19.0, the legacy `s3` container registry storage driver (AWS SDK v1) is removed
and aliased to the new `s3_v2` driver (AWS SDK v2). This change affects installations
using S3-compatible object storage backends such as Ceph RGW, MinIO, or OVH S3.

The `s3_v2` driver introduces two breaking changes for non-AWS S3-compatible backends:

- `regionendpoint` requires a full URI including scheme. The `s3_v2` driver requires
  `https://` (or `http://`) in the `regionendpoint` value. A bare hostname such as
  `storage.example.com` is no longer valid and causes a startup error:

  ```plaintext
  endpoint rule error, Custom endpoint `storage.example.com` was not a valid URI
  ```

  Update your configuration to include the scheme:

  ```ruby
  registry['storage'] = {
    's3_v2' => {
      'regionendpoint' => 'https://storage.example.com',
      # ...
    }
  }
  ```

- AWS SDK v2 sends enhanced checksums by default. The `s3_v2` driver sends
  `x-amz-content-sha256` and CRC64NVME checksums on uploads. Ceph RGW, older MinIO
  versions, OVH S3, and other S3-compatible backends may reject these with HTTP 400
  (`XAmzContentSHA256Mismatch`). Add `'checksum_disabled' => true` to disable this behavior.

  The `checksum_disabled` setting only suppresses checksums on upload (`PutObject`) calls.
  The `DeleteObjects` code path also sends a CRC32 checksum header that some S3-compatible
  backends do not support. If your backend rejects this header, image pushes that trigger
  blob deletions fail with a `MissingContentMD5` or `InvalidRequest` error even when
  `checksum_disabled` is set to `true`.

  To resolve this issue, upgrade your S3-compatible storage backend to a version that
  supports CRC32 checksum headers. Consult your storage provider's documentation for
  the minimum version required.

  No `gitlab.rb` configuration workaround exists for the `DeleteObjects` code path.
  For more information, see
  [issue 2309](https://gitlab.com/gitlab-org/container-registry/-/issues/2309).

For Ceph RGW and most S3-compatible backends, update your configuration as follows:

```ruby
registry['storage'] = {
  's3_v2' => {
    'accesskey' => '<your-access-key>',
    'secretkey' => '<your-secret-key>',
    'bucket' => '<your-bucket>',
    'region' => '<your-region>',
    'regionendpoint' => 'https://<your-s3-endpoint>',
    'pathstyle' => true,
    'checksum_disabled' => true
  }
}
```

For more information, see
[the container registry object storage documentation](../../administration/packages/container_registry.md#use-object-storage).

### Geo design management replication `NoMethodError` when project is `nil`

- Affects: Geo
- Affected versions: 16.0.0 - 19.0.1

On Geo secondary sites, a `NoMethodError` could occur during replication of
design management repositories when the associated project had been deleted,
leaving an orphaned `DesignManagement::Repository` record. GitLab 19.0.2 corrects
this issue.

For more information, see [issue 597049](https://gitlab.com/gitlab-org/gitlab/-/issues/597049).

### PostgreSQL 17 minimum requirement

- Affects: All installation methods
- Affected versions: 19.0.0

The minimum supported version of PostgreSQL is now version 17. Before installing GitLab 19.0:

- If you use the packaged PostgreSQL 16,
  [upgrade the packaged PostgreSQL server](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).
- If you use an [external PostgreSQL](../../administration/postgresql/external.md) instance,
  upgrade it to PostgreSQL 17.

### Geo container repository sync silently skips OCI image index tags

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

- Affects: Geo (container registry)
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 19.0    | 19.0.0 - 19.0.1         | 19.0.2            |

On Geo secondary sites, container repository sync silently skipped tags whose
manifest is an OCI image index (`application/vnd.oci.image.index.v1+json`).
Multi-arch images and BuildKit cache tags commonly use this manifest type. No
error was raised and tag counts matched, but `docker pull` of an affected tag
from the secondary returned `manifest unknown`. The same root cause also left
orphan tags on the secondary that sync could not remove.

After you upgrade both the primary and secondary sites to a fixed version, newly
synced tags are correct. Previously affected repositories converge on their next
verification cycle, which can take up to the re-verification interval (90 days by
default). To repair affected repositories immediately,
[resync the container repositories on the secondary site](../../administration/geo/replication/container_registry.md#manually-trigger-a-container-registry-sync-event).

For more information, see [issue 600486](https://gitlab.com/gitlab-org/gitlab/-/work_items/600486).

### Linux package support for Ubuntu 20.04 discontinued

- Affects: Linux package
- Affected versions: 19.0.0

Ubuntu 20.04 reached end of standard support in May 2025. From GitLab 19.0, Linux packages are no
longer provided for Ubuntu 20.04. GitLab 18.11 is the last release with packages for this
distribution. Before upgrading to GitLab 19.0, migrate to Ubuntu 22.04 or another
[supported operating system](../../install/package/_index.md#supported-platforms).

### Redis 6 support removed

- Affects: Linux package
- Affected versions: 19.0.0

Support for Redis 6 is removed in GitLab 19.0. If you use an external Redis 6 deployment, migrate
to Redis 7.0 or higher, or Valkey 7.2, before upgrading. Redis 7.2 or Valkey 7.2 is recommended.
Redis 7.0 has reached end-of-life (EOL) upstream, but in some cases is actively maintained by
vendors, such as Amazon ElastiCache for Redis 7.1. The bundled Redis included with the Linux
package has used Redis 7 since GitLab 16.2 and is not affected.

### Mattermost removed from the Linux package

- Affects: Linux package
- Affected versions: 19.0.0

Bundled Mattermost is removed from the Linux package in GitLab 19.0. If you currently use the
bundled Mattermost, see
[Migrating from the Linux package to Mattermost Standalone](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)
for migration instructions. If you do not use the bundled Mattermost, you are not impacted.

Before upgrading to GitLab 19.0, remove or comment out all `mattermost[...]` settings from `/etc/gitlab/gitlab.rb`.
If any `mattermost[...]` keys remain, `gitlab-ctl reconfigure` aborts immediately after the package
is installed with:

```plaintext
RuntimeError: Removed configurations found in gitlab.rb. Aborting reconfigure.
```

> [!NOTE]
> `gitlab-ctl check-config --version 19.0.x` does not currently detect this condition.
> Do not rely on `check-config` to validate Mattermost key removal before upgrading.
> See [issue 9916](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9916) for details.

### Linux package support for SUSE distributions discontinued

- Affects: Linux package
- Affected versions: 19.0.0

Linux package support for SUSE distributions ends in GitLab 19.0, which affects openSUSE Leap 15.6,
SUSE Linux Enterprise Server 12.5, and SUSE Linux Enterprise Server 15.6. GitLab 18.11 is the last
version with Linux packages for these distributions. To continue to use SUSE distributions, migrate
to a [Docker deployment of GitLab](../../install/docker/installation.md).

### Spamcheck removed from Linux package and GitLab Helm chart

- Affects: Linux package, Helm chart
- Affected versions: 19.0.0

[Spamcheck](../../administration/reporting/spamcheck.md) is removed from the Linux package and
GitLab Helm chart in GitLab 19.0. Customers not currently using Spamcheck are not impacted. If you
use the bundled Spamcheck, you can deploy it separately using
[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck).
No data migration is required.

### NGINX Ingress replaced by Gateway API with Envoy Gateway

- Affects: Helm chart
- Affected versions: 19.0.0

Gateway API with Envoy Gateway becomes the default networking configuration in the GitLab Helm chart
in GitLab 19.0, replacing NGINX Ingress which reached end-of-life in March 2026. If migration to
Envoy Gateway is not immediately feasible, you can explicitly re-enable the bundled NGINX Ingress,
which remains available until its proposed removal in GitLab 20.0. This change does not impact the
NGINX used in the Linux package, or Helm chart instances using an externally managed Ingress or
Gateway API controller.

For detailed migration steps, see the
[Helm chart 10.0 upgrade notes](https://docs.gitlab.com/charts/releases/10_0/).

### Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart

- Affects: Helm chart
- Affected versions: 19.0.0

The bundled Bitnami PostgreSQL, Bitnami Redis, and MinIO charts are removed from the GitLab Helm
chart and GitLab Operator in GitLab 19.0 with no replacement. These components were intended only
for proof-of-concept and test environments and are not recommended for production use. If you run an
instance with any of these bundled services, follow the
[migration guide](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)
to configure external services before upgrading to GitLab 19.0.
