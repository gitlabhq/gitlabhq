---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Getting started with an offline GitLab Installation **(FREE SELF)**

This is a step-by-step guide that helps you install, configure, and use a self-managed GitLab
instance entirely offline.

## Installation

NOTE:
This guide assumes the server is Ubuntu 20.04 using the [Omnibus installation method](https://docs.gitlab.com/omnibus/) and is running GitLab [Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/). Instructions for other servers may vary.
This guide also assumes the server host resolves as `my-host.internal`, which you should replace with your
server's FQDN, and that you have access to a different server with Internet access to download the required package files.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video walkthrough of this process, see [Offline GitLab Installation: Downloading & Installing](https://www.youtube.com/watch?v=TJaq4ua2Prw).

### Download the GitLab package

You should [manually download the GitLab package](../../update/package/index.md#upgrade-using-a-manually-downloaded-package) and relevant dependencies using a server of the same operating system type that has access to the Internet.

If your offline environment has no local network access, you must manually transport the relevant package through physical media, such as a USB drive.

In Ubuntu, this can be performed on a server with Internet access using the following commands:

```shell
# Download the bash script to prepare the repository
curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash

# Download the gitlab-ee package and dependencies to /var/cache/apt/archives
sudo apt-get install --download-only gitlab-ee

# Copy the contents of the apt download folder to a mounted media device
sudo cp /var/cache/apt/archives/*.deb /path/to/mount
```

### Install the GitLab package

Prerequisites:

- Before installing the GitLab package on your offline environment, ensure that you have installed all required dependencies first.

If you are using Ubuntu, you can install the dependency `.deb` packages you copied across with `dpkg`. Do not install the GitLab package yet.

```shell
# Navigate to the physical media device
sudo cd /path/to/mount

# Install the dependency packages
sudo dpkg -i <package_name>.deb
```

[Use the relevant commands for your operating system to install the package](../../update/package/index.md#upgrade-using-a-manually-downloaded-package) but make sure to specify an `http`
URL for the `EXTERNAL_URL` installation step. Once installed, we can manually
configure the SSL ourselves.

It is strongly recommended to setup a domain for IP resolution rather than bind
to the server's IP address. This better ensures a stable target for our certs' CN
and makes long-term resolution simpler.

The following example for Ubuntu specifies the `EXTERNAL_URL` using HTTP and installs the GitLab package:

```shell
sudo EXTERNAL_URL="http://my-host.internal" dpkg -i <gitlab_package_name>.deb
```

## Enabling SSL

Follow these steps to enable SSL for your fresh instance. These steps reflect those for
[manually configuring SSL in Omnibus's NGINX configuration](https://docs.gitlab.com/omnibus/settings/ssl/index.html#configure-https-manually):

1. Make the following changes to `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Update external_url from "http" to "https"
   external_url "https://my-host.internal"

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

Follow these steps to enable the container registry. These steps reflect those for
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

[Following a similar process to the steps for installing our GitLab Runner as a Docker service](https://docs.gitlab.com/runner/install/docker.html#install-the-docker-image-and-start-the-container), we must first register our runner:

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

As noted in [Docker registry authentication documentation](https://docs.docker.com/registry/insecure/#docker-still-complains-about-the-certificate-when-using-authentication),
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

### Disable Version Check and Service Ping

Version Check and Service Ping improve the GitLab user experience and ensure that
users are on the most up-to-date instances of GitLab. These two services can be turned off for offline
environments so that they do not attempt and fail to reach out to GitLab services.

For more information, see [Enable or disable usage statistics](../../user/admin_area/settings/usage_statistics.md#enable-or-disable-usage-statistics).

### Configure NTP

In GitLab 15.4 and 15.5, Gitaly Cluster assumes `pool.ntp.org` is accessible. If `pool.ntp.org` is not accessible, [customize the time server setting](../../administration/gitaly/praefect.md#customize-time-server-setting) on the Gitaly
and Praefect servers so they can use an accessible NTP server.

On offline instances, the [GitLab Geo check Rake task](../../administration/geo/replication/troubleshooting.md#can-geo-detect-the-current-site-correctly)
always fails because it uses `pool.ntp.org`. This error can be ignored but you can
[read more about how to work around it](../../administration/geo/replication/troubleshooting.md#message-machine-clock-is-synchronized--exception).

## Enabling the package metadata database

Enabling the package metadata database is required to enable [license scanning of CycloneDX files](../../user/compliance/license_scanning_of_cyclonedx_files).
This process requires usage of the GitLab License Database, which is licensed under the [EE License](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/v1/LICENSE).
Note the following in relation to use of the License Database:

- We may change or discontinue all or any part of the License Database, at any time and without notice, at our sole discretion.
- The License Database may contain links to third-party websites or resources. We provide these links only as a convenience and are not responsible for any third-party data, content, products, or services from those websites or resources or links displayed on such websites.
- The License Database is based in part on information made available by third parties, and GitLab is not responsible for the accuracy or completeness of content made available.

### Using the gsutil tool to download the package metadata exports

1. Install the [`gsutil`](https://cloud.google.com/storage/docs/gsutil_install) tool.
1. Find the root of the GitLab Rails directory.

   ```shell
   export GITLAB_RAILS_ROOT_DIR="$(gitlab-rails runner 'puts Rails.root.to_s')"
   echo $GITLAB_RAILS_ROOT_DIR
   ```

1. Download the package metadata exports.

   ```shell
   # To download the package metadata exports, an outbound connection to Google Cloud Storage bucket must be allowed.
   mkdir $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata_db/
   gsutil -m rsync -r -d gs://prod-export-license-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata_db/

   # Alternatively, if the GitLab instance is not allowed to connect to the Google Cloud Storage bucket, the package metadata
   # exports can be downloaded using a machine with the allowed access, and then copied to the root of the GitLab Rails directory.
   rsync rsync://example_username@gitlab.example.com/package_metadata_db $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata_db/
   ```

### Using the Google Cloud Storage REST API to download the package metadata exports

The package metadata exports can also be downloaded using the Google Cloud Storage API. The contents are available at [https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o](https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o). The following is an example of how this can be downloaded using [cURL](https://curl.se/) and [jq](https://stedolan.github.io/jq/).

```shell
#!/bin/bash

set -euo pipefail

GITLAB_RAILS_ROOT_DIR="$(gitlab-rails runner 'puts Rails.root.to_s')"
PKG_METADATA_DIR="$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata_db"
PKG_METADATA_MANIFEST_OUTPUT_FILE="/tmp/license_db_export_manifest.json"
PKG_METADATA_DOWNLOADS_OUTPUT_FILE="/tmp/license_db_object_links.tsv"

# Download the contents of the bucket
curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o" > "$PKG_METADATA_MANIFEST_OUTPUT_FILE"

# Parse the links and names for the bucket objects and output them into a tsv file
jq -r '.items[] | [.name, .mediaLink] | @tsv' "$PKG_METADATA_MANIFEST_OUTPUT_FILE" > "$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

echo -e "Saving package metadata exports to $PKG_METADATA_DIR\n"

# Track how many objects will be downloaded
INDEX=1
TOTAL_OBJECT_COUNT="$(wc -l $PKG_METADATA_DOWNLOADS_OUTPUT_FILE | awk '{print $1}')"

# Download the objects
while IFS= read -r line; do
   FILE="$(echo -n $line | awk '{print $1}')"
   URL="$(echo -n $line | awk '{print $2}')"
   OUTPUT_DIR="$(dirname $PKG_METADATA_DIR/$FILE)"
   OUTPUT_PATH="$PKG_METADATA_DIR/$FILE"

   echo "Downloading $FILE"

   curl --progress-bar --create-dirs --output "$OUTPUT_PATH" --request "GET" "$URL"

   echo -e "$INDEX of $TOTAL_OBJECT_COUNT objects downloaded\n"

   let INDEX=(INDEX+1)
done < "$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

echo "All objects saved to $PKG_METADATA_DIR"
```

### Automatic synchronization

Your GitLab instance is synchronized [every hour](https://gitlab.com/gitlab-org/gitlab/-/blob/d4331343d26d6e2a81fadd8f7ecd72f7cb74d04d/config/initializers/1_settings.rb#L831-832) with the contents of the `package_metadata_db` directory.
To automatically update your local copy with the upstream changes, a cron job can be added to periodically download new exports. For example, the following crontabs can be added to setup a cron job that runs every 30 minutes.

```plaintext
*/30 * * * * gsutil -m rsync -r -d gs://prod-export-license-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata_db/
```
