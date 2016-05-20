# GitLab Container Registry Administration

> **Note:**
This feature was [introduced][ce-4040] in GitLab 8.8.

With the Docker container Registry integrated into GitLab, every project can
have its own space for Docker images.

You can read more about Docker Registry at https://docs.docker.com/registry/introduction/.

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Differences between Omnibus and source installations](#differences-between-omnibus-and-source-installations)
- [Container Registry domain configuration](#container-registry-domain-configuration)
    - [Container Registry under existing GitLab domain](#container-registry-under-existing-gitlab-domain)
    - [Container Registry under its own domain](#container-registry-under-its-own-domain)
- [Container Registry storage path](#container-registry-storage-path)
- [Disable Container Registry](#disable-container-registry)
- [Changelog](#changelog)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Differences between Omnibus and source installations

If you are using Omnibus, you have to bare in mind the following:

- The container Registry will be enabled by default if GitLab is configured
  with HTTPS and it will listen on port `5005`. If you want the Registry to
  listen on a port other than `5005`, read [#Container Registry under existing GitLab domain](#container-registry-under-existing-gitlab-domain)
  on how to achieve that. You will also have to configure your firewall to allow
  connections to that port.
- The container Registry works under HTTPS by default. Using HTTP is possible
  but not recommended and out of the scope of this document,
  [see the insecure Registry documentation][docker-insecure] if you want to
  implement this.

---

If you have installed GitLab from source:
- Omnibus has some things configured for you

- You will have to install Docker Registry by yourself. You can follow the
  [official documentation][registry-deploy].
- The container Registry will not be enabled by default, you will have to
  configure it in `gitlab.yml`.

The contents of `gitlab.yml` are:

```
registry:
  enabled: true
  host: registry.gitlab.example.com
  port: 5005
  api_url: http://localhost:5000/
  key_path: config/registry.key
  path: shared/registry
  issuer: gitlab-issuer
```

where:

| Parameter | Description |
| --------- | ----------- |
| `enabled` | Enables the Registry in GitLab. By default this is false. |
| `host`    | The host URL under which the Registry will run and the users will be able to use. |
| `port`    | The port under which the external Registry domain will listen on. |
| `api_url` | The internal API URL under which the Registry is exposed to. It defaults to `http://localhost:5000`. |
| `key_path`| The private key location that is a pair of Registry's `rootcertbundle`. Read the [token auth configuration documentation][token-config]. |
| `path`    | This should be the same directory like specified in Registry's `rootdirectory`. Read the [storage configuration documentation][storage-config]. |
| `issuer`  | This should be the same value as configured in Registry's `issuer`. Read the [token auth configuration documentation][token-config]. |

## Container Registry domain configuration

There are two ways you can configure the Registry's external domain. Either use
the existing GitLab domain where in that case the Registry will listen on a port,
or use a completely separate domain. Since the container Registry requires a
TLS certificate, in the end it all boils down to how easy or pricey is to
get a new TLS certificate.

Please take this into consideration before configuring the Container Registry
for the first time.

### Container Registry under existing GitLab domain

If the Registry is configured to use the existing GitLab domain, you can
expose the Registry on a port so that you can reuse the existing GitLab TLS
certificate.

Assuming that the GitLab domain is `https://gitlab.example.com` and the port the
Registry is exposed to the outside world is `4567`, here is what you need to set
in `gitlab.rb` or `gitlab.yml` if you are using Omnibus GitLab or installed
GitLab from source respectively.

**Omnibus GitLab packages**

1. Your `/etc/gitlab/gitlab.rb` should contain the Registry URL as well as the
   path to the existing TLS certificate and key used by GitLab.

    ```ruby
    registry_external_url 'https://gitlab.example.com:4567'

    ## If your SSL certificate is not in /etc/gitlab/ssl/gitlab.example.com.crt
    ## and key not in /etc/gitlab/ssl/gitlab.example.com.key uncomment the lines
    ## below

    # registry_nginx['ssl_certificate'] = "/path/to/certificate.pem"
    # registry_nginx['ssl_certificate_key'] = "/path/to/certificate.key"
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**Installation from source**

```
registry:
  enabled: true
  host: registry.gitlab.example.com
  port: 5005
  api_url: http://localhost:5000/
  key_path: config/registry.key
  path: shared/registry
  issuer: gitlab-issuer
```

Users should now be able to login to the Container Registry using:

```bash
docker login gitlab.example.com:4567
```

with their GitLab credentials.

### Container Registry under its own domain

If the Registry is configured to use its own domain, you will need a TLS
certificate for that specific domain (e.g., `registry.example.com`) or maybe
a wildcard certificate if hosted under a subdomain (e.g., `registry.gitlab.example.com`).

Let's assume that you want the container Registry to be accessible at
`https://registry.gitlab.example.com`.

---

**Omnibus GitLab packages**

Place your SSL certificate and key in
`/etc/gitlab/ssl/registry.gitlab.example.com.crt`
and
`/etc/gitlab/ssl/registry.gitlab.example.com.key` and make sure they have
correct permissions:

```bash
chmod 600 /etc/gitlab/ssl/registry.gitlab.example.com.*
```

Once the SSL certificate is in place, edit `/etc/gitlab/gitlab.rb` with:

```ruby
registry_external_url 'https://registry.gitlab.example.com'
```

Save the file and [reconfigure GitLab][] for the changes to take effect.

```
registry:
  enabled: true
  host: registry.gitlab.example.com
  port: 5005
  api_url: http://localhost:5000/
  key_path: config/registry.key
  path: shared/registry
  issuer: gitlab-issuer
```

Users should now be able to login to the Container Registry using:

```bash
docker login registry.gitlab.example.com
```

with their GitLab credentials.

If you have a [wildcard certificate][], you need to specify the path to the
certificate in addition to the URL, in this case `/etc/gitlab/gitlab.rb` will
look like:

```ruby
registry_external_url 'https://registry.gitlab.example.com'
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/certificate.pem"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/certificate.key"
```

```
registry:
  enabled: true
  host: registry.gitlab.example.com
  port: 5005
  api_url: http://localhost:5000/
  key_path: config/registry.key
  path: shared/registry
  issuer: gitlab-issuer
```

## Container Registry storage path

It is possible to change path where containers will be stored by the Container
Registry.

**Omnibus GitLab packages**

---

By default, the path Container Registry is using to store the containers is in
`/var/opt/gitlab/gitlab-rails/shared/registry`.
This path is accessible to the user running the Container Registry daemon,
user running GitLab and to the user running Nginx web server.

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['registry_path'] = "/path/to/registry/storage"
```

```
registry:
  enabled: true
  host: registry.gitlab.example.com
  port: 5005
  api_url: http://localhost:5000/
  key_path: config/registry.key
  path: shared/registry
  issuer: gitlab-issuer
```

Save the file and [reconfigure GitLab][] for the changes to take effect.

**NOTE** You should confirm that the GitLab, registry and the web server user
have access to this directory.

## Disable Container Registry

**Omnibus GitLab**

```
# Settings used by GitLab application
# gitlab_rails['registry_enabled'] = true
```

```
# gitlab_rails['registry_host'] = "registry.gitlab.example.com"
# gitlab_rails['registry_api_url'] = "http://localhost:5000"
# gitlab_rails['registry_key_path'] = "/var/opt/gitlab/gitlab-rails/certificate.key"
# gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"
# gitlab_rails['registry_issuer'] = "omnibus-gitlab-issuer"

# Settings used by Registry application
# registry['enable'] = true
# registry['username'] = "registry"
# registry['group'] = "registry"
# registry['uid'] = nil
# registry['gid'] = nil
# registry['dir'] = "/var/opt/gitlab/registry"
# registry['log_directory'] = "/var/log/gitlab/registry"
# registry['log_level'] = "info"
# registry['rootcertbundle'] = "/var/opt/gitlab/registry/certificate.crt"
```

## Changelog


[reconfigure gitlab]: ../../administration/restart_gitlab.md "How to restart GitLab documentation"
[wildcard certificate]: "https://en.wikipedia.org/wiki/Wildcard_certificate"
[ce-4040]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/4040
[docker-insecure]: https://docs.docker.com/registry/insecure/
[registry-deploy]: https://docs.docker.com/registry/deploying/
[storage-config]: https://docs.docker.com/registry/configuration/#storage
[token-config]: https://docs.docker.com/registry/configuration/#token
