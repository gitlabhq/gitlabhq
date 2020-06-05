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

If you are seeing this ETag mismatch error with Amazon Web Services S3,
it's likely this is due to [encryption settings on your bucket](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonResponseHeaders.html).
See the section on [using Amazon instance profiles](#using-amazon-instance-profiles) on how to fix this issue.

When using GitLab direct upload, the
[workaround for MinIO](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564#note_244497658)
is to use the `--compat` parameter on the server.

We are working on a fix to the [GitLab Workhorse
component](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222).

### Using Amazon instance profiles

Instead of supplying AWS access and secret keys in object storage
configuration, GitLab can be configured to use IAM roles to set up an
[Amazon instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html).
When this is used, GitLab will fetch temporary credentials each time an
S3 bucket is accessed, so no hard-coded values are needed in the
configuration.

#### Encrypted S3 buckets

> Introduced in [GitLab 13.1](https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/466) only for instance profiles.

When configured to use an instance profile, GitLab Workhorse
will properly upload files to S3 buckets that have [SSE-S3 or SSE-KMS
encryption enabled by default](https://docs.aws.amazon.com/kms/latest/developerguide/services-s3.html).
Note that customer master keys (CMKs) and SSE-C encryption are not yet
supported since this requires supplying keys to the GitLab
configuration.

Without instance profiles enabled (or prior to GitLab 13.1), GitLab
Workhorse will upload files to S3 using pre-signed URLs that do not have
a `Content-MD5` HTTP header computed for them. To ensure data is not
corrupted, Workhorse checks that the MD5 hash of the data sent equals
the ETag header returned from the S3 server. When encryption is enabled,
this is not the case, which causes Workhorse to report an `ETag
mismatch` error during an upload.

With instance profiles enabled, GitLab Workhorse uses an AWS S3 client
that properly computes and sends the `Content-MD5` header to the server,
which eliminates the need for comparing ETag headers. If the data is
corrupted in transit, the S3 server will reject the file.

#### IAM Permissions

To set up an instance profile, create an Amazon Identity Access and
Management (IAM) role with the necessary permissions. The following
example is a role for an S3 bucket named `test-bucket`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::test-bucket/*"
        }
    ]
}
```

Associate this role with your GitLab instance, and then configure GitLab
to use it via the `use_iam_profile` configuration option. For example,
when configuring uploads to use object storage, see the `AWS IAM profiles`
section in [S3 compatible connection settings](uploads.md#s3-compatible-connection-settings).

#### Disabling the feature

The Workhorse S3 client is only enabled when the `use_iam_profile`
configuration flag is `true`.

To disable this feature, ask a GitLab administrator with [Rails console access](feature_flags.md#how-to-enable-and-disable-features-behind-flags) to run the
following command:

```ruby
Feature.disable(:use_workhorse_s3_client)
```
