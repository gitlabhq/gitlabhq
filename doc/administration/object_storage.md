---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Object storage **(FREE SELF)**

GitLab supports using an object storage service for holding numerous types of data.
It's recommended over NFS and
in general it's better in larger setups as object storage is
typically much more performant, reliable, and scalable.

## Options

GitLab has been tested on a number of object storage providers:

- [Amazon S3](https://aws.amazon.com/s3/)
- [Google Cloud Storage](https://cloud.google.com/storage)
- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces/)
- [Oracle Cloud Infrastructure](https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
- [OpenStack Swift](https://docs.openstack.org/swift/latest/s3_compat.html)
- [Azure Blob storage](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
- On-premises hardware and appliances from various storage vendors.
- MinIO. We have [a guide to deploying this](https://docs.gitlab.com/charts/advanced/external-object-storage/minio.html) within our Helm Chart documentation.

### Known compatibility issues

- Dell EMC ECS: Prior to GitLab 13.3, there is a [known bug in GitLab Workhorse that prevents
  HTTP Range Requests from working with CI job artifacts](https://gitlab.com/gitlab-org/gitlab/-/issues/223806).
  Be sure to upgrade to GitLab 13.3.0 or above if you use S3 storage with this hardware.

- Ceph S3 prior to [Kraken 11.0.2](https://ceph.com/releases/kraken-11-0-2-released/) does not support the [Upload Copy Part API](https://gitlab.com/gitlab-org/gitlab/-/issues/300604). You may need to [disable multi-threaded copying](#multi-threaded-copying).

## Configuration guides

There are two ways of specifying object storage configuration in GitLab:

- [Consolidated form](#consolidated-object-storage-configuration): A single credential is
  shared by all supported object types.
- [Storage-specific form](#storage-specific-configuration): Every object defines its
  own object storage [connection and configuration](#connection-settings).

For more information on the differences and to transition from one form to another, see
[Transition to consolidated form](#transition-to-consolidated-form).

### Consolidated object storage configuration

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4368) in GitLab 13.2.

Using the consolidated object storage configuration has a number of advantages:

- It can simplify your GitLab configuration since the connection details are shared
  across object types.
- It enables the use of [encrypted S3 buckets](#encrypted-s3-buckets).
- It [uploads files to S3 with proper `Content-MD5` headers](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222).

Because [direct upload mode](../development/uploads.md#direct-upload)
must be enabled, only the following providers can be used:

- [Amazon S3-compatible providers](#s3-compatible-connection-settings)
- [Google Cloud Storage](#google-cloud-storage-gcs)
- [Azure Blob storage](#azure-blob-storage)

When consolidated object storage is used, direct upload is enabled
automatically. Background upload is not supported. For storage-specific
configuration, [direct upload may become the default](https://gitlab.com/gitlab-org/gitlab/-/issues/27331)
because it does not require a shared folder.

Consolidated object storage configuration can't be used for backups or
Mattermost. See the [full table for a complete list](#storage-specific-configuration).

Enabling consolidated object storage enables object storage for all object
types. If you want to use local storage for specific object types, you can
[selectively disable object storages](#selectively-disabling-object-storage).

Most types of objects, such as CI artifacts, LFS files, upload
attachments, and so on can be saved in object storage by specifying a single
credential for object storage with multiple buckets.

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
    # OPTIONAL: The following lines are only needed if server side encryption is required
    gitlab_rails['object_store']['storage_options'] = {
      'server_side_encryption' => '<AES256 or aws:kms>',
      'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
    }
    gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '<artifacts>'
    gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = '<external-diffs>'
    gitlab_rails['object_store']['objects']['lfs']['bucket'] = '<lfs-objects>'
    gitlab_rails['object_store']['objects']['uploads']['bucket'] = '<uploads>'
    gitlab_rails['object_store']['objects']['packages']['bucket'] = '<packages>'
    gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = '<dependency-proxy>'
    gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = '<terraform-state>'
    gitlab_rails['object_store']['objects']['pages']['bucket'] = '<pages>'
    ```

   For GitLab 9.4 or later, if you're using AWS IAM profiles, be sure to omit the
   AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
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
     storage_options:
       server_side_encryption: <AES256 or aws:kms>
       server_side_encryption_key_kms_id: <arn:aws:kms:xxx>
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
       pages:
         bucket: <pages>
   ```

1. Edit `/home/git/gitlab-workhorse/config.toml` and add or amend the following lines:

   ```toml
   [object_storage]
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

| Setting           | Description                       |
|-------------------|-----------------------------------|
| `enabled`         | Enable or disable object storage. |
| `proxy_download`  | Set to `true` to [enable proxying all files served](#proxy-download). Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data. |
| `connection`      | Various [connection options](#connection-settings) described below. |
| `storage_options` | Options to use when saving new objects, such as [server side encryption](#server-side-encryption-headers). Introduced in GitLab 13.3. |
| `objects`         | [Object-specific configuration](#object-specific-configuration). |

### Connection settings

Both consolidated configuration form and storage-specific configuration form must configure a connection. The following sections describe parameters that can be used
in the `connection` setting.

#### S3-compatible connection settings

The connection settings match those provided by [fog-aws](https://github.com/fog/fog-aws):

| Setting                         | Description                        | Default |
|---------------------------------|------------------------------------|---------|
| `provider`                      | Always `AWS` for compatible hosts. | `AWS` |
| `aws_access_key_id`             | AWS credentials, or compatible.    | |
| `aws_secret_access_key`         | AWS credentials, or compatible.    | |
| `aws_signature_version`         | AWS signature version to use. `2` or `4` are valid options. Digital Ocean Spaces and other providers may need `2`. | `4` |
| `enable_signature_v4_streaming` | Set to `true` to enable HTTP chunked transfers with [AWS v4 signatures](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html). Oracle Cloud S3 needs this to be `false`.       | `true` |
| `region`                        | AWS region.                        | |
| `host`                          | S3 compatible host for when not using AWS. For example, `localhost` or `storage.example.com`. HTTPS and port 443 is assumed. | `s3.amazonaws.com` |
| `endpoint`                      | Can be used when configuring an S3 compatible service such as [MinIO](https://min.io), by entering a URL such as `http://127.0.0.1:9000`. This takes precedence over `host`. | (optional) |
| `path_style`                    | Set to `true` to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Leave as `false` for AWS S3. | `false`. |
| `use_iam_profile`               | Set to `true` to use IAM profile instead of access keys. | `false` |

#### Oracle Cloud S3 connection settings

Note that Oracle Cloud S3 must be sure to use the following settings:

| Setting                         | Value   |
|---------------------------------|---------|
| `enable_signature_v4_streaming` | `false` |
| `path_style`                    | `true`  |

If `enable_signature_v4_streaming` is set to `true`, you may see the
following error in `production.log`:

```plaintext
STREAMING-AWS4-HMAC-SHA256-PAYLOAD is not supported
```

#### Google Cloud Storage (GCS)

Here are the valid connection parameters for GCS:

| Setting                      | Description       | Example |
|------------------------------|-------------------|---------|
| `provider`                   | Provider name.    | `Google` |
| `google_project`             | GCP project name. | `gcp-project-12345` |
| `google_client_email`        | Email address of the service account. | `foo@gcp-project-12345.iam.gserviceaccount.com` |
| `google_json_key_location`   | JSON key path.    | `/path/to/gcp-project-12345-abcde.json` |
| `google_application_default` | Set to `true` to use [Google Cloud Application Default Credentials](https://cloud.google.com/docs/authentication/production#automatically) to locate service account credentials. | |

The service account must have permission to access the bucket. Learn more
in Google's
[Cloud Storage authentication documentation](https://cloud.google.com/storage/docs/authentication).

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

##### Google example with ADC (consolidated form)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/275979) in GitLab 13.6.

Google Cloud Application Default Credentials (ADC) are typically
used with GitLab to use the default service account. This eliminates the
need to supply credentials for the instance. For example:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'Google',
  'google_project' => '<GOOGLE PROJECT>',
  'google_application_default' => true
}
```

If you use ADC, be sure that:

- The service account that you use has the
[`iam.serviceAccounts.signBlob` permission](https://cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/signBlob).
  Typically this is done by granting the `Service Account Token Creator` role to the service account.
- Your virtual machines have the [correct access scopes to access Google Cloud APIs](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#changeserviceaccountandscopes). If the machines do not have the right scope, the error logs may show:

  ```markdown
  Google::Apis::ClientError (insufficientPermissions: Request had insufficient authentication scopes.)
  ```

#### Azure Blob storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25877) in GitLab 13.4.

Although Azure uses the word `container` to denote a collection of
blobs, GitLab standardizes on the term `bucket`. Be sure to configure
Azure container names in the `bucket` settings.

Azure Blob storage can only be used with the [consolidated form](#consolidated-object-storage-configuration)
because a single set of credentials are used to access multiple
containers. The [storage-specific form](#storage-specific-configuration)
is not supported. For more details, see [how to transition to consolidated form](#transition-to-consolidated-form).

The following are the valid connection parameters for Azure. Read the
[Azure Blob storage documentation](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
to learn more.

| Setting                      | Description    | Example   |
|------------------------------|----------------|-----------|
| `provider`                   | Provider name. | `AzureRM` |
| `azure_storage_account_name` | Name of the Azure Blob Storage account used to access the storage. | `azuretest` |
| `azure_storage_access_key`   | Storage account access key used to access the container. This is typically a secret, 512-bit encryption key encoded in base64. | `czV2OHkvQj9FKEgrTWJRZVRoV21ZcTN0Nnc5eiRDJkYpSkBOY1JmVWpYbjJy\nNHU3eCFBJUQqRy1LYVBkU2dWaw==\n` |
| `azure_storage_domain`       | Domain name used to contact the Azure Blob Storage API (optional). Defaults to `blob.core.windows.net`. Set this if you are using Azure China, Azure Germany, Azure US Government, or some other custom Azure domain. | `blob.core.windows.net` |

##### Azure example (consolidated form)

For Omnibus installations, this is an example of the `connection` setting:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AzureRM',
  'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
  'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
  'azure_storage_domain' => '<AZURE STORAGE DOMAIN>',
}
```

###### Azure Workhorse settings (source installs only)

For source installations, Workhorse also needs to be configured with Azure
credentials. This isn't needed in Omnibus installs, because the Workhorse
settings are populated from the previous settings.

1. Edit `/home/git/gitlab-workhorse/config.toml` and add or amend the following lines:

   ```toml
   [object_storage]
     provider = "AzureRM"

   [object_storage.azurerm]
     azure_storage_account_name = "<AZURE STORAGE ACCOUNT NAME>"
     azure_storage_access_key = "<AZURE STORAGE ACCESS KEY>"
   ```

If you are using a custom Azure storage domain, note that
`azure_storage_domain` does **not** have to be set in the Workhorse
configuration. This information is exchanged in an API call between
GitLab Rails and Workhorse.

#### OpenStack-compatible connection settings

Although OpenStack Swift provides S3 compatibility, some users may want to use
the [Swift API](https://docs.openstack.org/swift/latest/api/object_api_v1_overview.html).

This isn't compatible with the consolidated object storage form. OpenStack Swift
is supported only with the storage-specific form. If you want to use the
consolidated form, see the [S3 settings](#s3-compatible-connection-settings).

Here are the valid connection settings for the Swift API, provided by
[fog-openstack](https://github.com/fog/fog-openstack):

| Setting                  | Description          | Default |
|--------------------------|----------------------|---------|
| `provider`               | Always `OpenStack` for compatible hosts. | `OpenStack` |
| `openstack_username`     | OpenStack username.  | |
| `openstack_api_key`      | OpenStack API key.   | |
| `openstack_temp_url_key` | OpenStack key for generating temporary URLs | |
| `openstack_auth_url`     | OpenStack authentication endpoint | |
| `openstack_region`       | OpenStack region.    | |
| `openstack_tenant`       | OpenStack tenant ID. | |

#### Rackspace Cloud Files

The following table describes the valid connection parameters for
Rackspace Cloud, provided by [fog-rackspace](https://github.com/fog/fog-rackspace/).

This isn't compatible with the consolidated object storage form.
Rackspace Cloud is supported only with the storage-specific form.

| Setting                  | Description    | Example     |
|--------------------------|----------------|-------------|
| `provider`               | Provider name. | `Rackspace` |
| `rackspace_username`     | Username of the Rackspace account with access to the container. | `joe.smith` |
| `rackspace_api_key`      | API key of the Rackspace account with access to the container. | `ABC123DEF456ABC123DEF456ABC123DE` |
| `rackspace_region`       | Rackspace storage region to use, a three letter code from the [list of service access endpoints](https://docs.rackspace.com/docs/cloud-files/v1/general-api-info/service-access/). | `iad` |
| `rackspace_temp_url_key` | Private key you set in the Rackspace API for [temporary URLs](https://docs.rackspace.com/docs/cloud-files/v1/use-cases/public-access-to-your-cloud-files-account/#tempurl). | `ABC123DEF456ABC123DEF456ABC123DE` |

Regardless of whether the container has public access enabled or disabled, Fog
uses the TempURL method to grant access to LFS objects. If you see error
messages in logs that refer to instantiating storage with a `temp-url-key`,
be sure you have set the key properly both in the Rackspace API and in
`gitlab.rb`. You can verify the value of the key Rackspace has set by sending a
GET request with token header to the service access endpoint URL and comparing
the output of the returned headers.

### Object-specific configuration

The following YAML shows how the `object_store` section defines
object-specific configuration block and how the `enabled` and
`proxy_download` flags can be overridden. The `bucket` is the only
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
        pages:
          bucket: pages
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
gitlab_rails['object_store']['objects']['pages']['bucket'] = 'pages'
```

This is the list of valid `objects` that can be used:

|  Type              | Description                                                                |
|--------------------|----------------------------------------------------------------------------|
| `artifacts`        | [CI artifacts](job_artifacts.md)                                           |
| `external_diffs`   | [Merge request diffs](merge_request_diffs.md)                              |
| `uploads`          | [User uploads](uploads.md)                                                 |
| `lfs`              | [Git Large File Storage objects](lfs/index.md)                             |
| `packages`         | [Project packages (for example, PyPI, Maven, or NuGet)](packages/index.md) |
| `dependency_proxy` | [GitLab Dependency Proxy](packages/dependency_proxy.md)                    |
| `terraform_state`  | [Terraform state files](terraform_state.md)                                |
| `pages`            | [GitLab Pages](pages/index.md)                                             |

Within each object type, three parameters can be defined:

| Setting          | Required?              | Description                         |
|------------------|------------------------|-------------------------------------|
| `bucket`         | **{check-circle}** Yes | Bucket name for the object storage. |
| `enabled`        | **{dotted-circle}** No | Overrides the common parameter.     |
| `proxy_download` | **{dotted-circle}** No | Overrides the common parameter.     |

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

Although this provides flexibility in that it makes it possible for GitLab
to store objects across different cloud providers, it also creates
additional complexity and unnecessary redundancy. Since both GitLab
Rails and Workhorse components need access to object storage, the
consolidated form avoids excessive duplication of credentials.

The consolidated object storage configuration is used _only_ if all lines from
the original form is omitted. To move to the consolidated form, remove the
original configuration (for example, `artifacts_object_store_enabled`, or
`uploads_object_store_connection`)

### Storage-specific configuration

For configuring object storage in GitLab 13.1 and earlier, or for storage types not
supported by consolidated configuration form, refer to the following guides:

| Object storage type | Supported by consolidated configuration? |
|---------------------|------------------------------------------|
| [Backups](../raketasks/backup_restore.md#uploading-backups-to-a-remote-cloud-storage) | **{dotted-circle}** No |
| [Job artifacts](job_artifacts.md#using-object-storage) including archived job logs | **{check-circle}** Yes |
| [LFS objects](lfs/index.md#storing-lfs-objects-in-remote-object-storage) | **{check-circle}** Yes |
| [Uploads](uploads.md#using-object-storage) | **{check-circle}** Yes |
| [Container Registry](packages/container_registry.md#use-object-storage) (optional feature) | **{dotted-circle}** No |
| [Merge request diffs](merge_request_diffs.md#using-object-storage) | **{check-circle}** Yes |
| [Mattermost](https://docs.mattermost.com/administration/config-settings.html#file-storage)| **{dotted-circle}** No |
| [Packages](packages/index.md#using-object-storage) (optional feature) | **{check-circle}** Yes |
| [Dependency Proxy](packages/dependency_proxy.md#using-object-storage) (optional feature) **(PREMIUM SELF)** | **{check-circle}** Yes |
| [Pseudonymizer](pseudonymizer.md#configuration) (optional feature) **(ULTIMATE SELF)** | **{dotted-circle}** No |
| [Autoscale runner caching](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) (optional for improved performance) | **{dotted-circle}** No |
| [Terraform state files](terraform_state.md#using-object-storage) | **{check-circle}** Yes |
| [GitLab Pages content](pages/index.md#using-object-storage) | **{check-circle}** Yes |

### Other alternatives to file system storage

If you're working to [scale out](reference_architectures/index.md) your GitLab implementation,
or add fault tolerance and redundancy, you may be
looking at removing dependencies on block or network file systems.
See the following additional guides:

1. Make sure the [`git` user home directory](https://docs.gitlab.com/omnibus/settings/configuration.html#moving-the-home-directory-for-a-user) is on local disk.
1. Configure [database lookup of SSH keys](operations/fast_ssh_key_lookup.md)
   to eliminate the need for a shared `authorized_keys` file.
1. [Prevent local disk usage for job logs](job_logs.md#prevent-local-disk-usage).

## Warnings, limitations, and known issues

### Use separate buckets

Using separate buckets for each data type is the recommended approach for GitLab.
This ensures there are no collisions across the various types of data GitLab stores.
There are plans to [enable the use of a single bucket](https://gitlab.com/gitlab-org/gitlab/-/issues/292958)
in the future.

Helm-based installs require separate buckets to
[handle backup restorations](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-pseudonymizer).

### S3 API compatibility issues

Not all S3 providers [are fully compatible](../raketasks/backup_restore.md#other-s3-providers)
with the Fog library that GitLab uses. Symptoms include an error in `production.log`:

```plaintext
411 Length Required
```

### Proxy Download

Clients can download files in object storage by receiving a pre-signed, time-limited URL,
or by GitLab proxying the data from object storage to the client.
Downloading files from object storage directly
helps reduce the amount of egress traffic GitLab
needs to process.

When the files are stored on local block storage or NFS, GitLab has to act as a proxy.
This is not the default behavior with object storage.

The `proxy_download` setting controls this behavior: the default is generally `false`.
Verify this in the documentation for each use case. Set it to `true` if you want
GitLab to proxy the files.

When not proxying files, GitLab returns an
[HTTP 302 redirect with a pre-signed, time-limited object storage URL](https://gitlab.com/gitlab-org/gitlab/-/issues/32117#note_218532298).
This can result in some of the following problems:

- If GitLab is using non-secure HTTP to access the object storage, clients may generate
`https->http` downgrade errors and refuse to process the redirect. The solution to this
is for GitLab to use HTTPS. LFS, for example, generates this error:

   ```plaintext
   LFS: lfsapi/client: refusing insecure redirect, https->http
   ```

- Clients need to trust the certificate authority that issued the object storage
certificate, or may return common TLS errors such as:

   ```plaintext
   x509: certificate signed by unknown authority
   ```

- Clients need network access to the object storage.
Network firewalls could block access.
Errors that might result
if this access is not in place include:

   ```plaintext
   Received status code 403 from server: Forbidden
   ```

Getting a `403 Forbidden` response is specifically called out on the
[package repository documentation](packages/index.md#using-object-storage)
as a side effect of how some build tools work.

Additionally for a short time period users could share pre-signed, time-limited object storage URLs
with others without authentication. Also bandwidth charges may be incurred
between the object storage provider and the client.

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
GitLab Workhorse uploads files to S3 using pre-signed URLs that do
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
When this is used, GitLab fetches temporary credentials each time an
S3 bucket is accessed, so no hard-coded values are needed in the
configuration.

#### Encrypted S3 buckets

> - Introduced in [GitLab 13.1](https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/466) for instance profiles only and [S3 default encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html).
> - Introduced in [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34460) for static credentials when [consolidated object storage configuration](#consolidated-object-storage-configuration) and [S3 default encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html) are used.

When configured either with an instance profile or with the consolidated
object configuration, GitLab Workhorse properly uploads files to S3
buckets that have [SSE-S3 or SSE-KMS encryption enabled by
default](https://docs.aws.amazon.com/kms/latest/developerguide/services-s3.html).
Note that customer master keys (CMKs) and SSE-C encryption are [not
supported since this requires sending the encryption keys in every request](https://gitlab.com/gitlab-org/gitlab/-/issues/226006).

##### Server-side encryption headers

> Introduced in [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38240).

Setting a default encryption on an S3 bucket is the easiest way to
enable encryption, but you may want to [set a bucket policy to ensure
only encrypted objects are uploaded](https://aws.amazon.com/premiumsupport/knowledge-center/s3-bucket-store-kms-encrypted-objects/).
To do this, you must configure GitLab to send the proper encryption headers
in the `storage_options` configuration section:

| Setting                             | Description                              |
|-------------------------------------|------------------------------------------|
| `server_side_encryption`            | Encryption mode (`AES256` or `aws:kms`). |
| `server_side_encryption_kms_key_id` | Amazon Resource Name. Only needed when `aws:kms` is used in `server_side_encryption`. See the [Amazon documentation on using KMS encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingKMSEncryption.html). |

As with the case for default encryption, these options only work when
the Workhorse S3 client is enabled. One of the following two conditions
must be fulfilled:

- `use_iam_profile` is `true` in the connection settings.
- Consolidated object storage settings are in use.

[ETag mismatch errors](#etag-mismatch) occur if server side
encryption headers are used without enabling the Workhorse S3 client.

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

### Multi-threaded copying

GitLab uses the [S3 Upload Part Copy API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html)
to accelerate the copying of files within a bucket. Ceph S3 [prior to Kraken 11.0.2](https://ceph.com/releases/kraken-11-0-2-released/)
does not support this and [returns a 404 error when files are copied during the upload process](https://gitlab.com/gitlab-org/gitlab/-/issues/300604).

The feature can be disabled using the `:s3_multithreaded_uploads`
feature flag. To disable the feature, ask a GitLab administrator with
[Rails console access](feature_flags.md#how-to-enable-and-disable-features-behind-flags)
to run the following command:

```ruby
Feature.disable(:s3_multithreaded_uploads)
```
