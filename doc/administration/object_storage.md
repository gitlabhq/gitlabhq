---
type: reference
---

# Object Storage

GitLab supports using an object storage service for holding numerous types of data.
It's recommended over NFS and
in general it's better in larger setups as object storage is
typically much more performant, reliable, and scalable.

## Options

Object storage options that GitLab has tested, or is aware of customers using include:

- SaaS/Cloud solutions such as [Amazon S3](https://aws.amazon.com/s3/), [Google cloud storage](https://cloud.google.com/storage).
- On-premises hardware and appliances from various storage vendors.
- MinIO. We have [a guide to deploying this](https://docs.gitlab.com/charts/advanced/external-object-storage/minio.html) within our Helm Chart documentation.

## Configuration guides

For configuring GitLab to use Object Storage refer to the following guides:

1. Configure [object storage for backups](../raketasks/backup_restore.md#uploading-backups-to-a-remote-cloud-storage).
1. Configure [object storage for job artifacts](job_artifacts.md#using-object-storage)
   including [incremental logging](job_logs.md#new-incremental-logging-architecture).
1. Configure [object storage for LFS objects](lfs/index.md#storing-lfs-objects-in-remote-object-storage).
1. Configure [object storage for uploads](uploads.md#using-object-storage-core-only).
1. Configure [object storage for merge request diffs](merge_request_diffs.md#using-object-storage).
1. Configure [object storage for Container Registry](packages/container_registry.md#container-registry-storage-driver) (optional feature).
1. Configure [object storage for Mattermost](https://docs.mattermost.com/administration/config-settings.html#file-storage) (optional feature).
1. Configure [object storage for packages](packages/index.md#using-object-storage) (optional feature). **(PREMIUM ONLY)**
1. Configure [object storage for Dependency Proxy](packages/dependency_proxy.md#using-object-storage) (optional feature). **(PREMIUM ONLY)**
1. Configure [object storage for Pseudonymizer](pseudonymizer.md#configuration) (optional feature). **(ULTIMATE ONLY)**
1. Configure [object storage for autoscale Runner caching](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) (optional - for improved performance).
1. Configure [object storage for Terraform state files](terraform_state.md#using-object-storage-core-only)

### Other alternatives to filesystem storage

If you're working to [scale out](reference_architectures/index.md) your GitLab implementation,
or add fault tolerance and redundancy, you may be
looking at removing dependencies on block or network filesystems.
See the following guides and
[note that Pages requires disk storage](#gitlab-pages-requires-nfs):

1. Make sure the [`git` user home directory](https://docs.gitlab.com/omnibus/settings/configuration.html#moving-the-home-directory-for-a-user) is on local disk.
1. Configure [database lookup of SSH keys](operations/fast_ssh_key_lookup.md)
   to eliminate the need for a shared `authorized_keys` file.

## Warnings, limitations, and known issues

### Use separate buckets

Using separate buckets for each data type is the recommended approach for GitLab.

A limitation of our configuration is that each use of object storage is separately configured.
[We have an issue for improving this](https://gitlab.com/gitlab-org/gitlab/-/issues/23345)
and easily using one bucket with separate folders is one improvement that this might bring.

There is at least one specific issue with using the same bucket:
when GitLab is deployed with the Helm chart restore from backup
[will not properly function](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-pseudonymizer)
unless separate buckets are used.

One risk of using a single bucket would be that if your organisation decided to
migrate GitLab to the Helm deployment in the future. GitLab would run, but the situation with
backups might not be realised until the organisation had a critical requirement for the backups to work.

### S3 API compatibility issues

Not all S3 providers [are fully compatible](../raketasks/backup_restore.md#other-s3-providers)
with the Fog library that GitLab uses. Symptoms include:

```plaintext
411 Length Required
```

### GitLab Pages requires NFS

If you're working to add more GitLab servers for [scaling or fault tolerance](reference_architectures/index.md)
and one of your requirements is [GitLab Pages](../user/project/pages/index.md) this currently requires
NFS. There is [work in progress](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/196)
to remove this dependency. In the future, GitLab Pages may use
[object storage](https://gitlab.com/gitlab-org/gitlab/-/issues/208135).

The dependency on disk storage also prevents Pages being deployed using the
[GitLab Helm chart](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/37).

### Incremental logging is required for CI to use object storage

If you configure GitLab to use object storage for CI logs and artifacts,
[you must also enable incremental logging](job_artifacts.md#using-object-storage).

### Proxy Download

A number of the use cases for object storage allow client traffic to be redirected to the
object storage back end, like when Git clients request large files via LFS or when
downloading CI artifacts and logs.

When the files are stored on local block storage or NFS, GitLab has to act as a proxy.
This is not the default behavior with object storage.

The `proxy_download` setting controls this behavior: the default is generally `false`.
Verify this in the documentation for each use case. Set it to `true` so that GitLab proxies
the files.

When not proxying files, GitLab returns an
[HTTP 302 redirect with a pre-signed, time-limited object storage URL](https://gitlab.com/gitlab-org/gitlab/-/issues/32117#note_218532298).
This can result in some of the following problems:

- If GitLab is using non-secure HTTP to access the object storage, clients may generate
`https->http` downgrade errors and refuse to process the redirect. The solution to this
is for GitLab to use HTTPS. LFS, for example, will generate this error:

   ```plaintext
   LFS: lfsapi/client: refusing insecure redirect, https->http
   ```

- Clients will need to trust the certificate authority that issued the object storage
certificate, or may return common TLS errors such as:

   ```plaintext
   x509: certificate signed by unknown authority
   ```

- Clients will need network access to the object storage. Errors that might result
if this access is not in place include:

   ```plaintext
   Received status code 403 from server: Forbidden
   ```

Getting a `403 Forbidden` response is specifically called out on the
[package repository documentation](packages/index.md#using-object-storage)
as a side effect of how some build tools work.

### ETag mismatch

Using the default GitLab settings, some object storage back-ends such as
[MinIO](https://gitlab.com/gitlab-org/gitlab/-/issues/23188)
and [Alibaba](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564)
might generate `ETag mismatch` errors.

When using GitLab direct upload, the
[workaround for MinIO](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564#note_244497658)
is to use the `--compat` parameter on the server.

We are working on a fix to GitLab component Workhorse, and also
a workaround, in the mean time, to
[allow ETag verification to be disabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18175).
