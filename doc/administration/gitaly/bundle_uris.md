---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bundle URIs
---

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8939) in GitLab 17.0 [with a flag](../feature_flags.md) named `gitaly_bundle_uri`. Disabled by default.

FLAG:
On GitLab Self-Managed, by default this feature is not available.
To make it available, an administrator can [enable the feature flag](../feature_flags.md)
named `gitaly_bundle_uri`.
On GitLab.com and GitLab Dedicated, this feature is not available. This feature
is not ready for production use.

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

- The Git configuration [`transfer.bundleURI`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-transferbundleURI)
  must be enabled on Git clients.
- GitLab Runner 16.6 or later.
- In CI/CD pipeline configuration, the
  [default Git strategy](../../ci/pipelines/settings.md#choose-the-default-git-strategy) set to `git clone`.

## Server configuration

You must configure where the bundles are stored. Gitaly supports the following
storage services:

- Google Cloud Storage
- AWS S3 (or compatible)
- Azure Blob Storage
- Local file storage (**not recommended**)

### Configure Azure Blob storage

How you configure Azure Blob storage for Bundle URI depends on the type of
installation you have. For self-compiled installations, you must set the
`AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY` environment variables outside of
GitLab.

::Tabs

:::TabTitle Linux package (Omnibus)

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

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "azblob://<bucket>"
```

::EndTabs

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

::Tabs

:::TabTitle Linux package (Omnibus)

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

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "gs://<bucket>"
```

::EndTabs

### Configure S3 storage

To configure S3 storage authentication:

- If you authenticate with the AWS CLI, you can use the default AWS session.
- Otherwise, you can use the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  environment variables. For self-compiled installations, set the environment
  variables outside of GitLab.

For more information, see
[AWS Session documentation](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/).

The destination bucket and region are configured using the `go_cloud_url` option.

::Tabs

:::TabTitle Linux package (Omnibus)

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

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

::EndTabs

#### Configure S3-compatible servers

S3-compatible servers such as MinIO are configured similarly to S3 with the
addition of the `endpoint` parameter.

The following parameters are supported:

- `region`: The AWS region.
- `endpoint`: The endpoint URL.
- `disabledSSL`: A value of `true` disables SSL.
- `s3ForcePathStyle`: A value of `true` forces path-style addressing.

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'minio_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'minio_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true"
```

::EndTabs

## Generating bundles

After Gitaly is properly configured, Gitaly can generate bundles, which is a
manual process. To generate a bundle for Bundle URI, run:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly bundle-uri \
                                               --config=<config-file> \
                                               --storage=<storage-name> \
                                               --repository=<relative-path>
```

This command generates the bundle and stores it on the configured storage service.
Gitaly does not automatically refresh the generated bundle. When you want to generate
a more recent version of a bundle, you must run the command again.

You can schedule this command with a tool like `cron(8)`.

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

In the above example:

- When not using a Bundle URI, there were 5,271,177 objects received from the
  GitLab server.
- When using a Bundle URI, there were 1,322,255 objects received from the GitLab
  server.

This reduction means GitLab needs to pack together fewer objects (in the above
example, roughly a quarter of the number of objects) because the client first
downloaded the bundle from the storage server.

## Securing bundles

The bundles are made accessible to the client using signed URLs. A signed URL is
a URL that provides limited permissions and time to make a request. To see if
your storage service supports signed URLs, see the documentation of your storage
service.
