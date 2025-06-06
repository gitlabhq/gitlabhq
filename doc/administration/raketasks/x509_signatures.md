---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: X.509 signatures Rake task
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

When [signing commits with X.509](../../user/project/repository/signed_commits/x509.md),
the trust anchor might change and the signatures stored in the database must be updated.

## Update all X.509 signatures

This task:

- Iterates through all X.509-signed commits.
- Updates their verification status based on the current certificate store.
- Modifies only the database entries for the signatures.
- Leaves the commits unchanged.

To update all X.509 signatures, run:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## Troubleshooting

When working with X.509 certificates, you might encounter the following issues.

### Error: `GRPC::DeadlineExceeded` during signature updates

You might get an error that states `GRPC::DeadlineExceeded` when updating X.509 signatures.

This issue occurs when network timeouts or connectivity problems prevent the task from
completing.

To resolve this issue, the task automatically retries up to 5 times for each signature by default.
You can customize the retry limit by setting the `GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT`
environment variable:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT=2 sudo gitlab-rake gitlab:x509:update_signatures
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT=2 sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}
