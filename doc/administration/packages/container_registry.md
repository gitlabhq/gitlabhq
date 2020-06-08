---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Container Registry administration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/4040) in GitLab 8.8.
> - Container Registry manifest `v1` support was added in GitLab 8.9 to support
>   Docker versions earlier than 1.10.

NOTE: **Note:**
This document is the administrator's guide. To learn how to use GitLab Container
Registry, see the [user documentation](../../user/packages/container_registry/index.md).

With the Container Registry integrated into GitLab, every project can have its
own space to store its Docker images.

You can read more about the Docker Registry at
<https://docs.docker.com/registry/introduction/>.

## Enable the Container Registry

**Omnibus GitLab installations**

If you installed GitLab by using the Omnibus installation package, the Container Registry
may or may not be available by default.

The Container Registry is automatically enabled and available on your GitLab domain, port 5050 if:

- You're using the built-in [Let's Encrypt integration](https://docs.gitlab.com/omnibus/settings/ssl.html#lets-encrypt-integration), and
- You're using GitLab 12.5 or later.

Otherwise, the Container Registry is not enabled. To enable it:

- You can configure it for your [GitLab domain](#configure-container-registry-under-an-existing-gitlab-domain), or
- You can configure it for [a different domain](#configure-container-registry-under-its-own-domain).

NOTE: **Note:**
The Container Registry works under HTTPS by default. You can use HTTP
but it's not recommended and is out of the scope of this document.
Read the [insecure Registry documentation](https://docs.docker.com/registry/insecure/)
if you want to implement this.

**Installations from source**

If you have installed GitLab from source:

1. You will have to [install Registry](https://docs.docker.com/registry/deploying/) by yourself.
1. After the installation is complete, you will have to configure the Registry's
   settings in `gitlab.yml` in order to enable it.
1. Use the sample NGINX configuration file that is found under
   [`lib/support/nginx/registry-ssl`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/support/nginx/registry-ssl) and edit it to match the
   `host`, `port` and TLS certs paths.

The contents of `gitlab.yml` are:

```yaml
registry:
  enabled: true
  host: registry.gitlab.example.com
  port: 5005
  api_url: http://localhost:5000/
  key: config/registry.key
  path: shared/registry
  issuer: gitlab-issuer
```

where:

| Parameter | Description |
| --------- | ----------- |
| `enabled` | `true` or `false`. Enables the Registry in GitLab. By default this is `false`. |
| `host`    | The host URL under which the Registry will run and the users will be able to use. |
| `port`    | The port under which the external Registry domain will listen on. |
| `api_url` | The internal API URL under which the Registry is exposed to. It defaults to `http://localhost:5000`. |
| `key`     | The private key location that is a pair of Registry's `rootcertbundle`. Read the [token auth configuration documentation](https://docs.docker.com/registry/configuration/#token). |
| `path`    | This should be the same directory like specified in Registry's `rootdirectory`. Read the [storage configuration documentation](https://docs.docker.com/registry/configuration/#storage). This path needs to be readable by the GitLab user, the web-server user and the Registry user. Read more in [#container-registry-storage-path](#container-registry-storage-path). |
| `issuer`  | This should be the same value as configured in Registry's `issuer`. Read the [token auth configuration documentation](https://docs.docker.com/registry/configuration/#token). |

NOTE: **Note:**
A Registry init file is not shipped with GitLab if you install it from source.
Hence, [restarting GitLab](../restart_gitlab.md#installations-from-source) will not restart the Registry should
you modify its settings. Read the upstream documentation on how to achieve that.

At the **absolute** minimum, make sure your [Registry configuration](https://docs.docker.com/registry/configuration/#auth)
has `container_registry` as the service and `https://gitlab.example.com/jwt/auth`
as the realm:

```yaml
auth:
  token:
    realm: https://gitlab.example.com/jwt/auth
    service: container_registry
    issuer: gitlab-issuer
    rootcertbundle: /root/certs/certbundle
```

CAUTION: **Caution:**
If `auth` is not set up, users will be able to pull Docker images without authentication.

## Container Registry domain configuration

There are two ways you can configure the Registry's external domain. Either:

- [Use the existing GitLab domain](#configure-container-registry-under-an-existing-gitlab-domain) where in that case
  the Registry will have to listen on a port and reuse GitLab's TLS certificate,
- [Use a completely separate domain](#configure-container-registry-under-its-own-domain) with a new TLS certificate
  for that domain.

Since the container Registry requires a TLS certificate, in the end it all boils
down to how easy or pricey it is to get a new one.

Please take this into consideration before configuring the Container Registry
for the first time.

### Configure Container Registry under an existing GitLab domain

If the Registry is configured to use the existing GitLab domain, you can
expose the Registry on a port so that you can reuse the existing GitLab TLS
certificate.

Assuming that the GitLab domain is `https://gitlab.example.com` and the port the
Registry is exposed to the outside world is `5050`, here is what you need to set
in `gitlab.rb` or `gitlab.yml` if you are using Omnibus GitLab or installed
GitLab from source respectively.

NOTE: **Note:**
Be careful to choose a port different than the one that Registry listens to (`5000` by default),
otherwise you will run into conflicts.

**Omnibus GitLab installations**

1. Your `/etc/gitlab/gitlab.rb` should contain the Registry URL as well as the
   path to the existing TLS certificate and key used by GitLab:

   ```ruby
   registry_external_url 'https://gitlab.example.com:5050'
   ```

   Note how the `registry_external_url` is listening on HTTPS under the
   existing GitLab URL, but on a different port.

   If your TLS certificate is not in `/etc/gitlab/ssl/gitlab.example.com.crt`
   and key not in `/etc/gitlab/ssl/gitlab.example.com.key` uncomment the lines
   below:

   ```ruby
   registry_nginx['ssl_certificate'] = "/path/to/certificate.pem"
   registry_nginx['ssl_certificate_key'] = "/path/to/certificate.key"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

1. Validate using:

   ```shell
   openssl s_client -showcerts -servername gitlab.example.com -connect gitlab.example.com:5050 > cacert.pem
   ```

NOTE: **Note:**
If your certificate provider provides the CA Bundle certificates, append them to the TLS certificate file.

**Installations from source**

1. Open `/home/git/gitlab/config/gitlab.yml`, find the `registry` entry and
   configure it with the following settings:

   ```yaml
   registry:
     enabled: true
     host: gitlab.example.com
     port: 5050
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.
1. Make the relevant changes in NGINX as well (domain, port, TLS certificates path).

Users should now be able to login to the Container Registry with their GitLab
credentials using:

```shell
docker login gitlab.example.com:5050
```

### Configure Container Registry under its own domain

If the Registry is configured to use its own domain, you will need a TLS
certificate for that specific domain (e.g., `registry.example.com`) or maybe
a wildcard certificate if hosted under a subdomain of your existing GitLab
domain (e.g., `registry.gitlab.example.com`).

NOTE: **Note:**
As well as manually generated SSL certificates (explained here), certificates automatically
generated by Let's Encrypt are also [supported in Omnibus installs](https://docs.gitlab.com/omnibus/settings/ssl.html#host-services).

Let's assume that you want the container Registry to be accessible at
`https://registry.gitlab.example.com`.

**Omnibus GitLab installations**

1. Place your TLS certificate and key in
   `/etc/gitlab/ssl/registry.gitlab.example.com.crt` and
   `/etc/gitlab/ssl/registry.gitlab.example.com.key` and make sure they have
   correct permissions:

   ```shell
   chmod 600 /etc/gitlab/ssl/registry.gitlab.example.com.*
   ```

1. Once the TLS certificate is in place, edit `/etc/gitlab/gitlab.rb` with:

   ```ruby
   registry_external_url 'https://registry.gitlab.example.com'
   ```

   Note how the `registry_external_url` is listening on HTTPS.

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

If you have a [wildcard certificate](https://en.wikipedia.org/wiki/Wildcard_certificate), you need to specify the path to the
certificate in addition to the URL, in this case `/etc/gitlab/gitlab.rb` will
look like:

```ruby
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/certificate.pem"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/certificate.key"
```

**Installations from source**

1. Open `/home/git/gitlab/config/gitlab.yml`, find the `registry` entry and
   configure it with the following settings:

   ```yaml
   registry:
     enabled: true
     host: registry.gitlab.example.com
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.
1. Make the relevant changes in NGINX as well (domain, port, TLS certificates path).

Users should now be able to login to the Container Registry using their GitLab
credentials:

```shell
docker login registry.gitlab.example.com
```

## Disable Container Registry site-wide

NOTE: **Note:**
Disabling the Registry in the Rails GitLab application as set by the following
steps, will not remove any existing Docker images. This is handled by the
Registry application itself.

**Omnibus GitLab**

1. Open `/etc/gitlab/gitlab.rb` and set `registry['enable']` to `false`:

   ```ruby
   registry['enable'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. Open `/home/git/gitlab/config/gitlab.yml`, find the `registry` entry and
   set `enabled` to `false`:

   ```yaml
   registry:
     enabled: false
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Disable Container Registry for new projects site-wide

If the Container Registry is enabled, then it will be available on all new
projects. To disable this function and let the owners of a project to enable
the Container Registry by themselves, follow the steps below.

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_default_projects_features_container_registry'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. Open `/home/git/gitlab/config/gitlab.yml`, find the `default_projects_features`
   entry and configure it so that `container_registry` is set to `false`:

   ```yaml
   ## Default project features settings
   default_projects_features:
     issues: true
     merge_requests: true
     wiki: true
     snippets: false
     builds: true
     container_registry: false
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Container Registry storage path

NOTE: **Note:**
For configuring storage in the cloud instead of the filesystem, see the
[storage driver configuration](#container-registry-storage-driver).

If you want to store your images on the filesystem, you can change the storage
path for the Container Registry, follow the steps below.

This path is accessible to:

- The user running the Container Registry daemon.
- The user running GitLab.

CAUTION: **Warning** You should confirm that all GitLab, Registry and web server users
have access to this directory.

**Omnibus GitLab installations**

The default location where images are stored in Omnibus, is
`/var/opt/gitlab/gitlab-rails/shared/registry`. To change it:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['registry_path'] = "/path/to/registry/storage"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

The default location where images are stored in source installations, is
`/home/git/gitlab/shared/registry`. To change it:

1. Open `/home/git/gitlab/config/gitlab.yml`, find the `registry` entry and
   change the `path` setting:

   ```yaml
   registry:
     path: shared/registry
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Container Registry storage driver

You can configure the Container Registry to use a different storage backend by
configuring a different storage driver. By default the GitLab Container Registry
is configured to use the filesystem driver, which makes use of [storage path](#container-registry-storage-path)
configuration.

The different supported drivers are:

| Driver     | Description                         |
|------------|-------------------------------------|
| filesystem | Uses a path on the local filesystem |
| Azure      | Microsoft Azure Blob Storage        |
| gcs        | Google Cloud Storage                |
| s3         | Amazon Simple Storage Service. Be sure to configure your storage bucket with the correct [S3 Permission Scopes](https://docs.docker.com/registry/storage-drivers/s3/#s3-permission-scopes). |
| swift      | OpenStack Swift Object Storage      |
| oss        | Aliyun OSS                          |

Read more about the individual driver's configuration options in the
[Docker Registry docs](https://docs.docker.com/registry/configuration/#storage).

[Read more about using object storage with GitLab](../object_storage.md).

CAUTION: **Warning:** GitLab will not backup Docker images that are not stored on the
filesystem. Remember to enable backups with your object storage provider if
desired.

NOTE: **Note:**
`regionendpoint` is only required when configuring an S3 compatible service such as MinIO. It takes a URL such as `http://127.0.0.1:9000`.

**Omnibus GitLab installations**

To configure the `s3` storage driver in Omnibus:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['storage'] = {
     's3' => {
       'accesskey' => 's3-access-key',
       'secretkey' => 's3-secret-key-for-access-key',
       'bucket' => 'your-s3-bucket',
       'region' => 'your-s3-region',
       'regionendpoint' => 'your-s3-regionendpoint'
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

NOTE: **Note:**
`your-s3-bucket` should only be the name of a bucket that exists, and can't include subdirectories.

**Installations from source**

Configuring the storage driver is done in your registry configuration YML file created
when you [deployed your Docker registry](https://docs.docker.com/registry/deploying/).

`s3` storage driver example:

```yaml
storage:
  s3:
    accesskey: 's3-access-key'
    secretkey: 's3-secret-key-for-access-key'
    bucket: 'your-s3-bucket'
    region: 'your-s3-region'
    regionendpoint: 'your-s3-regionendpoint'
  cache:
    blobdescriptor: inmemory
  delete:
    enabled: true
```

NOTE: **Note:**
`your-s3-bucket` should only be the name of a bucket that exists, and can't include subdirectories.

**Migrate without downtime**

To migrate the data to AWS S3 without downtime:

1. To reduce the amount of data to be migrated, run the [garbage collection tool without downtime](#performing-garbage-collection-without-downtime). Part of this process sets the registry to `read-only`.
1. Copy the data to your AWS S3 bucket, for example with [AWS CLI's `cp`](https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html) command.
1. Configure your registry to use the S3 bucket for storage.
1. Put the registry back to `read-write`.
1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

### Disable redirect for storage driver

By default, users accessing a registry configured with a remote backend are redirected to the default backend for the storage driver. For example, registries can be configured using the `s3` storage driver, which redirects requests to a remote S3 bucket to alleviate load on the GitLab server.

However, this behavior is undesirable for registries used by internal hosts that usually can't access public servers. To disable redirects, set the `disable` flag to true as follows. This makes all traffic to always go through the Registry service. This results in improved security (less surface attack as the storage backend is not publicly accessible), but worse performance (all traffic is redirected via the service).

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    registry['storage'] = {
      's3' => {
        'accesskey' => 's3-access-key',
        'secretkey' => 's3-secret-key-for-access-key',
        'bucket' => 'your-s3-bucket',
        'region' => 'your-s3-region',
        'regionendpoint' => 'your-s3-regionendpoint'
      },
      'redirect' => {
        'disable' => true
      }
    }
    ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. Add the `redirect` flag to your registry configuration YML file:

    ```yaml
    storage:
      s3:
        accesskey: 'AKIAKIAKI'
        secretkey: 'secret123'
        bucket: 'gitlab-registry-bucket-AKIAKIAKI'
        region: 'your-s3-region'
        regionendpoint: 'your-s3-regionendpoint'
      redirect:
        disable: true
      cache:
        blobdescriptor: inmemory
      delete:
        enabled: true
    ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Storage limitations

Currently, there is no storage limitation, which means a user can upload an
infinite amount of Docker images with arbitrary sizes. This setting will be
configurable in future releases.

## Change the registry's internal port

NOTE: **Note:**
This is not to be confused with the port that GitLab itself uses to expose
the Registry to the world.

The Registry server listens on localhost at port `5000` by default,
which is the address for which the Registry server should accept connections.
In the examples below we set the Registry's port to `5001`.

**Omnibus GitLab**

1. Open `/etc/gitlab/gitlab.rb` and set `registry['registry_http_addr']`:

   ```ruby
   registry['registry_http_addr'] = "localhost:5001"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

1. Open the configuration file of your Registry server and edit the
   [`http:addr`](https://docs.docker.com/registry/configuration/#http) value:

   ```yaml
   http
     addr: localhost:5001
   ```

1. Save the file and restart the Registry server.

## Disable Container Registry per project

If Registry is enabled in your GitLab instance, but you don't need it for your
project, you can disable it from your project's settings. Read the user guide
on how to achieve that.

## Use an external container registry with GitLab as an auth endpoint

NOTE: **Note:**
In using an external container registry, some features associated with the
container registry may be unavailable or have [inherent risks](./../../user/packages/container_registry/index.md#use-with-external-container-registries)

**Omnibus GitLab**

You can use GitLab as an auth endpoint with an external container registry.

1. Open `/etc/gitlab/gitlab.rb` and set necessary configurations:

   ```ruby
   gitlab_rails['registry_enabled'] = true
   gitlab_rails['registry_api_url'] = "http://localhost:5000"
   gitlab_rails['registry_issuer'] = "omnibus-gitlab-issuer"
   ```

   NOTE: **Note:**
   `gitlab_rails['registry_enabled'] = true` is needed to enable GitLab's
   Container Registry features and authentication endpoint. GitLab's bundled
   Container Registry service will not be started even with this enabled.

1. A certificate-key pair is required for GitLab and the external container
   registry to communicate securely. You will need to create a certificate-key
   pair, configuring the external container registry with the public
   certificate and configuring GitLab with the private key. To do that, add
   the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   # registry['internal_key'] should contain the contents of the custom key
   # file. Line breaks in the key file should be marked using `\n` character
   # Example:
   registry['internal_key'] = "---BEGIN RSA PRIVATE KEY---\nMIIEpQIBAA\n"

   # Optionally define a custom file for Omnibus GitLab to write the contents
   # of registry['internal_key'] to.
   gitlab_rails['registry_key_path'] = "/custom/path/to/registry-key.key"
   ```

   NOTE: **Note:**
   The file specified at `registry_key_path` gets populated with the
   content specified by `internal_key`, each time reconfigure is executed. If
   no file is specified, Omnibus GitLab will default it to
   `/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key` and will populate
   it.

1. To change the container registry URL displayed in the GitLab Container
   Registry pages, set the following configurations:

   ```ruby
   gitlab_rails['registry_host'] = "registry.gitlab.example.com"
   gitlab_rails['registry_port'] = "5005"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

**Installations from source**

1. Open `/home/git/gitlab/config/gitlab.yml`, and edit the configuration settings under `registry`:

   ```yaml
   ## Container Registry

   registry:
     enabled: true
     host: "registry.gitlab.example.com"
     port: "5005"
     api_url: "http://localhost:5000"
     path: /var/opt/gitlab/gitlab-rails/shared/registry
     key: /var/opt/gitlab/gitlab-rails/certificate.key
     issuer: omnibus-gitlab-issuer
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Configure Container Registry notifications

You can configure the Container Registry to send webhook notifications in
response to events happening within the registry.

Read more about the Container Registry notifications configuration options in the
[Docker Registry notifications documentation](https://docs.docker.com/registry/notifications/).

NOTE: **Note:**
Multiple endpoints can be configured for the Container Registry.

**Omnibus GitLab installations**

To configure a notification endpoint in Omnibus:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['notifications'] = [
     {
       'name' => 'test_endpoint',
       'url' => 'https://gitlab.example.com/notify',
       'timeout' => '500ms',
       'threshold' => 5,
       'backoff' => '1s',
       'headers' => {
         "Authorization" => ["AUTHORIZATION_EXAMPLE_TOKEN"]
       }
     }
   ]
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Installations from source**

Configuring the notification endpoint is done in your registry configuration YML file created
when you [deployed your Docker registry](https://docs.docker.com/registry/deploying/).

Example:

```yaml
notifications:
  endpoints:
    - name: alistener
      disabled: false
      url: https://my.listener.com/event
      headers: <http.Header>
      timeout: 500
      threshold: 5
      backoff: 1000
```

## Container Registry garbage collection

NOTE: **Note:**
The garbage collection tools are only available when you've installed GitLab
via an Omnibus package or the [cloud native chart](https://docs.gitlab.com/charts/charts/registry/#garbage-collection).

DANGER: **Danger:**
By running the built-in garbage collection command, it will cause downtime to
the Container Registry. If you run this command on an instance in an environment
where one of your other instances is still writing to the Registry storage,
referenced manifests will be removed. To avoid that, make sure Registry is set to
[read-only mode](#performing-garbage-collection-without-downtime) before proceeding.

Container Registry can use considerable amounts of disk space. To clear up
some unused layers, the registry includes a garbage collect command.

GitLab offers a set of APIs to manipulate the Container Registry and aid the process
of removing unused tags. Currently, this is exposed using the API, but in the future,
these controls will be migrated to the GitLab interface.

Project maintainers can
[delete Container Registry tags in bulk](../../api/container_registry.md#delete-registry-repository-tags-in-bulk)
periodically based on their own criteria, however, this alone does not recycle data,
it only unlinks tags from manifests and image blobs. To recycle the Container
Registry data in the whole GitLab instance, you can use the built-in command
provided by `gitlab-ctl`.

### Understanding the content-addressable layers

Consider the following example, where you first build the image:

```shell
# This builds a image with content of sha256:111111
docker build -t my.registry.com/my.group/my.project:latest .
docker push my.registry.com/my.group/my.project:latest
```

Now, you do overwrite `:latest` with a new version:

```shell
# This builds a image with content of sha256:222222
docker build -t my.registry.com/my.group/my.project:latest .
docker push my.registry.com/my.group/my.project:latest
```

Now, the `:latest` tag points to manifest of `sha256:222222`. However, due to
the architecture of registry, this data is still accessible when pulling the
image `my.registry.com/my.group/my.project@sha256:111111`, even though it is
no longer directly accessible via the `:latest` tag.

### Recycling unused tags

There are a couple of considerations you need to note before running the
built-in command:

- The built-in command will stop the registry before it starts the garbage collection.
- The garbage collect command takes some time to complete, depending on the
  amount of data that exists.
- If you changed the location of registry configuration file, you will need to
  specify its path.
- After the garbage collection is done, the registry should start up automatically.

If you did not change the default location of the configuration file, run:

```shell
sudo gitlab-ctl registry-garbage-collect
```

This command will take some time to complete, depending on the amount of
layers you have stored.

If you changed the location of the Container Registry `config.yml`:

```shell
sudo gitlab-ctl registry-garbage-collect /path/to/config.yml
```

You may also [remove all unreferenced manifests](#removing-unused-layers-not-referenced-by-manifests),
although this is a way more destructive operation, and you should first
understand the implications.

### Removing unused layers not referenced by manifests

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/3097) in Omnibus GitLab 11.10.

DANGER: **Danger:**
This is a destructive operation.

The GitLab Container Registry follows the same default workflow as Docker Distribution:
retain all layers, even ones that are unreferenced directly to allow all content
to be accessed using context addressable identifiers.

However, in most workflows, you don't care about old layers if they are not directly
referenced by the registry tag. The `registry-garbage-collect` command supports the
`-m` switch to allow you to remove all unreferenced manifests and layers that are
not directly accessible via `tag`:

```shell
sudo gitlab-ctl registry-garbage-collect -m
```

Since this is a way more destructive operation, this behavior is disabled by default.
You are likely expecting this way of operation, but before doing that, ensure
that you have backed up all registry data.

### Performing garbage collection without downtime

You can perform a garbage collection without stopping the Container Registry by setting
it into a read-only mode and by not using the built-in command. During this time,
you will be able to pull from the Container Registry, but you will not be able to
push.

NOTE: **Note:**
By default, the [registry storage path](#container-registry-storage-path)
is `/var/opt/gitlab/gitlab-rails/shared/registry`.

To enable the read-only mode:

1. In `/etc/gitlab/gitlab.rb`, specify the read-only mode:

   ```ruby
     registry['storage'] = {
       'filesystem' => {
         'rootdirectory' => "<your_registry_storage_path>"
       },
       'maintenance' => {
         'readonly' => {
           'enabled' => true
         }
       }
     }
   ```

1. Save and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   This will set the Container Registry into the read only mode.

1. Next, trigger one of the garbage collect commands:

   ```shell
   # Recycling unused tags
   sudo /opt/gitlab/embedded/bin/registry garbage-collect /var/opt/gitlab/registry/config.yml

   # Removing unused layers not referenced by manifests
   sudo /opt/gitlab/embedded/bin/registry garbage-collect -m /var/opt/gitlab/registry/config.yml
   ```

   This will start the garbage collection, which might take some time to complete.

1. Once done, in `/etc/gitlab/gitlab.rb` change it back to read-write mode:

   ```ruby
    registry['storage'] = {
      'filesystem' => {
        'rootdirectory' => "<your_registry_storage_path>"
      },
      'maintenance' => {
        'readonly' => {
          'enabled' => false
        }
      }
    }
   ```

1. Save and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Running the garbage collection on schedule

Ideally, you want to run the garbage collection of the registry regularly on a
weekly basis at a time when the registry is not being in-use.
The simplest way is to add a new crontab job that it will run periodically
once a week.

Create a file under `/etc/cron.d/registry-garbage-collect`:

```shell
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Run every Sunday at 04:05am
5 4 * * 0  root gitlab-ctl registry-garbage-collect
```

## Troubleshooting

Before diving in to the following sections, here's some basic troubleshooting:

1. Check to make sure that the system clock on your Docker client and GitLab server have
   been synchronized (e.g. via NTP).

1. If you are using an S3-backed Registry, double check that the IAM
   permissions and the S3 credentials (including region) are correct. See [the
   sample IAM policy](https://docs.docker.com/registry/storage-drivers/s3/)
   for more details.

1. Check the Registry logs (e.g. `/var/log/gitlab/registry/current`) and the GitLab production logs
   for errors (e.g. `/var/log/gitlab/gitlab-rails/production.log`). You may be able to find clues
   there.

### Using self-signed certificates with Container Registry

If you're using a self-signed certificate with your Container Registry, you
might encounter issues during the CI jobs like the following:

```plaintext
Error response from daemon: Get registry.example.com/v1/users/: x509: certificate signed by unknown authority
```

The Docker daemon running the command expects a cert signed by a recognized CA,
thus the error above.

While GitLab doesn't support using self-signed certificates with Container
Registry out of the box, it is possible to make it work by
[instructing the Docker daemon to trust the self-signed certificates](https://docs.docker.com/registry/insecure/#use-self-signed-certificates),
mounting the Docker daemon and setting `privileged = false` in the Runner's
`config.toml`. Setting `privileged = true` takes precedence over the Docker daemon:

```toml
  [runners.docker]
    image = "ruby:2.6"
    privileged = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
```

Additional information about this: [issue 18239](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/18239).

### `unauthorized: authentication required` when pushing large images

Example error:

```shell
docker push gitlab.example.com/myproject/docs:latest
The push refers to a repository [gitlab.example.com/myproject/docs]
630816f32edb: Preparing
530d5553aec8: Preparing
...
4b0bab9ff599: Waiting
d1c800db26c7: Waiting
42755cf4ee95: Waiting
unauthorized: authentication required
```

GitLab has a default token expiration of 5 minutes for the registry. When pushing
larger images, or images that take longer than 5 minutes to push, users may
encounter this error.

Administrators can increase the token duration in **Admin area > Settings >
Container Registry > Authorization token duration (minutes)**.

### AWS S3 with the GitLab registry error when pushing large images

When using AWS S3 with the GitLab registry, an error may occur when pushing
large images. Look in the Registry log for the following error:

```plaintext
level=error msg="response completed with error" err.code=unknown err.detail="unexpected EOF" err.message="unknown error"
```

To resolve the error specify a `chunksize` value in the Registry configuration.
Start with a value between `25000000` (25MB) and `50000000` (50MB).

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['storage'] = {
     's3' => {
       'accesskey' => 'AKIAKIAKI',
       'secretkey' => 'secret123',
       'bucket'    => 'gitlab-registry-bucket-AKIAKIAKI',
       'chunksize' => 25000000
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**For installations from source**

1. Edit `config/gitlab.yml`:

   ```yaml
   storage:
     s3:
       accesskey: 'AKIAKIAKI'
       secretkey: 'secret123'
       bucket:    'gitlab-registry-bucket-AKIAKIAKI'
       chunksize: 25000000
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Supporting older Docker clients

As of GitLab 11.9, we began shipping version 2.7.1 of the Docker container registry, which disables the schema1 manifest by default. If you are still using older Docker clients (1.9 or older), you may experience an error pushing images. See [omnibus-4145](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4145) for more details.

You can add a configuration option for backwards compatibility.

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['compatibility_schema1_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**For installations from source**

1. Edit the YML configuration file you created when you [deployed the registry](https://docs.docker.com/registry/deploying/). Add the following snippet:

   ```yaml
   compatibility:
       schema1:
           enabled: true
   ```

1. Restart the registry for the changes to take affect.

### Docker connection error

A Docker connection error can occur when there are special characters in either the group,
project or branch name. Special characters can include:

- Leading underscore
- Trailing hyphen/dash
- Double hyphen/dash

To get around this, you can [change the group path](../../user/group/index.md#changing-a-groups-path),
[change the project path](../../user/project/settings/index.md#renaming-a-repository) or change the
branch name. Another option is to create a [push rule](../../push_rules/push_rules.md) to prevent
this at the instance level.

### Image push errors

When getting errors or "retrying" loops in an attempt to push an image but `docker login` works fine,
there is likely an issue with the headers forwarded to the registry by NGINX. The default recommended
NGINX configurations should handle this, but it might occur in custom setups where the SSL is
offloaded to a third party reverse proxy.

This problem was discussed in a [Docker project issue](https://github.com/docker/distribution/issues/970)
and a simple solution would be to enable relative URLs in the Registry.

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['env'] = {
     "REGISTRY_HTTP_RELATIVEURLS" => true
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**For installations from source**

1. Edit the YML configuration file you created when you [deployed the registry](https://docs.docker.com/registry/deploying/). Add the following snippet:

   ```yaml
   http:
       relativeurls: true
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

### Enable the Registry debug server

The optional debug server can be enabled by setting the registry debug address
in your `gitlab.rb` configuration.

```ruby
registry['debug_addr'] = "localhost:5001"
```

After adding the setting, [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) to apply the change.

Use curl to request debug output from the debug server:

```shell
curl localhost:5001/debug/health
curl localhost:5001/debug/vars
```

### Advanced Troubleshooting

NOTE: **Note:**
The following section is only recommended for experts.

Sometimes it's not obvious what is wrong, and you may need to dive deeper into
the communication between the Docker client and the Registry to find out
what's wrong. We will use a concrete example in the past to illustrate how to
diagnose a problem with the S3 setup.

#### Unexpected 403 error during push

A user attempted to enable an S3-backed Registry. The `docker login` step went
fine. However, when pushing an image, the output showed:

```plaintext
The push refers to a repository [s3-testing.myregistry.com:5050/root/docker-test/docker-image]
dc5e59c14160: Pushing [==================================================>] 14.85 kB
03c20c1a019a: Pushing [==================================================>] 2.048 kB
a08f14ef632e: Pushing [==================================================>] 2.048 kB
228950524c88: Pushing 2.048 kB
6a8ecde4cc03: Pushing [==>                                                ] 9.901 MB/205.7 MB
5f70bf18a086: Pushing 1.024 kB
737f40e80b7f: Waiting
82b57dbc5385: Waiting
19429b698a22: Waiting
9436069b92a3: Waiting
error parsing HTTP 403 response body: unexpected end of JSON input: ""
```

This error is ambiguous, as it's not clear whether the 403 is coming from the
GitLab Rails application, the Docker Registry, or something else. In this
case, since we know that since the login succeeded, we probably need to look
at the communication between the client and the Registry.

The REST API between the Docker client and Registry is [described
here](https://docs.docker.com/registry/spec/api/). Normally, one would just
use Wireshark or tcpdump to capture the traffic and see where things went
wrong. However, since all communications between Docker clients and servers
are done over HTTPS, it's a bit difficult to decrypt the traffic quickly even
if you know the private key. What can we do instead?

One way would be to disable HTTPS by setting up an [insecure
Registry](https://docs.docker.com/registry/insecure/). This could introduce a
security hole and is only recommended for local testing. If you have a
production system and can't or don't want to do this, there is another way:
use mitmproxy, which stands for Man-in-the-Middle Proxy.

#### mitmproxy

[mitmproxy](https://mitmproxy.org/) allows you to place a proxy between your
client and server to inspect all traffic. One wrinkle is that your system
needs to trust the mitmproxy SSL certificates for this to work.

The following installation instructions assume you are running Ubuntu:

1. [Install mitmproxy](https://docs.mitmproxy.org/stable/overview-installation/).
1. Run `mitmproxy --port 9000` to generate its certificates.
   Enter <kbd>CTRL</kbd>-<kbd>C</kbd> to quit.
1. Install the certificate from `~/.mitmproxy` to your system:

   ```shell
   sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
   sudo update-ca-certificates
   ```

If successful, the output should indicate that a certificate was added:

```shell
Updating certificates in /etc/ssl/certs... 1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d....done.
```

To verify that the certificates are properly installed, run:

```shell
mitmproxy --port 9000
```

This will run mitmproxy on port `9000`. In another window, run:

```shell
curl --proxy http://localhost:9000 https://httpbin.org/status/200
```

If everything is set up correctly, you will see information on the mitmproxy window and
no errors from the curl commands.

#### Running the Docker daemon with a proxy

For Docker to connect through a proxy, you must start the Docker daemon with the
proper environment variables. The easiest way is to shutdown Docker (e.g. `sudo initctl stop docker`)
and then run Docker by hand. As root, run:

```shell
export HTTP_PROXY="http://localhost:9000"
export HTTPS_PROXY="https://localhost:9000"
docker daemon --debug
```

This will launch the Docker daemon and proxy all connections through mitmproxy.

#### Running the Docker client

Now that we have mitmproxy and Docker running, we can attempt to login and push
a container image. You may need to run as root to do this. For example:

```shell
docker login s3-testing.myregistry.com:5050
docker push s3-testing.myregistry.com:5050/root/docker-test/docker-image
```

In the example above, we see the following trace on the mitmproxy window:

![mitmproxy output from Docker](img/mitmproxy-docker.png)

The above image shows:

- The initial PUT requests went through fine with a 201 status code.
- The 201 redirected the client to the S3 bucket.
- The HEAD request to the AWS bucket reported a 403 Unauthorized.

What does this mean? This strongly suggests that the S3 user does not have the right
[permissions to perform a HEAD request](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html).
The solution: check the [IAM permissions again](https://docs.docker.com/registry/storage-drivers/s3/).
Once the right permissions were set, the error will go away.
