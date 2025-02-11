---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install an offline GitLab Self-Managed instance
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This is a step-by-step guide that helps you install, configure, and use a GitLab Self-Managed
instance entirely offline.

## Installation

NOTE:
This guide assumes the server is Ubuntu 20.04 using the [Omnibus installation method](https://docs.gitlab.com/omnibus/) and is running GitLab [Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/). Instructions for other servers may vary.
This guide also assumes the server host resolves as `my-host.internal`, which you should replace with your
server's FQDN, and that you have access to a different server with Internet access to download the required package files.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video walkthrough of this process, see [Offline GitLab Installation: Downloading & Installing](https://www.youtube.com/watch?v=TJaq4ua2Prw).

### Download the GitLab package

You should [manually download the GitLab package](../../update/package/_index.md#by-using-a-downloaded-package) and relevant dependencies using a server of the same operating system type that has access to the Internet.

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
# Go to the physical media device
sudo cd /path/to/mount

# Install the dependency packages
sudo dpkg -i <package_name>.deb
```

[Use the relevant commands for your operating system to install the package](../../update/package/_index.md#by-using-a-downloaded-package) but make sure to specify an `http`
URL for the `EXTERNAL_URL` installation step. Once installed, we can manually
configure the SSL ourselves.

It is strongly recommended to set up a domain for IP resolution rather than bind
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

## Enabling the GitLab container registry

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
[following the steps for using trusted certificates with your registry](../../administration/packages/container_registry_troubleshooting.md#using-self-signed-certificates-with-container-registry):

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

Enter the GitLab instance URL (for example, https://gitlab.com/):
https://my-host.internal
Enter the registration token:
XXXXXXXXXXX
Enter a description for the runner:
[eb18856e13c0]:
Enter tags for the runner (comma-separated):
Enter optional maintenance note for the runner:

Registering runner... succeeded                     runner=FSMwkvLZ
Please enter the executor: custom, docker, virtualbox, kubernetes, docker+machine, docker-ssh+machine, docker-ssh, parallels, shell, ssh:
docker
Please enter the default Docker image (for example, ruby:2.6):
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

As noted in [Docker registry authentication documentation](https://distribution.github.io/distribution/about/insecure/#docker-still-complains-about-the-certificate-when-using-authentication),
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

For more information, see [Enable or disable service ping](../../administration/settings/usage_statistics.md#enable-or-disable-service-ping).

### Disable runner version management

Runner version management retrieves the latest runner versions from GitLab to
[determine which runners in your environment are out of date](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded).
You must [disable runner version management](../../administration/settings/continuous_integration.md#disable-runner-version-management)
for offline environments.

### Configure NTP

In GitLab 15.4 and 15.5, Gitaly Cluster assumes `pool.ntp.org` is accessible. If `pool.ntp.org` is not accessible, [customize the time server setting](../../administration/gitaly/praefect.md#customize-time-server-setting) on the Gitaly
and Praefect servers so they can use an accessible NTP server.

On offline instances, the [GitLab Geo check Rake task](../../administration/geo/replication/troubleshooting/common.md#can-geo-detect-the-current-site-correctly)
always fails because it uses `pool.ntp.org`. This error can be ignored but you can
[read more about how to work around it](../../administration/geo/replication/troubleshooting/common.md#message-machine-clock-is-synchronized--exception).

## Enabling the Package Metadata Database

Enabling the Package Metadata Database is required to enable
[Continuous Vulnerability Scanning](../../user/application_security/continuous_vulnerability_scanning/_index.md)
and [license scanning of CycloneDX files](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md).
This process requires the use of License and/or Advisory Data under what is collectively called the Package Metadata Database, which is licensed under the [EE License](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/LICENSE).
Note the following in relation to use of the Package Metadata Database:

- We may change or discontinue all or any part of the Package Metadata Database, at any time and without notice, at our sole discretion.
- The Package Metadata Database may contain links to third-party websites or resources. We provide these links only as a convenience and are not responsible for any third-party data, content, products, or services from those websites or resources or links displayed on such websites.
- The Package Metadata Database is based in part on information made available by third parties, and GitLab is not responsible for the accuracy or completeness of content made available.

Package metadata is stored in the following Google Cloud Provider (GCP) buckets:

- License Scanning - prod-export-license-bucket-1a6c642fc4de57d4
- Dependency Scanning - prod-export-advisory-bucket-1a6c642fc4de57d4

### Using the gsutil tool to download the package metadata exports

1. Install the [`gsutil`](https://cloud.google.com/storage/docs/gsutil_install) tool.
1. Find the root of the GitLab Rails directory.

   ```shell
   export GITLAB_RAILS_ROOT_DIR="$(gitlab-rails runner 'puts Rails.root.to_s')"
   echo $GITLAB_RAILS_ROOT_DIR
   ```

1. Set the type of data you wish to sync.

   ```shell
   # For License Scanning
   export PKG_METADATA_BUCKET=prod-export-license-bucket-1a6c642fc4de57d4
   export DATA_DIR="licenses"

   # For Dependency Scanning
   export PKG_METADATA_BUCKET=prod-export-advisory-bucket-1a6c642fc4de57d4
   export DATA_DIR="advisories"
   ```

1. Download the package metadata exports.

   ```shell
   # To download the package metadata exports, an outbound connection to Google Cloud Storage bucket must be allowed.
   # Skip v1 objects using -y "^v1\/" to only download v2 objects. v1 data is no longer used and deprecated since 16.3.
   mkdir -p "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"
   gsutil -m rsync -r -d -y "^v1\/" gs://$PKG_METADATA_BUCKET "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"

   # Alternatively, if the GitLab instance is not allowed to connect to the Google Cloud Storage bucket, the package metadata
   # exports can be downloaded using a machine with the allowed access, and then copied to the root of the GitLab Rails directory.
   rsync rsync://example_username@gitlab.example.com/package_metadata/$DATA_DIR "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"
   ```

### Using the Google Cloud Storage REST API to download the package metadata exports

The package metadata exports can also be downloaded using the Google Cloud Storage API. The contents are available at [https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o](https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o) and [https://storage.googleapis.com/storage/v1/b/prod-export-advisory-bucket-1a6c642fc4de57d4/o](https://storage.googleapis.com/storage/v1/b/prod-export-advisory-bucket-1a6c642fc4de57d4/o). The following is an example of how this can be downloaded using [cURL](https://curl.se/) and [jq](https://stedolan.github.io/jq/).

```shell
#!/bin/bash

set -euo pipefail

DATA_TYPE=$1

GITLAB_RAILS_ROOT_DIR="$(gitlab-rails runner 'puts Rails.root.to_s')"

if [ "$DATA_TYPE" == "license" ]; then
  PKG_METADATA_DIR="$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses"
elif [ "$DATA_TYPE" == "advisory" ]; then
  PKG_METADATA_DIR="$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories"
else
  echo "Usage: import_script.sh [license|advisory]"
  exit 1
fi

PKG_METADATA_BUCKET="prod-export-$DATA_TYPE-bucket-1a6c642fc4de57d4"
PKG_METADATA_DOWNLOADS_OUTPUT_FILE="/tmp/package_metadata_${DATA_TYPE}_object_links.tsv"

# Download the contents of the bucket
# Filter results using `prefix=v2` to only download v2 objects. v1 data is no longer used and deprecated since 16.3.
# The script downloads all the objects and creates files with a maximum 1000 objects per file in JSON format.

MAX_RESULTS=1000
TEMP_FILE="out.json"

curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/$PKG_METADATA_BUCKET/o?maxResults=$MAX_RESULTS&prefix=v2%2f" >"$TEMP_FILE"
NEXT_PAGE_TOKEN="$(jq -r '.nextPageToken' $TEMP_FILE)"
jq -r '.items[] | [.name, .mediaLink] | @tsv' "$TEMP_FILE" >"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

while [ "$NEXT_PAGE_TOKEN" != "null" ]; do
  curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/$PKG_METADATA_BUCKET/o?maxResults=$MAX_RESULTS&pageToken=$NEXT_PAGE_TOKEN&prefix=v2%2f" >"$TEMP_FILE"
  NEXT_PAGE_TOKEN="$(jq -r '.nextPageToken' $TEMP_FILE)"
  jq -r '.items[] | [.name, .mediaLink] | @tsv' "$TEMP_FILE" >>"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"
  #use for API rate-limiting
  sleep 1
done

trap 'rm -f "$TEMP_FILE"' EXIT

echo "Fetched $DATA_TYPE export manifest"

# Parse the links and names for the bucket objects and output them into a tsv file

echo -e "Saving package metadata exports to $PKG_METADATA_DIR\n"

# Track how many objects will be downloaded
INDEX=1
TOTAL_OBJECT_COUNT="$(wc -l "$PKG_METADATA_DOWNLOADS_OUTPUT_FILE" | awk '{print $1}')"

# Download the objects
while IFS= read -r line; do
  FILE="$(echo -n "$line" | awk '{print $1}')"
  URL="$(echo -n "$line" | awk '{print $2}')"
  OUTPUT_PATH="$PKG_METADATA_DIR/$FILE"

  echo "Downloading $FILE"

  if [ ! -f "$OUTPUT_PATH" ]; then
    curl --progress-bar --create-dirs --output "$OUTPUT_PATH" --request "GET" "$URL"
  else
    echo "Existing file found"
  fi

  echo -e "$INDEX of $TOTAL_OBJECT_COUNT objects downloaded\n"

  INDEX=$((INDEX + 1))
done <"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

echo "All objects saved to $PKG_METADATA_DIR"
```

### Automatic synchronization

Your GitLab instance is synchronized [regularly](https://gitlab.com/gitlab-org/gitlab/-/blob/63a187d47f6da353ba4514650bbbbeb99c356325/config/initializers/1_settings.rb#L840-842) with the contents of the `package_metadata` directory.
To automatically update your local copy with the upstream changes, a cron job can be added to periodically download new exports. For example, the following crontabs can be added to set up a cron job that runs every 30 minutes.

For License Scanning:

```plaintext
*/30 * * * * gsutil -m rsync -r -d -y "^v1\/" gs://prod-export-license-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses
```

For Dependency Scanning:

```plaintext
*/30 * * * * gsutil -m rsync -r -d gs://prod-export-advisory-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories
```

### Change note

The directory for package metadata changed with the release of 16.2 from `vendor/package_metadata_db` to `vendor/package_metadata/licenses`. If this directory already exists on the instance and Dependency Scanning needs to be added then you need to take the following steps.

1. Rename the licenses directory: `mv vendor/package_metadata_db vendor/package_metadata/licenses`.
1. Update any automation scripts or commands saved to change `vendor/package_metadata_db` to `vendor/package_metadata/licenses`.
1. Update any cron entries to change `vendor/package_metadata_db` to `vendor/package_metadata/licenses`.

   ```shell
   sed -i '.bckup' -e 's#vendor/package_metadata_db#vendor/package_metadata/licenses#g' [FILE ...]
   ```

### Troubleshooting

#### Missing database data

If license or advisory data is missing from the dependency list or MR pages, one possible cause of this is that the database has not been synchronized with the export data.

`package_metadata` synchronization is triggered by using cron jobs ([advisory sync](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L864-866) and [license sync](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L855-857)) and imports only the package registry types enabled in [admin settings](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync).

The file structure in `vendor/package_metadata` must coincide with the package registry type enabled above. For example, to sync `maven` license or advisory data, the package metadata directory under the Rails directory must have the following structure:

- For licenses:`$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v2/maven/**/*.ndjson`.
- For advisories:`$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories/v2/maven/**/*.ndjson`.

After a successful run, data under the `pm_` tables in the database should be populated (check using [Rails console](../../administration/operations/rails_console.md)):

- For licenses: `sudo gitlab-rails runner "puts \"Package model has #{PackageMetadata::Package.where(purl_type: 'maven').size} packages\""`
- For advisories: `sudo gitlab-rails runner "puts \"Advisory model has #{PackageMetadata::AffectedPackage.where(purl_type: 'maven').size} packages\""`

Additionally, checkpoint data should exist for the particular package registry being synchronized. For Maven, for example, there should be a checkpoint created after a successful sync run:

- For licenses: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'licenses', purl_type: 'maven')}\""`
- For advisories: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'advisories', purl_type: 'maven')}\""`

Finally, you can check the [`application_json.log`](../../administration/logs/_index.md#application_jsonlog) logs to verify that the
sync job has run and is without error by searching for `DEBUG` messages where the class is `PackageMetadata::SyncService`. Example: `{"severity":"DEBUG","time":"2023-06-22T16:41:00.825Z","correlation_id":"a6e80150836b4bb317313a3fe6d0bbd6","class":"PackageMetadata::SyncService","message":"Evaluating data for licenses:gcp/prod-export-license-bucket-1a6c642fc4de57d4/v2/pypi/1694703741/0.ndjson"}`.
