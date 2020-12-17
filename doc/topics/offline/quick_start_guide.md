---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Getting started with an offline GitLab Installation

This is a step-by-step guide that helps you install, configure, and use a self-managed GitLab
instance entirely offline.

## Installation

NOTE:
This guide assumes the server is Ubuntu 18.04. Instructions for other servers may vary.
This guide also assumes the server host resolves as `my-host`, which you should replace with your
server's name.

Follow the installation instructions [as outlined in the omnibus install
guide](https://about.gitlab.com/install/#ubuntu), but make sure to specify an `http`
URL for the `EXTERNAL_URL` installation step. Once installed, we can manually
configure the SSL ourselves.

It is strongly recommended to setup a domain for IP resolution rather than bind
to the server's IP address. This better ensures a stable target for our certs' CN
and makes long-term resolution simpler.

```shell
sudo EXTERNAL_URL="http://my-host.internal" apt-get install gitlab-ee
```

## Enabling SSL

Follow these steps to enable SSL for your fresh instance. Note that these steps reflect those for
[manually configuring SSL in Omnibus's NGINX configuration](https://docs.gitlab.com/omnibus/settings/nginx.html#manually-configuring-https):

1. Make the following changes to `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Update external_url from "http" to "https"
   external_url "https://gitlab.example.com"

   # Set Let's Encrypt to false
   letsencrypt['enable'] = false
   ```

1. Create the following directories with the appropriate permissions for generating self-signed
   certificates:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/gitlab/ssl/my-host.internal.key -out /etc/gitlab/ssl/my-host.internal.crt
   ```

1. Reconfigure your instance to apply the changes:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Enabling the GitLab Container Registry

Follow these steps to enable the container registry. Note that these steps reflect those for
[configuring the container registry under an existing domain](../../administration/packages/container_registry.md#configure-container-registry-under-an-existing-gitlab-domain):

1. Make the following changes to `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Change external_registry_url to match external_url, but append the port 4567
   external_url "https://gitlab.example.com"
   registry_external_url "https://gitlab.example.com:4567"
   ```

1. Reconfigure your instance to apply the changes:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Allow the Docker daemon to trust the registry and GitLab Runner

Provide your Docker daemon with your certs by
[following the steps for using trusted certificates with your registry](../../administration/packages/container_registry.md#using-self-signed-certificates-with-container-registry):

```shell
sudo mkdir -p /etc/docker/certs.d/my-host.internal:5000

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/docker/certs.d/my-host.internal:5000/ca.crt
```

Provide your GitLab Runner (to be installed next) with your certs by
[following the steps for using trusted certificates with your runner](https://docs.gitlab.com/runner/install/docker.html#installing-trusted-ssl-server-certificates):

```shell
sudo mkdir -p /etc/gitlab-runner/certs

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/gitlab-runner/certs/ca.crt
```

## Enabling GitLab Runner

[Following a similar process to the steps for installing our GitLab Runner as a
Docker service](https://docs.gitlab.com/runner/install/docker.html#docker-image-installation), we must first register our runner:

```shell
$ sudo docker run --rm -it -v /etc/gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register
Updating CA certificates...
Runtime platform                                    arch=amd64 os=linux pid=7 revision=1b659122 version=12.8.0
Running in system-mode.

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
https://my-host.internal
Please enter the gitlab-ci token for this runner:
XXXXXXXXXXX
Please enter the gitlab-ci description for this runner:
[eb18856e13c0]:
Please enter the gitlab-ci tags for this runner (comma separated):

Registering runner... succeeded                     runner=FSMwkvLZ
Please enter the executor: custom, docker, virtualbox, kubernetes, docker+machine, docker-ssh+machine, docker-ssh, parallels, shell, ssh:
docker
Please enter the default Docker image (e.g. ruby:2.6):
ruby:2.6
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

Now we must add some additional configuration to our runner:

Make the following changes to `/etc/gitlab-runner/config.toml`:

- Add Docker socket to volumes `volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]`
- Add `pull_policy = "if-not-present"` to the executor configuration

Now we can start our runner:

```shell
sudo docker run -d --restart always --name gitlab-runner -v /etc/gitlab-runner:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
90646b6587127906a4ee3f2e51454c6e1f10f26fc7a0b03d9928d8d0d5897b64
```

### Authenticating the registry against the host OS

As noted in [Docker's registry authentication documentation](https://docs.docker.com/registry/insecure/#docker-still-complains-about-the-certificate-when-using-authentication),
certain versions of Docker require trusting the certificate chain at the OS level.

In the case of Ubuntu, this involves using `update-ca-certificates`:

```shell
sudo cp /etc/docker/certs.d/my-host.internal\:5000/ca.crt /usr/local/share/ca-certificates/my-host.internal.crt

sudo update-ca-certificates
```

If all goes well, this is what you should see:

```plaintext
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```
