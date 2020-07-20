---
type: reference
---

# Object Storage

GitLab supports using an object storage service for holding numerous types of data.
It's recommended over NFS and
in general it's better in larger setups as object storage is
typically much more performant, reliable, and scalable.

## Options

GitLab has been tested on a number of object storage providers:

- [Amazon S3](https://aws.amazon.com/s3/)
- [Google Cloud Storage](https://cloud.google.com/storage)
- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces)
- [Oracle Cloud Infrastructure](https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
- [Openstack Swift](https://docs.openstack.org/swift/latest/s3_compat.html)
- On-premises hardware and appliances from various storage vendors.
- MinIO. We have [a guide to deploying this](https://docs.gitlab.com/charts/advanced/external-object-storage/minio.html) within our Helm Chart documentation.

## Configuration guides

There are two ways of specifying object storage configuration in GitLab:

- [Consolidated form](#consolidated-object-storage-configuration): A single credential is
  shared by all supported object types.
- [Storage-specific form](#storage-specific-configuration): Every object defines its
  own object storage [connection and configuration](#connection-settings).

For more information on the differences and to transition from one form to another, see
[Transition to consolidated form](#transition-to-consolidated-form).

### Consolidated object storage configuration

> Introduced in [GitLab 13.2](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4368).

Using the consolidated object storage configuration has a number of advantages:

- It can simplify your GitLab configuration since the connection details are shared
  across object types.
- It enables the use of [encrypted S3 buckets](#encrypted-s3-buckets).
- It [uploads files to S3 with proper `Content-MD5` headers](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222).

NOTE: **Note:**
Only AWS S3-compatible providers and Google are
supported at the moment since [direct upload
mode](../development/uploads.md#direct-upload) must be used. Background
upload is not supported in this mode. We recommend direct upload mode because
it does not require a shared folder, and [this setting may become the default](https://gitlab.com/gitlab-org/gitlab/-/issues/27331).

NOTE: **Note:**
Consolidated object storage configuration cannot be used for
backups or Mattermost. See [the full table for a complete list](#storage-specific-configuration).

Most types of objects, such as CI artifacts, LFS files, upload
attachments, and so on can be saved in object storage by specifying a single
credential for object storage with multiple buckets. A [different bucket
for each type must be used](#use-separate-buckets).

When the consolidated form is:

- Used with an S3-compatible object storage, Workhorse uses its internal S3 client to
  upload files.
- Not used with an S3-compatible object storage, Workhorse falls back to using
  pre-signed URLs.

See the section on [ETag mismatch errors](#etag-mismatch) for more details.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, substituting
   the values you want:

    ```ruby
    # Consolidated object storage configuration
    gitlab_rails['object_store']['enabled'] = true
    gitlab_rails['object_store']['proxy_download'] = true
    gitlab_rails['object_store']['connection'] = {
      'provider' => 'AWS',
      'region' => '<eu-central-1>',
      'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
      'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
    }
    gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '<artifacts>'
    gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = '<external-diffs>'
    gitlab_rails['object_store']['objects']['lfs']['bucket'] = '<lfs-objects>'
    gitlab_rails['object_store']['objects']['uploads']['bucket'] = '<uploads>'
    gitlab_rails['object_store']['objects']['packages']['bucket'] = '<packages>'
    gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = '<dependency-proxy>'
    gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = '<terraform-state>'
    ```

   NOTE: For GitLab 9.4 or later, if you're using AWS IAM profiles, be sure to omit the
   AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['object_store_connection'] = {
     'provider' => 'AWS',
     'region' => '<eu-central-1>',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   object_store:
     enabled: true
     proxy_download: true
     connection:
       provider: AWS
       aws_access_key_id: <AWS_ACCESS_KEY_ID>
       aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
       region: <eu-central-1>
     objects:
       artifacts:
         bucket: <artifacts>
       external_diffs:
         bucket: <external-diffs>
       lfs:
         bucket: <lfs-objects>
       uploads:
         bucket: <uploads>
       packages:
         bucket: <packages>
       dependency_proxy:
         bucket: <dependency_proxy>
       terraform_state:
         bucket: <terraform>
   ```

1. Edit `/home/git/gitlab-workhorse/config.toml` and add or amend the following lines:

   ```toml
   [object_storage]
     enabled = true
     provider = "AWS"

   [object_storage.s3]
     aws_access_key_id = "<AWS_ACCESS_KEY_ID>"
     aws_secret_access_key = "<AWS_SECRET_ACCESS_KEY>"
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

#### Common parameters

In the consolidated configuration, the `object_store` section defines a
common set of parameters. Here we use the YAML from the source
installation because it's easier to see the inheritance:

```yaml
    object_store:
      enabled: true
      proxy_download: true
      connection:
        provider: AWS
        aws_access_key_id: <AWS_ACCESS_KEY_ID>
        aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
      objects:
        ...
```

The Omnibus configuration maps directly to this:

```ruby
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['proxy_download'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'aws_access_key_id' => '<AWS_ACCESS_KEY_ID',
  'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
}
```

| Setting | Description |
|---------|-------------|
| `enabled` | Enable/disable object storage |
| `proxy_download` | Set to `true` to [enable proxying all files served](#proxy-download). Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data |
| `connection` | Various connection options described below |
| `objects` | [Object-specific configuration](#object-specific-configuration)

### Connection settings

Both consolidated configuration form and storage-specific configuration form must configure a connection. The following sections describe parameters that can be used
in the `connection` setting.

#### S3-compatible connection settings

The connection settings match those provided by [fog-aws](https://github.com/fog/fog-aws):

| Setting | Description | Default |
|---------|-------------|---------|
| `provider` | Always `AWS` for compatible hosts | `AWS` |
| `aws_access_key_id` | AWS credentials, or compatible | |
| `aws_secret_access_key` | AWS credentials, or compatible | |
| `aws_signature_version` | AWS signature version to use. `2` or `4` are valid options. Digital Ocean Spaces and other providers may need `2`. | `4` |
| `enable_signature_v4_streaming` | Set to `true` to enable HTTP chunked transfers with [AWS v4 signatures](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html). Oracle Cloud S3 needs this to be `false`. | `true` |
| `region` | AWS region | us-east-1 |
| `host` | S3 compatible host for when not using AWS, e.g. `localhost` or `storage.example.com`. HTTPS and port 443 is assumed. | `s3.amazonaws.com` |
| `endpoint` | Can be used when configuring an S3 compatible service such as [MinIO](https://min.io), by entering a URL such as `http://127.0.0.1:9000`. This takes precedence over `host`. | (optional) |
| `path_style` | Set to `true` to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Leave as `false` for AWS S3. | `false` |
| `use_iam_profile` | Set to `true` to use IAM profile instead of access keys | `false`

#### Oracle Cloud S3 connection settings

Note that Oracle Cloud S3 must be sure to use the following settings:

| Setting | Value |
|---------|-------|
| `enable_signature_v4_streaming` | `false` |
| `path_style` | `true` |

If `enable_signature_v4_streaming` is set to `true`, you may see the
following error in `production.log`:

```plaintext
STREAMING-AWS4-HMAC-SHA256-PAYLOAD is not supported
```

#### Google Cloud Storage (GCS)

Here are the valid connection parameters for GCS:

| Setting | Description | example |
|---------|-------------|---------|
| `provider` | The provider name | `Google` |
| `google_project` | GCP project name | `gcp-project-12345` |
| `google_client_email` | The email address of the service account | `foo@gcp-project-12345.iam.gserviceaccount.com` |
| `google_json_key_location` | The JSON key path | `/path/to/gcp-project-12345-abcde.json` |

NOTE: **Note:**
The service account must have permission to access the bucket.
[See more](https://cloud.google.com/storage/docs/authentication)

##### Google example (consolidated form)

For Omnibus installations, this is an example of the `connection` setting:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'Google',
  'google_project' => '<GOOGLE PROJECT>',
  'google_client_email' => '<GOOGLE CLIENT EMAIL>',
  'google_json_key_location' => '<FILENAME>'
}
```

#### OpenStack-compatible connection settings

NOTE: **Note:**
This is not compatible with the consolidated object storage form.
OpenStack Swift is only supported with the storage-specific form. See the
[S3 settings](#s3-compatible-connection-settings) if you want to use the consolidated form.

While OpenStack Swift provides S3 compatibliity, some users may want to use the
[Swift API](https://docs.openstack.org/swift/latest/api/object_api_v1_overview.html).
Here are the valid connection settings below for the Swift API, provided by
[fog-openstack](https://github.com/fog/fog-openstack):

| Setting | Description | Default |
|---------|-------------|---------|
| `provider` | Always `OpenStack` for compatible hosts | `OpenStack` |
| `openstack_username` | OpenStack username | |
| `openstack_api_key` | OpenStack API key  | |
| `openstack_temp_url_key` | OpenStack key for generating temporary URLs | |
| `openstack_auth_url` | OpenStack authentication endpoint | |
| `openstack_region` | OpenStack region | |
| `openstack_tenant` | OpenStack tenant ID |

#### Rackspace Cloud Files

NOTE: **Note:**
This is not compatible with the consolidated object
storage form. Rackspace Cloud is only supported with the storage-specific form.

Here are the valid connection parameters for Rackspace Cloud, provided by
[fog-rackspace](https://github.com/fog/fog-rackspace/):

| Setting | Description | example |
|---------|-------------|---------|
| `provider` | The provider name | `Rackspace` |
| `rackspace_username` | The username of the Rackspace account with access to the container | `joe.smith` |
| `rackspace_api_key` | The API key of the Rackspace account with access to the container | `ABC123DEF456ABC123DEF456ABC123DE` |
| `rackspace_region` | The Rackspace storage region to use, a three letter code from the [list of service access endpoints](https://developer.rackspace.com/docs/cloud-files/v1/general-api-info/service-access/) | `iad` |
| `rackspace_temp_url_key` | The private key you have set in the Rackspace API for temporary URLs. Read more [here](https://developer.rackspace.com/docs/cloud-files/v1/use-cases/public-access-to-your-cloud-files-account/#tempurl) | `ABC123DEF456ABC123DEF456ABC123DE` |

NOTE: **Note:**
Regardless of whether the container has public access enabled or disabled, Fog will
use the TempURL method to grant access to LFS objects. If you see errors in logs referencing
instantiating storage with a `temp-url-key`, ensure that you have set the key properly
on the Rackspace API and in `gitlab.rb`. You can verify the value of the key Rackspace
has set by sending a GET request with token header to the service access endpoint URL
and comparing the output of the returned headers.

### Object-specific configuration

The following YAML shows how the `object_store` section defines
object-specific configuration block and how the `enabled` and
`proxy_download` flags can be overriden. The `bucket` is the only
required parameter within each type:

```yaml
  object_store:
      connection:
        ...
      objects:
        artifacts:
          bucket: artifacts
          proxy_download: false
        external_diffs:
          bucket: external-diffs
        lfs:
          bucket: lfs-objects
        uploads:
          bucket: uploads
        packages:
          bucket: packages
        dependency_proxy:
          enabled: false
          bucket: dependency_proxy
        terraform_state:
          bucket: terraform
```

This maps to this Omnibus GitLab configuration:

```ruby
gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'artifacts'
gitlab_rails['object_store']['objects']['artifacts']['proxy_download'] = false
gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'external-diffs'
gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'lfs-objects'
gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'uploads'
gitlab_rails['object_store']['objects']['packages']['bucket'] = 'packages'
gitlab_rails['object_store']['objects']['dependency_proxy']['enabled'] = false
gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'dependency-proxy'
gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'terraform-state'
```

This is the list of valid `objects` that can be used:

|  Type              | Description |
|--------------------|---------------|
| `artifacts`        | [CI artifacts](job_artifacts.md) |
| `external_diffs`   | [Merge request diffs](merge_request_diffs.md) |
| `uploads`          | [User uploads](uploads.md) |
| `lfs`              | [Git Large File Storage objects](lfs/index.md) |
| `packages`         | [Project packages (e.g. PyPI, Maven, NuGet, etc.)](packages/index.md) |
| `dependency_proxy` | [GitLab Dependency Proxy](packages/dependency_proxy.md) |
| `terraform_state`  | [Terraform state files](terraform_state.md) |

Within each object type, three parameters can be defined:

| Setting          | Required? | Description |
|------------------|-----------|-------------|
| `bucket`         | Yes       | The bucket name for the object storage. |
| `enabled`        | No        | Overrides the common parameter |
| `proxy_download` | No        | Overrides the common parameter |

#### Selectively disabling object storage

As seen above, object storage can be disabled for specific types by
setting the `enabled` flag to `false`. For example, to disable object
storage for CI artifacts:

```ruby
gitlab_rails['object_store']['objects']['artifacts']['enabled'] = false
```

A bucket is not needed if the feature is disabled entirely. For example,
no bucket is needed if CI artifacts are disabled with this setting:

```ruby
gitlab_rails['artifacts_enabled'] = false
```

### Transition to consolidated form

Prior to GitLab 13.2:

- Object storage configuration for all types of objects such as CI/CD artifacts, LFS
  files, upload attachments, and so on had to be configured independently.
- Object store connection parameters such as passwords and endpoint URLs had to be
  duplicated for each type.

For example, an Omnibus GitLab install might have the following configuration:

```ruby
# Original object storage configuration
gitlab_rails['artifacts_object_store_enabled'] = true
gitlab_rails['artifacts_object_store_direct_upload'] = true
gitlab_rails['artifacts_object_store_proxy_download'] = true
gitlab_rails['artifacts_object_store_remote_directory'] = 'artifacts'
gitlab_rails['artifacts_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_direct_upload'] = true
gitlab_rails['uploads_object_store_proxy_download'] = true
gitlab_rails['uploads_object_store_remote_directory'] = 'uploads'
gitlab_rails['uploads_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
```

While this provides flexibility in that it makes it possible for GitLab
to store objects across different cloud providers, it also creates
additional complexity and unnecessary redundancy. Since both GitLab
Rails and Workhorse components need access to object storage, the
consolidated form avoids excessive duplication of credentials.

NOTE: **Note:**
The consolidated object storage configuration is **only** used if all
lines from the original form is omitted. To move to the consolidated form, remove the original configuration (for example, `artifacts_object_store_enabled`, `uploads_object_store_connection`, and so on.)

## Storage-specific configuration

For configuring object storage in GitLab 13.1 and earlier, or for storage types not
supported by consolidated configuration form, refer to the following guides:

|Object storage type|Supported by consolidated configuration?|
|-------------------|----------------------------------------|
| [Backups](../raketasks/backup_restore.md#uploading-backups-to-a-remote-cloud-storage)|No|
| [Job artifacts](job_artifacts.md#using-object-storage) and [incremental logging](job_logs.md#new-incremental-logging-architecture) | Yes |
| [LFS objects](lfs/index.md#storing-lfs-objects-in-remote-object-storage) | Yes |
| [Uploads](uploads.md#using-object-storage-core-only) | Yes |
| [Container Registry](packages/container_registry.md#use-object-storage) (optional feature) | No |
| [Merge request diffs](merge_request_diffs.md#using-object-storage) | Yes |
| [Mattermost](https://docs.mattermost.com/administration/config-settings.html#file-storage)| No |
| [Packages](packages/index.md#using-object-storage) (optional feature) **(PREMIUM ONLY)** | Yes |
| [Dependency Proxy](packages/dependency_proxy.md#using-object-storage) (optional feature) **(PREMIUM ONLY)** | Yes |
| [Pseudonymizer](pseudonymizer.md#configuration) (optional feature) **(ULTIMATE ONLY)** | No |
| [Autoscale Runner caching](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) (optional for improved performance) | No |
| [Terraform state files](terraform_state.md#using-object-storage-core-only) | Yes |

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
with the Fog library that GitLab uses. Symptoms include an error in `production.log`:

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
To fix this issue, you have two options:

- [Use the consolidated object configuration](#consolidated-object-storage-configuration).
- [Use Amazon instance profiles](#using-amazon-instance-profiles).

The first option is recommended for MinIO. Otherwise, the
[workaround for MinIO](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564#note_244497658)
is to use the `--compat` parameter on the server.

Without consolidated object store configuration or instance profiles enabled,
GitLab Workhorse will upload files to S3 using pre-signed URLs that do
not have a `Content-MD5` HTTP header computed for them. To ensure data
is not corrupted, Workhorse checks that the MD5 hash of the data sent
equals the ETag header returned from the S3 server. When encryption is
enabled, this is not the case, which causes Workhorse to report an `ETag
mismatch` error during an upload.

With the consolidated object configuration and instance profile, Workhorse has
S3 credentials so that it can compute the `Content-MD5` header. This
eliminates the need to compare ETag headers returned from the S3 server.

### Using Amazon instance profiles

Instead of supplying AWS access and secret keys in object storage
configuration, GitLab can be configured to use IAM roles to set up an
[Amazon instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html).
When this is used, GitLab will fetch temporary credentials each time an
S3 bucket is accessed, so no hard-coded values are needed in the
configuration.

#### Encrypted S3 buckets

> - Introduced in [GitLab 13.1](https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/466) for instance profiles only.
> - Introduced in [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34460) for static credentials when [consolidated object storage configuration](#consolidated-object-storage-configuration) is used.

When configured either with an instance profile or with the consolidated
object configuration, GitLab Workhorse properly uploads files to S3 buckets
that have [SSE-S3 or SSE-KMS encryption enabled by
default](https://docs.aws.amazon.com/kms/latest/developerguide/services-s3.html).
Note that customer master keys (CMKs) and
SSE-C encryption are [not yet supported since this requires supplying
keys to the GitLab configuration](https://gitlab.com/gitlab-org/gitlab/-/issues/226006).

##### Disabling the feature

The Workhorse S3 client is enabled by default when the
[`use_iam_profile` configuration option](#iam-permissions) is set to `true`.

The feature can be disabled using the `:use_workhorse_s3_client` feature flag. To disable the
feature, ask a GitLab administrator with
[Rails console access](feature_flags.md#how-to-enable-and-disable-features-behind-flags) to run the
following command:

```ruby
Feature.disable(:use_workhorse_s3_client)
```

#### IAM Permissions

To set up an instance profile:

1. Create an Amazon Identity Access and Management (IAM) role with the necessary permissions. The
   following example is a role for an S3 bucket named `test-bucket`:

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

1. [Attach this role](https://aws.amazon.com/premiumsupport/knowledge-center/attach-replace-ec2-instance-profile/)
   to the EC2 instance hosting your GitLab instance.
1. Configure GitLab to use it via the `use_iam_profile` configuration option.
