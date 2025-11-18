---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bundle URIs
---

{{< details >}}

Tier: Free, Premium, Ultimate

Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8939) in GitLab 17.0 [with a flag](../feature_flags/_index.md) named `gitaly_bundle_uri`. Disabled by default.

{{< /history >}}

Gitaly supports Git [bundle URIs](https://git-scm.com/docs/bundle-uri). Bundle
URIs are locations where Git can download one or more bundles to bootstrap the
object database before fetching the remaining objects from a remote. Bundle URIs
are built in to the Git protocol.

Using Bundle URIs can:

- Speed up clones and fetches for users with a poor network connection to the
  GitLab server. The bundles can be stored on a CDN, making them available
  around the world.
- Reduce the load on servers that run CI/CD jobs. If CI/CD jobs can pre-load
  bundles from somewhere else, the remaining work to incrementally fetch missing
  objects and references creates a lot less load on the server.

## Prerequisites

The prerequisites for using bundle URI depend on whether cloning in a CI/CD job or locally in a terminal.

### Cloning in CI/CD jobs

To prepare to use bundle URI in CI/CD jobs:

1. Select a [GitLab Runner helper image](https://gitlab.com/gitlab-org/gitlab-runner/container_registry/1472754) used
   by GitLab Runner to a version that runs:

   - Git version 2.49.0 or later.
   - GitLab Runner helper version 18.0 or later.

   This step is required because bundle URI is a mechanism that aims to reduce the load on the Git
   server during a `git clone`. Therefore, when a CI/CD pipeline runs, the `git` client that initiates the `git clone` command is the GitLab Runner. The `git` process runs inside the
   helper image.

   Make sure to select an image that corresponds to the operating system distribution and the architecture you use for your GitLab
   runners.

   You can verify that the image satisfies the requirements by running these commands:

   ```shell
   docker run -it <image:tag>
   $ git version
   $ gitlab-runner-helper -v
   ```

   We rely on the operating system distribution's package manager to manage the Git version in the
   `gitlab-runner-helper` image. Therefore, some of the latest available images might still not run Git 2.49.

   If you do not find an image that meets the requirements, use the `gitlab-runner-helper` as a base image for your own
   custom-built image. You can host on your custom-build image by using
   [GitLab container registry](../../user/packages/container_registry/_index.md).

1. Configure your GitLab Runner instances to use the select image by updating your `config.toml` file:

   ```toml
   [[runners]]
     (...)
     executor = "docker"
     [runners.docker]
       (...)
       helper_image = "image:tag" ## <-- put the image name and tag here
   ```

    For more details, see [information on the helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image).

1. Restart the runners for the new configuration to take effect.
1. Enable the `FF_USE_GIT_NATIVE_CLONE` [GitLab Runner feature flag](https://docs.gitlab.com/runner/configuration/feature-flags/)
   in your `.gitlab-ci.yml` file by setting it `true` :

   ```yaml
   variables:
     FF_USE_GIT_NATIVE_CLONE: "true"
   ```

### Cloning locally in your terminal

To prepare to use bundle URI for cloning locally in your terminal, enable `bundle-uri` in your local Git configuration:

```shell
git config --global transfer.bundleuri true
```

## Server configuration

You must configure where the bundles are stored. Gitaly supports the following
storage services:

- Google Cloud Storage
- AWS S3 (or compatible)
- Azure Blob Storage
- Local file storage (not recommended)

### Configure Azure Blob storage

How you configure Azure Blob storage for Bundle URI depends on the type of
installation you have. For self-compiled installations, you must set the
`AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY` environment variables outside of
GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Edit `/etc/gitlab/gitlab.rb` and configure the `bundle_uri.go_cloud_url`:

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Configure Google Cloud storage

Google Cloud storage (GCP) authenticates using Application Default Credentials.
Set up Application Default Credentials on each Gitaly server using either:

- The [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)
  command.
- The `GOOGLE_APPLICATION_CREDENTIALS` environment variable. For self-compiled
  installations, set the environment variable outside of GitLab.

For more information, see
[Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc).

The destination bucket is configured using the `go_cloud_url` option.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Configure S3 storage

To configure S3 storage authentication:

- If you authenticate with the AWS CLI, you can use the default AWS session.
- Otherwise, you can use the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  environment variables. For self-compiled installations, set the environment
  variables outside of GitLab.

For more information, see
[AWS Session documentation](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/).

The destination bucket and region are configured using the `go_cloud_url` option.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### Configure S3-compatible servers

{{< history >}}

- `use_path_style` and `disable_https` parameters [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8939) in GitLab 17.4.

{{< /history >}}

S3-compatible servers such as MinIO are configured similarly to S3 with the
addition of the `endpoint` parameter.

The following parameters are supported:

- `region`: The AWS region.
- `endpoint`: The endpoint URL.
- `disableSSL`: Set to `true` to disable SSL. Available for GitLab 17.4.0 and earlier. For GitLab versions after 17.4.0, use `disable_https`.
- `disable_https`: Set to `true` to disable HTTPS in the endpoint options.
- `s3ForcePathStyle`: Set to `true` to force path-style URLs for S3 objects. Unavailable in GitLab versions 17.4.0 to 17.4.3. In those versions, use `use_path_style` instead.
- `use_path_style`: Set to `true` to enable path-style S3 URLs (`https://<host>/<bucket>` instead of `https://<bucket>.<host>`).
- `awssdk`: Force a particular version of AWS SDK. Set to `v1` to force AWS SDK v1 or `v2` to force AWS SDK v2. If:
  - Set to `v1`, you must use `disableSSL` instead of `disable_https`.
  - Not set, defaults to `v2`.

`use_path_style` was introduced when the Go Cloud Development Kit dependency was updated from v0.38.0 to v0.39.0, which switched from AWS SDK v1 to v2. However, the `s3ForcePathStyle` parameter was restored in GitLab 17.4.4 after the gocloud.dev maintainers added backward compatibility support. For more information, see [issue 6489](https://gitlab.com/gitlab-org/gitaly/-/issues/6489).

`disable_https` was introduced in the Go Cloud Development Kit v0.40.0 (AWS SDK v2).

`awssdk` was introduced in the Go Cloud Development Kit v0.24.0.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'minio_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'minio_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=minio&endpoint=my.minio.local:8080&disable_https=true&use_path_style=true'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=minio&endpoint=my.minio.local:8080&disable_https=true&use_path_style=true"
```

{{< /tab >}}

{{< /tabs >}}

## Generating bundles

After Gitaly is configured, Gitaly can generate bundles either manually or automatically.

### Manual generation

This command generates the bundle and stores it on the configured storage service.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly bundle-uri \
                                               --config=<config-file> \
                                               --storage=<storage-name> \
                                               --repository=<relative-path>
```

Gitaly does not automatically refresh the generated bundle. When you want to generate
a more recent version of a bundle, you must run the command again.

You can schedule this command with a tool like `cron(8)`.

### Automatic generation

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16007) in GitLab 18.0 [with a flag](../feature_flags/_index.md) named `gitaly_bundle_generation`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Gitaly can generate bundles automatically by determining if it is handling frequent clones for the same repository.
The current heuristic keeps track of the number of times a `git fetch` request is issued for each repository. If the
number of requests reaches a certain threshold in a given interval, Gitaly automatically generates a bundle.

Gitaly also keeps track of the last time it generated a bundle for a repository. When a new bundle should be regenerated,
based on the `threshold` and `interval`, Gitaly looks at the last time a bundle was generated for the given repository.
Gitaly only generates a new bundle if the existing bundle is older than `maxBundleAge` configuration, in which case the
old bundle is overwritten. There can only be one bundle per repository in cloud storage.

## Bundle URI example

In the following example, we demonstrate the difference between cloning
`gitlab.com/gitlab-org/gitlab.git` with and without using bundle URI.

```shell
$ git -c transfer.bundleURI=false clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 5271177, done.
remote: Total 5271177 (delta 0), reused 0 (delta 0), pack-reused 5271177
Receiving objects: 100% (5271177/5271177), 1.93 GiB | 32.93 MiB/s, done.
Resolving deltas: 100% (4140349/4140349), done.
Updating files: 100% (71304/71304), done.

$ git -c transfer.bundleURI=true clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 1322255, done.
remote: Counting objects: 100% (611708/611708), done.
remote: Total 1322255 (delta 611708), reused 611708 (delta 611708), pack-reused 710547
Receiving objects: 100% (1322255/1322255), 539.66 MiB | 22.98 MiB/s, done.
Resolving deltas: 100% (1026890/1026890), completed with 223946 local objects.
Checking objects: 100% (8388608/8388608), done.
Checking connectivity: 1381139, done.
Updating files: 100% (71304/71304), done.
```

In the previous example:

- When not using a Bundle URI, there were 5,271,177 objects received from the
  GitLab server.
- When using a Bundle URI, there were 1,322,255 objects received from the GitLab
  server.

This reduction means GitLab needs to pack together fewer objects (in the previous
example, roughly a quarter of the number of objects) because the client first
downloaded the bundle from the storage server.

## Securing bundles

The bundles are made accessible to the client using signed URLs. A signed URL is
a URL that provides limited permissions and time to make a request. To see if
your storage service supports signed URLs, see the documentation of your storage
service.
