# GitLab Container Registry Administration

> **Note:**
This feature was [introduced][ce-4040] in GitLab 8.8.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Configuration](#configuration)
    - [Container Registry under its own domain](#container-registry-under-its-own-domain)
    - [Container Registry under existing GitLab domain](#container-registry-under-existing-gitlab-domain)
- [Container Registry storage path](#container-registry-storage-path)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Configuration

Containers can be large in size and they are stored on the server GitLab is
installed on.

The Container Registry works under HTTPS by default.
This means that the Container Registry requires a SSL certificate.
There are two options on how this can be configured:

1. Use its own domain - needs a SSL certificate for that specific domain
   (eg. registry.example.com) or a wildcard certificate if hosted under a subdomain
   (eg. registry.gitlab.example.com)
1. Use existing GitLab domain and expose the registry on a port - can reuse
   existing GitLab SSL certificate

Note that using HTTP is possible but not recommended,
[see insecure Registry document][docker-insecure].

Please take this into consideration before configuring Container Registry for
the first time.

### Container Registry under its own domain

Lets assume that you want the Container Registry to be accessible at
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

### Container Registry under existing GitLab domain

Lets assume that your GitLab instance is accessible at
`https://gitlab.example.com`. You can expose the Container Registry under
a separate port.

Lets assume that you've exposed port `4567` in your network firewall.

**Omnibus GitLab packages**

---

Your `/etc/gitlab/gitlab.rb` should contain the Container Registry URL as
well as the path to the existing SSL certificate and key used by GitLab.

```ruby
registry_external_url 'https://gitlab.example.com:4567'

## If your SSL certificate is not in /etc/gitlab/ssl/gitlab.example.com.crt
## and key not in /etc/gitlab/ssl/gitlab.example.com.key uncomment the lines
## below

# registry_nginx['ssl_certificate'] = "/path/to/certificate.pem"
# registry_nginx['ssl_certificate_key'] = "/path/to/certificate.key"
```

Save the file and [reconfigure GitLab][] for the changes to take effect.

Users should now be able to login to the Container Registry using:

```bash
docker login gitlab.example.com:4567
```

with their GitLab credentials.

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

Save the file and [reconfigure GitLab][] for the changes to take effect.

**NOTE** You should confirm that the GitLab, registry and the web server user
have access to this directory.

[reconfigure gitlab]: ../../administration/restart_gitlab.md "How to restart GitLab documentation"
[wildcard certificate]: "https://en.wikipedia.org/wiki/Wildcard_certificate"
[ce-4040]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/4040
[docker-insecure]: https://github.com/docker/distribution/blob/master/docs/insecure.md
