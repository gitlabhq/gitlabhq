---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Object storage
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab supports using an object storage service for holding numerous types of data.
It's recommended over NFS and
in general it's better in larger setups as object storage is
typically much more performant, reliable, and scalable.

To configure the object storage, you have two options:

- Recommended. [Configure a single storage connection for all object types](#configure-a-single-storage-connection-for-all-object-types-consolidated-form):
  A single credential is shared by all supported object types. This is called the consolidated form.
- [Configure each object type to define its own storage connection](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form):
  Every object defines its own object storage connection and configuration. This is called the storage-specific form.

  If you already use the storage-specific form, see how to
  [transition to the consolidated form](#transition-to-consolidated-form).

If you store data locally, see how to
[migrate to object storage](#migrate-to-object-storage).

## Supported object storage providers

GitLab is tightly integrated with the Fog library, so you can see which
[providers](https://fog.github.io/about/provider_documentation.html) can be used
with GitLab.

Specifically, GitLab has been tested by vendors and customers on a number of object storage providers:

- [Amazon S3](https://aws.amazon.com/s3/) ([Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
  is not supported, see [issue #335775](https://gitlab.com/gitlab-org/gitlab/-/issues/335775)
  for more information)
- [Google Cloud Storage](https://cloud.google.com/storage)
- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces) (S3 compatible)
- [Oracle Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
- [OpenStack Swift (S3 compatible mode)](https://docs.openstack.org/swift/latest/s3_compat.html)
- [Azure Blob storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
- [MinIO](https://min.io/) (S3 compatible)
- On-premises hardware and appliances from various storage vendors, whose list is not officially established.

## Configure a single storage connection for all object types (consolidated form)

Most types of objects, such as CI artifacts, LFS files, and upload attachments
can be saved in object storage by specifying a single credential for object
storage with multiple buckets.

NOTE:
For GitLab Helm Charts, see how to [configure the consolidated form](https://docs.gitlab.com/charts/charts/globals.html#consolidated-object-storage).

Configuring the object storage using the consolidated form has a number of advantages:

- It can simplify your GitLab configuration since the connection details are shared
  across object types.
- It enables the use of [encrypted S3 buckets](#encrypted-s3-buckets).
- It [uploads files to S3 with proper `Content-MD5` headers](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222).

When the consolidated form is used,
[direct upload](../development/uploads/_index.md#direct-upload) is enabled
automatically. Thus, only the following providers can be used:

- [Amazon S3-compatible providers](#amazon-s3)
- [Google Cloud Storage](#google-cloud-storage-gcs)
- [Azure Blob storage](#azure-blob-storage)

The consolidated form configuration can't be used for backups or
Mattermost. Backups can be configured with
[server side encryption](backup_restore/backup_gitlab.md#s3-encrypted-buckets)
separately. See the
[table for a complete list](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form)
of supported object storage types.

Enabling the consolidated form enables object storage for all object
types. If not all buckets are specified, you may see an error like:

```plaintext
Object storage for <object type> must have a bucket specified
```

If you want to use local storage for specific object types, you can
[disable object storage for specific features](#disable-object-storage-for-specific-features).

### Configure the common parameters

In the consolidated form, the `object_store` section defines a
common set of parameters.

| Setting           | Description                       |
|-------------------|-----------------------------------|
| `enabled`         | Enable or disable object storage. |
| `proxy_download`  | Set to `true` to [enable proxying all files served](#proxy-download). Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data. |
| `connection`      | Various [connection options](#configure-the-connection-settings) described below. |
| `storage_options` | Options to use when saving new objects, such as [server side encryption](#server-side-encryption-headers). |
| `objects`         | [Object-specific configuration](#configure-the-parameters-of-each-object). |

For an example, see how to [use the consolidated form and Amazon S3](#full-example-using-the-consolidated-form-and-amazon-s3).

### Configure the parameters of each object

Each object type must at least define the bucket name where it will be stored.

The following table lists the valid `objects` that can be used:

| Type               | Description |
|--------------------|-------------|
| `artifacts`        | [CI/CD job artifacts](cicd/job_artifacts.md) |
| `external_diffs`   | [Merge request diffs](merge_request_diffs.md) |
| `uploads`          | [User uploads](uploads.md) |
| `lfs`              | [Git Large File Storage objects](lfs/_index.md) |
| `packages`         | [Project packages (for example, PyPI, Maven, or NuGet)](packages/_index.md) |
| `dependency_proxy` | [Dependency Proxy](packages/dependency_proxy.md) |
| `terraform_state`  | [Terraform state files](terraform_state.md) |
| `pages`            | [Pages](pages/_index.md) |
| `ci_secure_files`  | [Secure files](cicd/secure_files.md) |

Within each object type, three parameters can be defined:

| Setting          | Required?              | Description                         |
|------------------|------------------------|-------------------------------------|
| `bucket`         | **{check-circle}** Yes\* | Bucket name for the object type. Not required if `enabled` is set to `false`. |
| `enabled`        | **{dotted-circle}** No | Overrides the [common parameter](#configure-the-common-parameters).     |
| `proxy_download` | **{dotted-circle}** No | Overrides the [common parameter](#configure-the-common-parameters).     |

For an example, see how to [use the consolidated form and Amazon S3](#full-example-using-the-consolidated-form-and-amazon-s3).

#### Disable object storage for specific features

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

## Configure each object type to define its own storage connection (storage-specific form)

With the storage-specific form, every object defines its own object
storage connection and configuration. You should [use the consolidated form](#transition-to-consolidated-form) instead,
except for the storage types not supported by the consolidated form. When working with the GitLab Helm charts, refer to how the charts handle [consolidated form for object storage](https://docs.gitlab.com/charts/charts/globals.html#consolidated-object-storage).

The use of [encrypted S3 buckets](#encrypted-s3-buckets) with non-consolidated form is not supported.
You may get [ETag mismatch errors](#etag-mismatch) if you use it.

NOTE:
For the storage-specific form,
[direct upload may become the default](https://gitlab.com/gitlab-org/gitlab/-/issues/27331)
because it does not require a shared folder.

For storage types not
supported by the consolidated form, refer to the following guides:

| Object storage type | Supported by consolidated form? |
|---------------------|------------------------------------------|
| [Backups](backup_restore/backup_gitlab.md#upload-backups-to-a-remote-cloud-storage) | **{dotted-circle}** No |
| [Container registry](packages/container_registry.md#use-object-storage) (optional feature) | **{dotted-circle}** No |
| [Mattermost](https://docs.mattermost.com/configure/file-storage-configuration-settings.html)| **{dotted-circle}** No |
| [Autoscale runner caching](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) (optional for improved performance) | **{dotted-circle}** No |
| [Secure Files](cicd/secure_files.md#using-object-storage) | **{check-circle}** Yes |
| [Job artifacts](cicd/job_artifacts.md#using-object-storage) including archived job logs | **{check-circle}** Yes |
| [LFS objects](lfs/_index.md#storing-lfs-objects-in-remote-object-storage) | **{check-circle}** Yes |
| [Uploads](uploads.md#using-object-storage) | **{check-circle}** Yes |
| [Merge request diffs](merge_request_diffs.md#using-object-storage) | **{check-circle}** Yes |
| [Packages](packages/_index.md#use-object-storage) (optional feature) | **{check-circle}** Yes |
| [Dependency Proxy](packages/dependency_proxy.md#using-object-storage) (optional feature) | **{check-circle}** Yes |
| [Terraform state files](terraform_state.md#using-object-storage) | **{check-circle}** Yes |
| [Pages content](pages/_index.md#object-storage-settings) | **{check-circle}** Yes |

## Configure the connection settings

Both consolidated and storage-specific form must configure a connection. The following sections describe parameters that can be used
in the `connection` setting.

### Amazon S3

The connection settings match those provided by [fog-aws](https://github.com/fog/fog-aws):

| Setting                                     | Description                        | Default |
|---------------------------------------------|------------------------------------|---------|
| `provider`                                  | Always `AWS` for compatible hosts. | `AWS` |
| `aws_access_key_id`                         | AWS credentials, or compatible.    | |
| `aws_secret_access_key`                     | AWS credentials, or compatible.    | |
| `aws_signature_version`                     | AWS signature version to use. `2` or `4` are valid options. Digital Ocean Spaces and other providers may need `2`. | `4` |
| `enable_signature_v4_streaming`             | Set to `true` to enable HTTP chunked transfers with [AWS v4 signatures](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html). Oracle Cloud S3 needs this to be `false`. GitLab 17.4 changed the default from `true` to `false`.  | `false` |
| `region`                                    | AWS region.                        | |
| `host`                                      | DEPRECATED: Use `endpoint` instead. S3 compatible host for when not using AWS. For example, `localhost` or `storage.example.com`. HTTPS and port 443 is assumed. | `s3.amazonaws.com` |
| `endpoint`                                  | Can be used when configuring an S3 compatible service such as [MinIO](https://min.io), by entering a URL such as `http://127.0.0.1:9000`. This takes precedence over `host`. Always use `endpoint` for consolidated form. | (optional) |
| `path_style`                                | Set to `true` to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Set to `true` for using [MinIO](https://min.io). Leave as `false` for AWS S3. | `false`. |
| `use_iam_profile`                           | Set to `true` to use IAM profile instead of access keys. | `false` |
| `aws_credentials_refresh_threshold_seconds` | Sets the [automatic refresh threshold](https://github.com/fog/fog-aws#controlling-credential-refresh-time-with-iam-authentication) in seconds when using temporary credentials in IAM. | `15` |

#### Use Amazon instance profiles

Instead of supplying AWS access and secret keys in object storage
configuration, you can configure GitLab to use Amazon Identity Access and Management (IAM) roles to set up an
[Amazon instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html).
When this is used, GitLab fetches temporary credentials each time an
S3 bucket is accessed, so no hard-coded values are needed in the
configuration.

Prerequisites:

- GitLab must be able to connect to the
  [instance metadata endpoint](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html).
- If GitLab is [configured to use an internet proxy](https://docs.gitlab.com/omnibus/settings/environment-variables.html), the endpoint IP
  address must be added to the `no_proxy` list.

To set up an instance profile:

1. Create an IAM role with the necessary permissions. The
   following example is a role for an S3 bucket named `test-bucket`:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::test-bucket/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket"
               ],
               "Resource": "arn:aws:s3:::test-bucket"
           }
       ]
   }
   ```

1. [Attach this role](https://repost.aws/knowledge-center/attach-replace-ec2-instance-profile)
   to the EC2 instance hosting your GitLab instance.
1. Set the `use_iam_profile` GitLab configuration option to `true`.

#### Encrypted S3 buckets

When configured either with an instance profile or with the consolidated
form, GitLab Workhorse properly uploads files to S3
buckets that have [SSE-S3 or SSE-KMS encryption enabled by default](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html).
AWS KMS keys and SSE-C encryption are
[not supported since this requires sending the encryption keys in every request](https://gitlab.com/gitlab-org/gitlab/-/issues/226006).

#### Server-side encryption headers

Setting a default encryption on an S3 bucket is the easiest way to
enable encryption, but you may want to
[set a bucket policy to ensure only encrypted objects are uploaded](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects).
To do this, you must configure GitLab to send the proper encryption headers
in the `storage_options` configuration section:

| Setting                             | Description                              |
|-------------------------------------|------------------------------------------|
| `server_side_encryption`            | Encryption mode (`AES256` or `aws:kms`). |
| `server_side_encryption_kms_key_id` | Amazon Resource Name. Only needed when `aws:kms` is used in `server_side_encryption`. See the [Amazon documentation on using KMS encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html). |

As with the case for default encryption, these options only work when
the Workhorse S3 client is enabled. One of the following two conditions
must be fulfilled:

- `use_iam_profile` is `true` in the connection settings.
- Consolidated form is in use.

[ETag mismatch errors](#etag-mismatch) occur if server side
encryption headers are used without enabling the Workhorse S3 client.

### Oracle Cloud S3

Oracle Cloud S3 must be sure to use the following settings:

| Setting                         | Value   |
|---------------------------------|---------|
| `enable_signature_v4_streaming` | `false` |
| `path_style`                    | `true`  |

If `enable_signature_v4_streaming` is set to `true`, you may see the
following error in `production.log`:

```plaintext
STREAMING-AWS4-HMAC-SHA256-PAYLOAD is not supported
```

### Google Cloud Storage (GCS)

Here are the valid connection parameters for GCS:

| Setting                      | Description       | Example |
|------------------------------|-------------------|---------|
| `provider`                   | Provider name.    | `Google` |
| `google_project`             | GCP project name. | `gcp-project-12345` |
| `google_json_key_location`   | JSON key path.    | `/path/to/gcp-project-12345-abcde.json` |
| `google_json_key_string`     | JSON key string.  | `{ "type": "service_account", "project_id": "example-project-382839", ... }` |
| `google_application_default` | Set to `true` to use [Google Cloud Application Default Credentials](https://cloud.google.com/docs/authentication#adc) to locate service account credentials. | |

GitLab reads the value of `google_json_key_location`, then `google_json_key_string`, and finally, `google_application_default`.
It uses the first of these settings that has a value.

The service account must have permission to access the bucket. For more information,
see the [Cloud Storage authentication documentation](https://cloud.google.com/storage/docs/authentication).

NOTE:
To use bucket encryption with [customer-managed encryption keys](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys), use the [consolidated form](#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

#### GCS example

For Linux Package installations, this is an example of the `connection` setting in the consolidated form:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'Google',
  'google_project' => '<GOOGLE PROJECT>',
  'google_json_key_location' => '<FILENAME>'
}
```

#### GCS example with ADC

Google Cloud Application Default Credentials (ADC) are typically
used with GitLab to use the default service account. This eliminates the
need to supply credentials for the instance. For example, in the consolidated form:

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

### Azure Blob storage

Although Azure uses the word `container` to denote a collection of
blobs, GitLab standardizes on the term `bucket`. Be sure to configure
Azure container names in the `bucket` settings.

Azure Blob storage can only be used with the [consolidated form](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)
because a single set of credentials are used to access multiple
containers. The [storage-specific form](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form)
is not supported. For more details, see [how to transition to consolidated form](#transition-to-consolidated-form).

The following are the valid connection parameters for Azure. For more information, see the
[Azure Blob Storage documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction).

| Setting                      | Description    | Example   |
|------------------------------|----------------|-----------|
| `provider`                   | Provider name. | `AzureRM` |
| `azure_storage_account_name` | Name of the Azure Blob Storage account used to access the storage. | `azuretest` |
| `azure_storage_access_key`   | Storage account access key used to access the container. This is typically a secret, 512-bit encryption key encoded in base64. This is optional for [Azure workload and managed identities](#azure-workload-and-managed-identities). | `czV2OHkvQj9FKEgrTWJRZVRoV21ZcTN0Nnc5eiRDJkYpSkBOY1JmVWpYbjJy\nNHU3eCFBJUQqRy1LYVBkU2dWaw==\n` |
| `azure_storage_domain`       | Domain name used to contact the Azure Blob Storage API (optional). Defaults to `blob.core.windows.net`. Set this if you are using Azure China, Azure Germany, Azure US Government, or some other custom Azure domain. | `blob.core.windows.net` |

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, substituting
   the values you want:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   If you are using [a workload identity](#azure-workload-and-managed-identities), omit `azure_storage_access_key`:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `object_storage.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#connection):

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_access_key: <YOUR_AZURE_STORAGE_ACCOUNT_KEY>
   azure_storage_domain: blob.core.windows.net
   ```

   If you are using [a workload or managed identity](#azure-workload-and-managed-identities), omit `azure_storage_access_key`:

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_domain: blob.core.windows.net
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AzureRM',
             'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
             'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
             'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

    If you are using [a managed identity](#azure-workload-and-managed-identities), omit `azure_storage_access_key`.

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

For self-compiled installations, Workhorse also needs to be configured with Azure
credentials. This isn't needed in Linux package installations because the Workhorse
settings are populated from the previous settings.

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AzureRM
         azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
         azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

1. Edit `/home/git/gitlab-workhorse/config.toml` and add or amend the following lines:

     ```toml
     [object_storage]
       provider = "AzureRM"

     [object_storage.azurerm]
       azure_storage_account_name = "<AZURE STORAGE ACCOUNT NAME>"
       azure_storage_access_key = "<AZURE STORAGE ACCESS KEY>"
     ```

   If you are using a custom Azure storage domain, `azure_storage_domain`
   does **not** have to be set in the Workhorse configuration. This
   information is exchanged in an API call between GitLab Rails and
   Workhorse.

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

#### Azure workload and managed identities

> - [Introduced in GitLab 17.9](https://gitlab.com/gitlab-org/gitlab/-/issues/242245)

To use [Azure workload identities](https://azure.github.io/azure-workload-identity/docs/) or [managed identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/), omit
`azure_storage_access_key` from the configuration. When
`azure_storage_access_key` is blank, GitLab attempts to:

1. Obtain temporary credentials with [a workload identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-overview). `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, and `AZURE_FEDERATED_TOKEN_FILE` should be in the environment.
1. If a workload identity is not available, request credentials from the [Azure Instance Metadata Service](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token).
1. Get a [User Delegation Key](https://learn.microsoft.com/en-us/rest/api/storageservices/get-user-delegation-key).
1. Generate a SAS token with that key to access a Storage Account blob.

Ensure that the identity has the `Storage Blob Data Contributor` role
assigned to it.

### Storj Gateway (SJ)

NOTE:
The Storj Gateway [does not support](https://github.com/storj/gateway-st/blob/4b74c3b92c63b5de7409378b0d1ebd029db9337d/docs/s3-compatibility.md) multi-threaded copying (see `UploadPartCopy` in the table).
While an implementation [is planned](https://github.com/storj/roadmap/issues/40), you must [disable multi-threaded copying](#multi-threaded-copying) until completion.

The [Storj Network](https://www.storj.io/) provides an S3-compatible API gateway. Use the following configuration example:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://gateway.storjshare.io',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 2,
  'enable_signature_v4_streaming' => false
}
```

The signature version must be `2`. Using v4 results in a HTTP 411 Length Required error.
For more information, see [issue #4419](https://gitlab.com/gitlab-org/gitlab/-/issues/4419).

### Hitachi Vantara HCP

NOTE:
Connections to HCP may return an error stating `SignatureDoesNotMatch - The request signature we calculated does not match the signature you provided. Check your HCP Secret Access key and signing method.` In these cases, set the `endpoint` to the URL of the tenant instead of the namespace, and ensure bucket paths are configured as `<namespace_name>/<bucket_name>`.

[HCP](https://docs.hitachivantara.com/r/en-us/content-platform-for-cloud-scale/2.6.x/mk-hcpcs008/getting-started/introducing-hcp-for-cloud-scale/support-for-the-amazon-s3-api) provides an S3-compatible API. Use the following configuration example:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://<tenant_endpoint>',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 4,
  'enable_signature_v4_streaming' => false
}

# Example of <namespace_name/bucket_name> formatting
gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '<namespace_name>/<bucket_name>'
```

## Full example using the consolidated form and Amazon S3

The following example uses AWS S3 to enable object storage for all supported services:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, substituting
   the values you want:

   ```ruby
   # Consolidated object storage configuration
   gitlab_rails['object_store']['enabled'] = true
   gitlab_rails['object_store']['proxy_download'] = false
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
     'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
   }
   # OPTIONAL: The following lines are only needed if server side encryption is required
   gitlab_rails['object_store']['storage_options'] = {
     'server_side_encryption' => '<AES256 or aws:kms>',
     'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   If you're using [AWS IAM profiles](#use-amazon-instance-profiles), omit
   the AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `object_storage.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#connection):

   ```yaml
   provider: AWS
   region: us-east-1
   aws_access_key_id: <AWS_ACCESS_KEY_ID>
   aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
   ```

   If you're using [AWS IAM profiles](#use-amazon-instance-profiles), omit
   the AWS access key and secret access key/value pairs. For example:

   ```yaml
   provider: AWS
   region: us-east-1
   use_iam_profile: true
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AWS',
             'region' => 'eu-central-1',
             'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
             'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
           }
           # OPTIONAL: The following lines are only needed if server side encryption is required
           gitlab_rails['object_store']['storage_options'] = {
             'server_side_encryption' => '<AES256 or aws:kms>',
             'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   If you're using [AWS IAM profiles](#use-amazon-instance-profiles), omit
   the AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AWS
         aws_access_key_id: <AWS_ACCESS_KEY_ID>
         aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
         region: eu-central-1
       storage_options:
         server_side_encryption: <AES256 or aws:kms>
         server_side_encryption_key_kms_id: <arn:aws:kms:xxx>
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

   If you're using [AWS IAM profiles](#use-amazon-instance-profiles), omit
   the AWS access key and secret access key/value pairs. For example:

   ```yaml
   connection:
     provider: AWS
     region: eu-central-1
     use_iam_profile: true
   ```

1. Edit `/home/git/gitlab-workhorse/config.toml` and add or amend the following lines:

   ```toml
   [object_storage]
     provider = "AWS"

   [object_storage.s3]
     aws_access_key_id = "<AWS_ACCESS_KEY_ID>"
     aws_secret_access_key = "<AWS_SECRET_ACCESS_KEY>"
   ```

   If you're using [AWS IAM profiles](#use-amazon-instance-profiles), omit
   the AWS access key and secret access key/value pairs. For example:

   ```yaml
   [object_storage.s3]
     use_iam_profile = true
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Migrate to object storage

To migrate existing local data to object storage see the following guides:

- [Job artifacts](cicd/job_artifacts.md#migrating-to-object-storage) including archived job logs
- [LFS objects](lfs/_index.md#migrating-to-object-storage)
- [Uploads](raketasks/uploads/migrate.md#migrate-to-object-storage)
- [Merge request diffs](merge_request_diffs.md#using-object-storage)
- [Packages](packages/_index.md#migrate-local-packages-to-object-storage) (optional feature)
- [Dependency Proxy](packages/dependency_proxy.md#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage)
- [Terraform state files](terraform_state.md#migrate-to-object-storage)
- [Pages content](pages/_index.md#migrate-pages-deployments-to-object-storage)
- [Project-level Secure Files](cicd/secure_files.md#migrate-to-object-storage)

## Transition to consolidated form

In storage-specific configuration:

- Object storage configuration for all types of objects such as CI/CD artifacts, LFS
  files, and upload attachments is configured independently.
- Object store connection parameters such as passwords and endpoint URLs is duplicated for each type.

For example, a Linux package installation might have the following configuration:

```ruby
# Original object storage configuration
gitlab_rails['artifacts_object_store_enabled'] = true
gitlab_rails['artifacts_object_store_direct_upload'] = true
gitlab_rails['artifacts_object_store_proxy_download'] = false
gitlab_rails['artifacts_object_store_remote_directory'] = 'artifacts'
gitlab_rails['artifacts_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_direct_upload'] = true
gitlab_rails['uploads_object_store_proxy_download'] = false
gitlab_rails['uploads_object_store_remote_directory'] = 'uploads'
gitlab_rails['uploads_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
```

Although this provides flexibility in that it makes it possible for GitLab
to store objects across different cloud providers, it also creates
additional complexity and unnecessary redundancy. Since both GitLab
Rails and Workhorse components need access to object storage, the
consolidated form avoids excessive duplication of credentials.

The consolidated form is used _only_ if all lines from
the original form is omitted. To move to the consolidated form, remove the
original configuration (for example, `artifacts_object_store_enabled`, or
`uploads_object_store_connection`)

## Migrate objects to a different object storage provider

You may need to migrate GitLab data in object storage to a different object storage provider. The following steps show you how do this using [Rclone](https://rclone.org/).

The steps assume you are moving the `uploads` bucket, but the same process works for other buckets.

Prerequisites:

- Choose the computer to run Rclone on. Depending on how much data you are migrating, Rclone may have to run for a long time so you should avoid using a laptop or desktop computer that can go into power saving. You can use your GitLab server to run Rclone.

1. [Install](https://rclone.org/downloads/) Rclone.
1. Configure Rclone by running the following:

   ```shell
   rclone config
   ```

   The configuration process is interactive. Add at least two "remotes": one for the object storage provider your data is currently on (`old`), and one for the provider you are moving to (`new`).

1. Verify that you can read the old data. The following example refers to the `uploads` bucket , but your bucket may have a different name:

   ```shell
   rclone ls old:uploads | head
   ```

   This should print a partial list of the objects currently stored in your `uploads` bucket. If you get an error, or if
   the list is empty, go back and update your Rclone configuration using `rclone config`.

1. Perform an initial copy. You do not need to take your GitLab server offline for this step.

   ```shell
   rclone sync -P old:uploads new:uploads
   ```

1. After the first sync completes, use the web UI or command-line interface of your new object storage provider to
   verify that there are objects in the new bucket. If there are none, or if you encounter an error while running
   `rclone sync`, check your Rclone configuration and try again.

After you have done at least one successful Rclone copy from the old location to the new location, schedule maintenance and take your GitLab server offline. During your maintenance window you must do two things:

1. Perform a final `rclone sync` run, knowing that your users cannot add new objects so you do not leave any behind in the old bucket.
1. Update the object storage configuration of your GitLab server to use the new provider for `uploads`.

## Alternatives to file system storage

If you're working to [scale out](reference_architectures/_index.md) your GitLab implementation,
or add fault tolerance and redundancy, you may be
looking at removing dependencies on block or network file systems.
See the following additional guides:

1. Make sure the [`git` user home directory](https://docs.gitlab.com/omnibus/settings/configuration.html#move-the-home-directory-for-a-user) is on local disk.
1. Configure [database lookup of SSH keys](operations/fast_ssh_key_lookup.md)
   to eliminate the need for a shared `authorized_keys` file.
1. [Prevent local disk usage for job logs](cicd/job_logs.md#prevent-local-disk-usage).
1. [Disable Pages local storage](pages/_index.md#disable-pages-local-storage).

## Troubleshooting

### Objects are not included in GitLab backups

As noted in [the backup documentation](backup_restore/backup_gitlab.md#object-storage),
objects are not included in GitLab backups. You can enable backups with
your object storage provider instead.

### Use separate buckets

Using separate buckets for each data type is the recommended approach for GitLab.
This ensures there are no collisions across the various types of data GitLab stores.
[Issue 292958](https://gitlab.com/gitlab-org/gitlab/-/issues/292958) proposes to enable the use of a single bucket.

With Linux package and self-compiled installations, it is possible to split a single
real bucket into multiple virtual buckets. If your object storage
bucket is called `my-gitlab-objects` you can configure uploads to go
into `my-gitlab-objects/uploads`, artifacts into
`my-gitlab-objects/artifacts`, etc. The application acts as if
these are separate buckets. Use of bucket prefixes
[may not work correctly with Helm backups](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376).

Helm-based installs require separate buckets to
[handle backup restorations](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy).

### S3 API compatibility issues

Not all S3 providers [are fully compatible](backup_restore/backup_gitlab.md#other-s3-providers)
with the Fog library that GitLab uses. Symptoms include an error in `production.log`:

```plaintext
411 Length Required
```

### Artifacts always downloaded with filename `download`

Downloaded artifact filenames are set with the `response-content-disposition` header in the
[GetObject request](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html).
If the S3 provider does not support this header, the downloaded file is always saved as `download`.

### Proxy Download

Clients can download files in object storage by receiving a pre-signed, time-limited URL,
or by GitLab proxying the data from object storage to the client.
Downloading files from object storage directly
helps reduce the amount of egress traffic GitLab
needs to process.

When the files are stored on local block storage or NFS, GitLab has to act as a proxy.
This is not the default behavior with object storage.

The `proxy_download` setting controls this behavior: the default is `false`.
Verify this in the documentation for each use case.

Set `proxy_download` to `true` if you want GitLab to proxy the files.
There can be a large performance hit to the GitLab server if `proxy_download` is set to `true`. The server deployments of GitLab have `proxy_download` set to `false`.

When `proxy_download` to `false`, GitLab returns an
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

- Object storage buckets need to allow Cross-Origin Resource Sharing
  (CORS) access from the URL of the GitLab instance. Attempting to load
  a PDF in the repository page may show the following error:

  ```plaintext
  An error occurred while loading the file. Please try again later.
  ```

  See [the LFS documentation](lfs/_index.md#error-viewing-a-pdf-file) for more details.

Additionally for a short time period users could share pre-signed, time-limited object storage URLs
with others without authentication. Also bandwidth charges may be incurred
between the object storage provider and the client.

### ETag mismatch

Using the default GitLab settings, some object storage back-ends such as
[MinIO](https://gitlab.com/gitlab-org/gitlab/-/issues/23188)
and [Alibaba](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564)
might generate `ETag mismatch` errors.

#### Amazon S3 encryption

If you are seeing this ETag mismatch error with Amazon Web Services S3,
it's likely this is due to [encryption settings on your bucket](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonResponseHeaders.html).
To fix this issue, you have two options:

- [Use the consolidated form](#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
- [Use Amazon instance profiles](#use-amazon-instance-profiles).

The first option is recommended for MinIO. Otherwise, the
[workaround for MinIO](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564#note_244497658)
is to use the `--compat` parameter on the server.

Without the consolidated form or instance profiles enabled,
GitLab Workhorse uploads files to S3 using pre-signed URLs that do
not have a `Content-MD5` HTTP header computed for them. To ensure data
is not corrupted, Workhorse checks that the MD5 hash of the data sent
equals the ETag header returned from the S3 server. When encryption is
enabled, this is not the case, which causes Workhorse to report an `ETag mismatch`
error during an upload.

When the consolidated form is:

- Used with an S3-compatible object storage or an instance profile, Workhorse
  uses its internal S3 client which has S3 credentials so that it can compute
  the `Content-MD5` header. This eliminates the need to compare ETag headers
  returned from the S3 server.
- Not used with an S3-compatible object storage, Workhorse falls back to using
  pre-signed URLs.

#### Google Cloud Storage encryption

> - [Introduced in GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/issues/441782).

ETag mismatch errors occur also in Google Cloud Storage (GCS) when enabling [data encryption with customer-managed encryption keys (CMEK)](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys).

To use CMEK, use the [consolidated form](#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

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

### Manual testing through Rails Console

In some situations, it may be helpful to test object storage settings using the Rails Console. The following example tests a given set of connection settings, attempts to write a test object, and finally read it.

1. Start a [Rails console](operations/rails_console.md).
1. Set up the object storage connection, using the same parameters you set up in `/etc/gitlab/gitlab.rb`, in the following example format:

   Example connection using access keys:

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       region: `eu-central-1`,
       aws_access_key_id: '<AWS_ACCESS_KEY_ID>',
       aws_secret_access_key: '<AWS_SECRET_ACCESS_KEY>'
     }
   )
   ```

   Example connection using AWS IAM Profiles:

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       use_iam_profile: true,
       region: 'us-east-1'
     }
   )
   ```

1. Specify the bucket name to test against, write, and finally read a test file.

   ```ruby
   dir = connection.directories.new(key: '<bucket-name-here>')
   f = dir.files.create(key: 'test.txt', body: 'test')
   pp f
   pp dir.files.head('test.txt')
   ```
