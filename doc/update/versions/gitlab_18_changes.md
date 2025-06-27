---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 18 changes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This page contains upgrade information for minor and patch versions of GitLab 18.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 9.0](https://docs.gitlab.com/charts/releases/9_0/).

## 18.1.0

### Geo installations 18.1.0

- GitLab version 18.1.0 has a known issue where Git operations that are proxied from a secondary Geo site fail with HTTP 500 errors. To resolve, upgrade to GitLab 18.1.1 or later.

## 18.0.0

### Geo installations 18.0.0

- If you deployed GitLab Enterprise Edition and then reverted to GitLab Community Edition,
  your database schema may deviate from the schema that the GitLab application expects,
  leading to migration errors. Four particular errors can be encountered on upgrade to 18.0.0
  because a migration was added in that version which changes the defaults of those columns.

  The errors are:

  - `No such column: geo_nodes.verification_max_capacity`
  - `No such column: geo_nodes.minimum_reverification_interval`
  - `No such column: geo_nodes.repos_max_capacity`
  - `No such column: geo_nodes.container_repositories_max_capacity`

  This migration was patched in GitLab 18.0.2 to add those columns if they are missing.
  See [issue #543146](https://gitlab.com/gitlab-org/gitlab/-/issues/543146).

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 18.0                    |  18.0.0 - 18.0.1        | 18.0.2   |

- GitLab versions 18.0 through 18.0.2 have a known issue where Git operations that are proxied from a secondary Geo site fail with HTTP 500 errors. To resolve, upgrade to GitLab 18.0.3 or later.

### PRNG is not seeded error on Docker installations

If you run GitLab on a Docker installation with a FIPS-enabled host, you
may see that SSH key generation or the OpenSSH server (`sshd`) fails to
start with the error message:

```plaintext
PRNG is not seeded
```

GitLab 18.0 [updated the base image from Ubuntu 22.04 to 24.04](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8928).
This error occurs because Ubuntu 24.04 no longer [allows a FIPS host to use a non-FIPS OpenSSL provider](https://github.com/dotnet/dotnet-docker/issues/5849#issuecomment-2324943811).

To fix this issue, you have a few options:

- Disable FIPS on the host system.
- Disable the auto-detection of a FIPS-based kernel in the GitLab Docker container.
  This can be done by setting the `OPENSSL_FORCE_FIPS_MODE=0` environment variable with GitLab 18.0.2 or higher.
- Instead of using the GitLab Docker image, install a [native FIPS package](https://packages.gitlab.com/gitlab/gitlab-fips) on the host.

The last option is the recommended one to meet FIPS requirements. For
legacy installations, the first two options can be used as a stopgap.
