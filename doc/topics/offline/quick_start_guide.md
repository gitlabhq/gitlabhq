---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Install, configure, and use a GitLab Self-Managed instance in an environment with no internet access.
title: Install an offline GitLab Self-Managed instance
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This is a step-by-step guide that helps you install, configure, and use a GitLab Self-Managed
instance entirely offline.

## Installation

> [!note]
> This guide assumes the server is Ubuntu 20.04 using the [Linux package installation method](https://docs.gitlab.com/omnibus/) and is running GitLab [Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/). Instructions for other servers may vary.
> This guide also assumes the server host resolves as `my-host.internal`, which you should replace with your
> server's FQDN, and that you have access to a different server with Internet access to download the required package files.

<i class="fa-youtube-play" aria-hidden="true"></i>
For a video walkthrough of this process, see [Offline GitLab Installation: Downloading & Installing](https://www.youtube.com/watch?v=TJaq4ua2Prw).

### Download the GitLab package

You should [download the GitLab package](../../update/package/_index.md#upgrade-with-a-downloaded-package) and relevant dependencies using a server of the same operating system type that has access to the Internet.

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

[Use the relevant commands for your operating system to install the package](../../update/package/_index.md#upgrade-with-a-downloaded-package) but make sure to specify an `http`
URL for the `EXTERNAL_URL` installation step. Once installed, you can manually
configure the SSL yourself.

You should set up a domain for IP resolution rather than bind to the server's IP address.
A domain provides a stable target for the certificate's Common Name (CN) and simplifies the long-term
resolution.

The following example for Ubuntu specifies the `EXTERNAL_URL` using HTTP and installs the GitLab package:

```shell
sudo EXTERNAL_URL="http://my-host.internal" dpkg -i <gitlab_package_name>.deb
```

## Enabling SSL

Follow these steps to enable SSL for your fresh instance. These steps reflect those for
[manually configuring SSL in the NGINX configuration](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually):

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
[following the steps for using trusted certificates with your registry](../../administration/packages/container_registry.md#configure-self-signed-certificates):

```shell
sudo mkdir -p /etc/docker/certs.d/my-host.internal:5000

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/docker/certs.d/my-host.internal:5000/ca.crt
```

Provide your GitLab Runner (to be installed next) with your certs by
[following the steps for using trusted certificates with your runner](https://docs.gitlab.com/runner/install/docker/#installing-trusted-ssl-server-certificates):

```shell
sudo mkdir -p /etc/gitlab-runner/certs

sudo cp /etc/gitlab/ssl/my-host.internal.crt /etc/gitlab-runner/certs/ca.crt
```

## Enabling GitLab Runner

[Following a similar process to the steps for installing our GitLab Runner as a Docker service](https://docs.gitlab.com/runner/install/docker/#install-the-docker-image-and-start-the-container), you must first register your runner:

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

Next, you must add some additional configuration to your runner.

Make the following changes to `/etc/gitlab-runner/config.toml`:

- Add Docker socket to volumes `volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]`
- Add `pull_policy = "if-not-present"` to the executor configuration

Now you can start your runner:

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
You must [disable runner version management](../../administration/settings/continuous_integration.md#control-runner-version-management)
for offline environments.

### Configure NTP

Gitaly Cluster (Praefect) assumes `pool.ntp.org` is accessible. If `pool.ntp.org` is not accessible, [customize the time server setting](../../administration/gitaly/praefect/configure.md#customize-time-server-setting) on the Gitaly
and Praefect servers so they can use an accessible NTP server.

On offline instances, the [GitLab Geo check Rake task](../../administration/geo/replication/troubleshooting/common.md#can-geo-detect-the-current-site-correctly)
always fails because it uses `pool.ntp.org`. This error can be ignored but you can
[read more about how to work around it](../../administration/geo/replication/troubleshooting/common.md#message-machine-clock-is-synchronized--exception).

## Enabling the Package Metadata Database

Enabling the Package Metadata Database is required to enable
[continuous vulnerability scanning](../../user/application_security/continuous_vulnerability_scanning/_index.md)
and [license scanning of CycloneDX files](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md).
This process requires the use of License and/or Advisory Data under what is collectively called the Package Metadata Database, which is licensed under the [EE License](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/LICENSE).
Note the following in relation to use of the Package Metadata Database:

- We may change or discontinue all or any part of the Package Metadata Database, at any time and without notice, at our sole discretion.
- The Package Metadata Database may contain links to third-party websites or resources. We provide these links only as a convenience and are not responsible for any third-party data, content, products, or services from those websites or resources or links displayed on such websites.
- The Package Metadata Database is based in part on information made available by third parties, and GitLab is not responsible for the accuracy or completeness of content made available.

Package metadata is stored in the following Google Cloud Provider (GCP) buckets which are maintained and owned by GitLab:

- License Scanning - `prod-export-license-bucket-1a6c642fc4de57d4`
- Dependency scanning - `prod-export-advisory-bucket-1a6c642fc4de57d4`

### Using the gsutil tool to download the package metadata exports

1. Install the [`gsutil`](https://docs.cloud.google.com/storage/docs/gsutil_install) tool.
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

   # For dependency scanning
   export PKG_METADATA_BUCKET=prod-export-advisory-bucket-1a6c642fc4de57d4
   export DATA_DIR="advisories"
   ```

1. Download the package metadata exports.

   ```shell
   # To download the package metadata exports, an outbound connection to Google Cloud Storage bucket must be allowed.
   mkdir -p "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"
   gsutil -m rsync -r -d gs://$PKG_METADATA_BUCKET "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"

   # Alternatively, if the GitLab instance is not allowed to connect to the Google Cloud Storage bucket, the package metadata
   # exports can be downloaded using a machine with the allowed access, and then copied to the root of the GitLab Rails directory.
   rsync rsync://example_username@gitlab.example.com/package_metadata/$DATA_DIR "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/$DATA_DIR"
   ```

### Using the Google Cloud Storage REST API to download the package metadata exports

The package metadata exports can also be downloaded using the Google Cloud Storage API. The contents are available at <https://storage.googleapis.com/storage/v1/b/prod-export-license-bucket-1a6c642fc4de57d4/o> and <https://storage.googleapis.com/storage/v1/b/prod-export-advisory-bucket-1a6c642fc4de57d4/o>. The following is an example of how this can be downloaded using [cURL](https://curl.se/) and [jq](https://stedolan.github.io/jq/).

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
# The script downloads all the objects and creates files with a maximum 1000 objects per file in JSON format.

MAX_RESULTS=1000
TEMP_FILE="out.json"

curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/$PKG_METADATA_BUCKET/o?maxResults=$MAX_RESULTS" >"$TEMP_FILE"
NEXT_PAGE_TOKEN="$(jq -r '.nextPageToken' $TEMP_FILE)"
jq -r '.items[] | [.name, .mediaLink] | @tsv' "$TEMP_FILE" >"$PKG_METADATA_DOWNLOADS_OUTPUT_FILE"

while [ "$NEXT_PAGE_TOKEN" != "null" ]; do
  curl --silent --show-error --request GET "https://storage.googleapis.com/storage/v1/b/$PKG_METADATA_BUCKET/o?maxResults=$MAX_RESULTS&pageToken=$NEXT_PAGE_TOKEN" >"$TEMP_FILE"
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

### Download GitLab malware advisories

{{< details >}}

- Tier: Ultimate
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/20876) in GitLab 19.3 [with flags](../../administration/feature_flags/_index.md) named `sync_malware_advisories` and `ingest_malware_advisories`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249740) in GitLab 19.3.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag. For more information, see the history.
> Besides Ultimate, this feature is available to Premium customers with the dependency firewall add-on.

[GitLab malware advisories](../../user/application_security/gitlab_advisory_database/_index.md#gitlab-malware-advisories) cover known malicious packages found in package registries.
Unlike the license and advisory exports, they are distributed by an authenticated GitLab service, so an offline instance cannot download them itself.
Instead, you download them on a machine with internet access and copy them to the offline instance.
The download script exchanges your license key for a token that is valid for three days.
That machine needs a copy of your license file, but does not need access to the offline instance.

Prerequisites:

- Administrator access.
- An offline license. A legacy license file does not work: the token request fails with `Invalid cloud license` and the script stops. The **Admin** area dashboard shows your license type under **License overview**.
- On the machine with internet access, cURL, jq 1.6 or later, and outbound access to `customers.gitlab.com`, `pmdb-dist-svc.runway.gitlab.net`, and `storage.googleapis.com`. The distribution service is on the `gitlab.net` domain, so an allowlist limited to `gitlab.com` cannot reach it.
- On the offline instance, rsync.

To get an offline license, you must receive an [opt-out exemption of cloud licensing](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing), which requires approval.
For more details, contact your GitLab sales representative.
If you already have an offline license, you can download the file again from the [Customers Portal](https://customers.gitlab.com).

These steps apply to Linux package installations.
In Kubernetes installations the advisories must be on a volume that the Sidekiq pods read, which is tracked in [issue 561085](https://gitlab.com/gitlab-org/gitlab/-/issues/561085).

> [!warning]
> In Docker installations the Rails directory is not on a mounted volume.
> Bind mount `vendor/package_metadata` before you copy the advisories, or they are lost when you upgrade the container.

The following is an example of how the advisories can be downloaded using cURL and jq.

```shell
#!/bin/bash

set -euo pipefail

CDOT_URL="${CDOT_URL:-https://customers.gitlab.com}"
PDS_URL="${PDS_URL:-https://pmdb-dist-svc.runway.gitlab.net}"

if [ $# -lt 4 ]; then
  echo "Usage: download_malware_advisories.sh <license_file> <gitlab_version> <output_dir> <registry>..."
  echo "Pass the package registries to download, or 'all' for every supported registry."
  exit 1
fi

LICENSE_FILE=$1
GITLAB_VERSION=$2
OUTPUT_DIR=$3
shift 3
REQUESTED_REGISTRIES="$*"

if [ -z "$OUTPUT_DIR" ]; then
  echo "output_dir must not be empty"
  exit 1
fi

if [ ! -r "$LICENSE_FILE" ]; then
  echo "Cannot read $LICENSE_FILE"
  exit 1
fi

REQUEST_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
SHARDS_FILE="$(mktemp)"
HEADER_FILE="$(mktemp)"
trap 'rm -f "$REQUEST_FILE" "$RESPONSE_FILE" "$SHARDS_FILE" "$HEADER_FILE"' EXIT
chmod 600 "$HEADER_FILE"

# Exchange the license key for a Cloud Connector token.
GRAPHQL_QUERY='query($licenseKey: String!, $gitlabVersion: String!) {
  cloudConnectorAccess(licenseKey: $licenseKey, gitlabVersion: $gitlabVersion) {
    serviceToken { token }
  }
}'

jq --null-input --arg query "$GRAPHQL_QUERY" --rawfile licenseKey "$LICENSE_FILE" \
  --arg gitlabVersion "$GITLAB_VERSION" \
  '{query: $query, variables: {licenseKey: $licenseKey, gitlabVersion: $gitlabVersion}}' >"$REQUEST_FILE"

HTTP_STATUS="$(curl --silent --show-error --request POST "$CDOT_URL/graphql" \
  --header 'Content-Type: application/json' --data @"$REQUEST_FILE" \
  --output "$RESPONSE_FILE" --write-out '%{http_code}')"

if [ "$HTTP_STATUS" != "200" ]; then
  echo "Token request to $CDOT_URL failed with HTTP $HTTP_STATUS"
  head -c 500 "$RESPONSE_FILE"
  exit 1
fi

TOKEN="$(jq --raw-output '.data.cloudConnectorAccess.serviceToken.token // empty' "$RESPONSE_FILE")"

if [ -z "$TOKEN" ]; then
  echo "No token in the response from $CDOT_URL"
  jq --raw-output '.errors[]?.message // empty' "$RESPONSE_FILE"
  exit 1
fi

# The distribution service requires X-Gitlab-Instance-Id to equal the token's
# subject claim and X-Gitlab-Realm to equal its realm claim. Both are in the
# payload, which is the second dot-separated segment of the token.
CLAIMS="$(printf '%s' "$TOKEN" |
  jq --raw-input 'split(".")[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson')"

INSTANCE_ID="$(jq --raw-output '.sub // empty' <<<"$CLAIMS")"
REALM="$(jq --raw-output '.gitlab_realm // empty' <<<"$CLAIMS")"

if [ -z "$INSTANCE_ID" ] || [ -z "$REALM" ]; then
  echo "The token is missing its subject or realm claim"
  exit 1
fi

# Pass the headers through a file so the token never appears in a process
# list. It is readable there by any local user for the download's duration.
{
  printf 'header = "Authorization: Bearer %s"\n' "$TOKEN"
  printf 'header = "X-Gitlab-Instance-Id: %s"\n' "$INSTANCE_ID"
  printf 'header = "X-Gitlab-Realm: %s"\n' "$REALM"
} >"$HEADER_FILE"

# Writes the response body to $2 and returns the HTTP status.
advisories_request() {
  curl --silent --show-error --config "$HEADER_FILE" \
    --output "$2" --write-out '%{http_code}' "$1"
}

HTTP_STATUS="$(advisories_request "$PDS_URL/v1/malware/advisories/supported" "$RESPONSE_FILE")"

if [ "$HTTP_STATUS" != "200" ]; then
  echo "Request for the supported package registries failed with HTTP $HTTP_STATUS"
  head -c 500 "$RESPONSE_FILE"
  exit 1
fi

SUPPORTED="$(jq --raw-output '.registries[]' "$RESPONSE_FILE")"
SKIPPED=""

if [ -z "$SUPPORTED" ]; then
  echo "No package registries are available"
  exit 1
fi

echo "Available package registries: $(echo "$SUPPORTED" | tr '\n' ' ')"

# Disable filename expansion so a registry name is never treated as a glob.
set -f

if [ "$REQUESTED_REGISTRIES" = "all" ]; then
  REGISTRIES="$SUPPORTED"
else
  REGISTRIES="$REQUESTED_REGISTRIES"

  for REGISTRY in $REGISTRIES; do
    if ! grep --quiet --fixed-strings --line-regexp "$REGISTRY" <<<"$SUPPORTED"; then
      echo "$REGISTRY is not a supported package registry"
      exit 1
    fi
  done
fi

for REGISTRY in $REGISTRIES; do
  HTTP_STATUS="$(advisories_request "$PDS_URL/v1/malware/advisories/all?purl_type=$REGISTRY" "$RESPONSE_FILE")"

  # A pending snapshot is the only skippable outcome. Every other 503 is
  # transient, and treating it as "no data" would delete a registry that the
  # instance already has.
  if [ "$HTTP_STATUS" = "503" ]; then
    # A 503 from in front of the service has no JSON body, so keep the reason
    # empty rather than letting jq abort the script.
    REASON="$(jq --raw-output '.reason // empty' "$RESPONSE_FILE" 2>/dev/null || true)"

    if [ "$REASON" = "snapshot_not_yet_published" ]; then
      echo "Skipping $REGISTRY, no snapshot is published yet"
      SKIPPED="$SKIPPED $REGISTRY"
      continue
    fi

    echo "Request for $REGISTRY failed with HTTP 503, try again later ($REASON)"
    exit 1
  fi

  if [ "$HTTP_STATUS" != "200" ]; then
    echo "Request for $REGISTRY failed with HTTP $HTTP_STATUS"
    head -c 500 "$RESPONSE_FILE"
    exit 1
  fi

  UNTIL="$(jq --raw-output '.until // empty' "$RESPONSE_FILE")"

  if [ -z "$UNTIL" ]; then
    echo "The response for $REGISTRY has no snapshot timestamp"
    exit 1
  fi
  DATASET_DIR="$OUTPUT_DIR/v3/$REGISTRY/full_dataset"

  # Skip the download when this snapshot is already on disk. Every archive in a
  # snapshot shares one `until`, so an unchanged value means no archive changed.
  if [ -r "$DATASET_DIR/checkpoint.json" ] &&
    [ "$(jq --raw-output '.until // empty' "$DATASET_DIR/checkpoint.json" 2>/dev/null)" = "$UNTIL" ]; then
    echo "Skipping $REGISTRY, snapshot $UNTIL is already downloaded"
    continue
  fi

  # Remove any previous snapshot. GitLab reads every archive in this directory,
  # so archives left over from an earlier snapshot would be imported alongside
  # the new ones, restoring advisories that were withdrawn since.
  rm -rf "$DATASET_DIR"
  mkdir -p "$DATASET_DIR"

  jq --raw-output '.shards[] | [.shard, .signed_url] | @tsv' "$RESPONSE_FILE" >"$SHARDS_FILE"

  while IFS=$'\t' read -r SHARD URL; do
    echo "Downloading $REGISTRY archive $SHARD"
    curl --fail --silent --show-error --location --output "$DATASET_DIR/$SHARD.tar.zst.part" "$URL"
    mv "$DATASET_DIR/$SHARD.tar.zst.part" "$DATASET_DIR/$SHARD.tar.zst"
  done <"$SHARDS_FILE"

  # Write the checkpoint last. GitLab ignores a directory that has no
  # checkpoint, so an interrupted download is never imported as a snapshot.
  jq --null-input --argjson until "$UNTIL" '{until: $until}' >"$DATASET_DIR/checkpoint.json"
done

set +f

if [ -n "$SKIPPED" ]; then
  echo "Warning: no snapshot is published yet for:$SKIPPED"
  echo "The downloaded registries are complete and safe to copy. Run the script again later to pick up the rest."
fi

echo "Advisories saved to $OUTPUT_DIR"
```

To download the malware advisories:

1. On the offline instance, find the GitLab version.

   ```shell
   sudo gitlab-rails runner 'puts Gitlab::VERSION'
   ```

1. On the machine with internet access, save the preceding script as `download_malware_advisories.sh` and make it executable.

   ```shell
   chmod +x download_malware_advisories.sh
   ```

1. Run the script with your license file, the GitLab version from the first step, a directory to write to, and the package registries to download.
   Pass the registries whose types are enabled in [admin settings](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync), or `all` for every supported registry.

   ```shell
   ./download_malware_advisories.sh ./Gitlab.gitlab-license 19.3.0-ee ./malware_advisories npm pypi
   ```

   The script creates one directory per package registry.

   ```plaintext
   malware_advisories/
   └── v3/
       └── npm/
           └── full_dataset/
               ├── 00.tar.zst
               ├── 01.tar.zst
               ├── ...
               ├── 3f.tar.zst
               └── checkpoint.json
   ```

   The service sets the number of archives per registry, and names each one for its hexadecimal shard identifier.
   An archive that contains no advisories is expected.

1. Transfer the output directory to the offline instance.

1. On the offline instance, find the root of the GitLab Rails directory, then copy the advisories into place and update the permissions.

   ```shell
   export GITLAB_RAILS_ROOT_DIR="$(sudo gitlab-rails runner 'puts Rails.root.to_s')"
   echo $GITLAB_RAILS_ROOT_DIR
   sudo mkdir -p "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/malware_advisories"
   sudo rsync --recursive --delete ./malware_advisories/ "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/malware_advisories/"
   sudo chmod -R 755 "$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/"
   ```

The `PackageMetadata::MalwareAdvisoriesSyncWorker` cron job runs every five minutes and imports the advisories on its next run.
On GitLab Self-Managed the job adds an offset of up to five minutes to spread load across instances, so the import can start up to ten minutes after you copy the files.
Only the package registry types enabled in [admin settings](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) are imported, so the instance can hold data for registries it never imports.

Repeat this procedure to update the advisories.
Each run downloads a complete snapshot rather than a set of changes.
`rsync --delete` is required so that archives from an earlier snapshot are not imported alongside the new ones.
Reuse the same output directory on every run: `rsync --delete` removes any registry that is missing from it, including registries that were skipped because their snapshot is not published yet.

When the snapshot on the service matches the one already in the output directory, the script skips the download for that registry.

### Automatic synchronization

Your GitLab instance is synchronized [regularly](https://gitlab.com/gitlab-org/gitlab/-/blob/63a187d47f6da353ba4514650bbbbeb99c356325/config/initializers/1_settings.rb#L840-842) with the contents of the `package_metadata` directory.
To automatically update your local copy with the upstream changes, a cron job can be added to periodically download new exports. For example, the following crontabs can be added to set up a cron job that runs every 30 minutes.

For License Scanning:

```plaintext
*/30 * * * * gsutil -m rsync -r -d -y "^v1\/" gs://prod-export-license-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses
```

For dependency scanning:

```plaintext
*/30 * * * * gsutil -m rsync -r -d gs://prod-export-advisory-bucket-1a6c642fc4de57d4 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories
```

### Change note

The directory for package metadata changed with the release of 16.2 from `vendor/package_metadata_db` to `vendor/package_metadata/licenses`. If this directory already exists on the instance and dependency scanning needs to be added then you need to take the following steps.

1. Rename the licenses directory: `mv vendor/package_metadata_db vendor/package_metadata/licenses`.
1. Update any automation scripts or commands saved to change `vendor/package_metadata_db` to `vendor/package_metadata/licenses`.
1. Update any cron entries to change `vendor/package_metadata_db` to `vendor/package_metadata/licenses`.

   ```shell
   sed -i '.bckup' -e 's#vendor/package_metadata_db#vendor/package_metadata/licenses#g' [FILE ...]
   ```

### Troubleshooting

#### Missing database data

If license or advisory data is missing from the dependency list, vulnerability reports, or merge request pages, the database might not have synchronized with the export data.

##### Confirm enabled package registry types

`package_metadata` synchronization is triggered by using cron jobs ([advisory sync](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L864-866) and [license sync](https://gitlab.com/gitlab-org/gitlab/-/blob/16-3-stable-ee/config/initializers/1_settings.rb#L855-857)). Only the package registry types enabled in [admin settings](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) are imported.

For example, if `maven` is selected, but `golang` is not, you will only see advisories and license information for Maven.

##### Confirm correct file structure

The file structure in `vendor/package_metadata` must coincide with the package registry type enabled previously. For example, to sync `maven` license or advisory data, the package metadata directory under the Rails directory must have the following structure where `$GITLAB_RAILS_ROOT_DIR` matches the output of the command `gitlab-rails runner 'puts Rails.root.to_s'`:

- For licenses:`$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/licenses/v2/maven/**/*.ndjson`.
- For advisories:`$GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/advisories/v2/maven/**/*.ndjson`.

You can check if GitLab recognizes the file path in the [Rails console](../../administration/operations/rails_console.md):

- For licenses: `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::LICENSES_PATH)"`
- For advisories: `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::ADVISORIES_PATH)"`

If the above commands return `false`, GitLab is not able to find the expected package path. All folders and files in the path must have `755` permissions. To update the permissions:

`sudo chmod -R 755 $GITLAB_RAILS_ROOT_DIR/vendor/package_metadata/`

##### Verify data

After a sync job is successfully run, data under the `pm_` tables in the database should be populated.

You can confirm by checking how many packages exist for a vendor by using the [Rails console](../../administration/operations/rails_console.md). For example, to confirm that Maven license and advisory data loaded, run:

- For licenses: `sudo gitlab-rails runner "puts \"Package model has #{PackageMetadata::Package.where(purl_type: 'maven').size} packages\""`
- For advisories: `sudo gitlab-rails runner "puts \"Advisory model has #{PackageMetadata::AffectedPackage.where(purl_type: 'maven').size} packages\""`

Additionally, checkpoint data should exist for the particular package registry being synchronized. For Maven, for example, there should be a checkpoint created after a successful sync run:

- For licenses: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'licenses', purl_type: 'maven')}\""`
- For advisories: `sudo gitlab-rails runner "puts \"maven data has been synced up to #{PackageMetadata::Checkpoint.where(data_type: 'advisories', purl_type: 'maven')}\""`

##### Logs

The [`application_json.log`](../../administration/logs/_index.md#application_jsonlog) file will help verify the
sync job has run and is without error. Events associated with the sync will have a `DEBUG` severity and the class is `PackageMetadata::SyncService`.
Example:
`{"severity":"DEBUG","time":"2026-01-07T02:15:49.618Z","meta.caller_id":"PackageMetadata::AdvisoriesSyncWorker","correlation_id":"43008e30dd708eadbe1ab16ad7fa953f","meta.root_caller_id":"Cronjob","meta.feature_category":"software_composition_analysis","meta.client_id":"ip/","class":"PackageMetadata::SyncService","message":"Evaluating data for advisories:offline//opt/gitlab/embedded/service/gitlab-rails/vendor/package_metadata/advisories/v2/maven/1761761049/0.ndjson"}`

The [`sidekiq`](../../administration/logs/_index.md#sidekiq-logs) logs will show if any errors have occurred during the sync job. Events logged for the sync will mention the relevant classes:

- For licenses: `PackageMetadata::LicensesSyncWorker`
- For advisories: `PackageMetadata::AdvisoriesSyncWorker`

#### Missing malware advisory data

If malware advisories are missing after you copy them to the instance, the sync job either did not find the directory or found nothing new to import.
Both outcomes are silent, so work through the following checks rather than looking for an error.

##### Confirm enabled package registry types for malware advisories

Only the package registry types enabled in [admin settings](../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) are imported.
A registry you copied but did not enable is never read, and nothing is logged.

##### Confirm GitLab detects the offline directory

GitLab reads malware advisories from disk when the vendor directory exists, and from the distribution service when it does not.
You can check if GitLab recognizes the file path in the [Rails console](../../administration/operations/rails_console.md):

- `sudo gitlab-rails runner "puts File.exist?(PackageMetadata::SyncConfiguration::Location::MALWARE_ADVISORIES_PATH)"`

If the command returns `false`, GitLab is not able to find the expected path.
All folders and files in the path must have `755` permissions.
In Kubernetes installations, run the command in a pod that mounts the same volume as Sidekiq, otherwise the result does not reflect what the sync job reads.

##### Confirm the malware advisory file structure

Directories are named for the package registry identifier rather than the package type.
These identifiers are not always the same: `gem` advisories are stored under `rubygem`, `golang` under `go`, and `composer` under `packagist`.
A directory named for the package type is ignored, and no error is logged.

Each `full_dataset` directory must also contain a `checkpoint.json`.
GitLab ignores a directory that has no checkpoint, which prevents an interrupted download from being imported.

##### Verify malware advisory data

After a sync job is successfully run, malware advisories should be populated.
You can confirm by counting the advisories in the [Rails console](../../administration/operations/rails_console.md):

- `sudo gitlab-rails runner "puts \"Malware advisory model has #{PackageMetadata::MalwareAdvisory.count} advisories\""`

Checkpoint data should also exist for the package registries you copied:

- `sudo gitlab-rails runner "puts PackageMetadata::Checkpoint.where(data_type: 'malware_advisories').pluck(:purl_type, :sequence).to_h"`

A snapshot is imported only if it is newer than the recorded checkpoint, so copying the same snapshot a second time has no effect.

##### Malware advisory logs

Events associated with the malware advisory sync are logged in
[`application_json.log`](../../administration/logs/_index.md#application_jsonlog) with `INFO` severity.
The class is `PackageMetadata::MalwareAdvisorySyncService` for the sync itself, and
`PackageMetadata::MalwareAdvisoryIngestionService` for the import.
The sync runs in Sidekiq, so in Kubernetes installations these events are on the Sidekiq pods under the
`subcomponent="application_json"` key, not the Webservice pods.

The [`sidekiq`](../../administration/logs/_index.md#sidekiq-logs) logs show any errors that occurred, logged for the
`PackageMetadata::MalwareAdvisoriesSyncWorker` class.

Each registry logs a `started` and a `completed` event per run.
A `completed` event with `files_ingested: 0` means the run found nothing to import.
The `storage_type` field on that event tells you which case you are in: `offline` means GitLab read the vendor directory, and `pds` means it did not find the directory and tried the distribution service instead.
On Kubernetes this field is more reliable than the preceding `File.exist?` check, because it comes from the process that runs the sync.

If no `PackageMetadata::MalwareAdvisorySyncService` events appear at all, look for a `PackageMetadata::MalwareAdvisoriesSyncWorker` event with `DEBUG` severity.
It names the reason the run did not start, such as a disabled `sync_malware_advisories` feature flag.

A `Malware advisory upsert skipped: ingest_malware_advisories disabled` event means the `ingest_malware_advisories` feature flag is off.
The sync reads the files on every run but writes nothing, and the checkpoint does not advance.

A first import of a large registry can run for several minutes, and the cron fires again every five minutes while it does.
Each overlapping run logs `Cannot obtain an exclusive lease. There must be another instance already in execution.` to `application_json.log` with `ERROR` severity and then exits.
The lease is what stops two syncs running at once, so these events are expected during a long import and do not mean the sync failed.
