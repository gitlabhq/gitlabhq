---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Package Metadata Database
description: What the Package Metadata Database contains, how GitLab synchronizes it, and which data format version each GitLab version reads.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The Package Metadata Database (PMDB) is a collection of license, security advisories and enrichment data for
open source packages, maintained by GitLab.
GitLab instances synchronize PMDB data into the database, where the following features use it:

- [Container scanning for registry](../container_scanning/_index.md#container-scanning-for-registry)
- [Continuous vulnerability scanning](../continuous_vulnerability_scanning/_index.md)
- [Dependency scanning](../dependency_scanning/_index.md)
- [License scanning of CycloneDX files](../../compliance/license_scanning_of_cyclonedx_files/_index.md)

The Package Metadata Database is licensed under the
[EE License](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/LICENSE).

## Datasets

The Package Metadata Database holds four datasets:

| Dataset            | Contents                                              | Used by |
|--------------------|-------------------------------------------------------|---------|
| Licenses           | License data for package versions.                    | License scanning |
| Advisories         | Security advisories for package versions.             | Dependency scanning, continuous vulnerability scanning, and container scanning for registry |
| CVE enrichment     | The EPSS score and KEV status of vulnerabilities.     | [Vulnerability risk assessment data](../vulnerabilities/risk_assessment_data.md) |
| Malware advisories | Known malicious packages found in package registries. | [GitLab malware advisories](../gitlab_advisory_database/_index.md#gitlab-malware-advisories) |

By default, GitLab synchronizes data for all package registry types.
To synchronize less data, clear the package registry types that you do not use in the
[admin settings](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync).

## Data format versions

Each dataset is published in one of two data format versions, v2 or v3.

| Format version | Datasets |
|----------------|----------|
| v2             | Licenses for GitLab 19.3 and earlier, advisories, and CVE enrichment. |
| v3             | Licenses for GitLab 19.4 and later, and malware advisories. |

v3 license data supports Software Package Data Exchange (SPDX) license expressions. For example, `MIT OR Apache-2.0`.

GitLab instances determines which data format version to use:

| GitLab version   | Licenses | Advisories | CVE enrichment | Malware advisories |
|------------------|----------|------------|----------------|--------------------|
| 19.2 and earlier | v2       | v2         | v2             | Not available      |
| 19.3             | v2       | v2         | v2             | v3                 |
| 19.4 and later   | v3       | v2         | v2             | v3                 |

Feature flags control the v3 license data and the malware advisories, and both are enabled by default.

## Synchronization

Cron jobs in Sidekiq synchronize each dataset into the database of your instance.
Each run resumes from the checkpoint that the previous run recorded, so it imports only data
that is newer than what the instance already holds.

### Instances with internet access

An instance with internet access downloads v2 data from the defined GCP buckets and v3 data from a
distribution service.
To download v2 data, the instance needs outbound network access to `storage.googleapis.com`.

### Offline instances

An offline instance cannot download the data itself.
Instead, you download it on a machine with internet access and copy it into the
`vendor/package_metadata` directory of the offline instance.
Downloading v3 data requires an offline license.

When the directory for a dataset exists under `vendor/package_metadata`, GitLab reads that
directory instead of downloading the data.
There is no fallback to the network, so a directory that holds stale data serves stale data
and reports no error.

For the download procedures and feature flag details for each dataset, see
[enabling the Package Metadata Database](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database).

## Related topics

- [Offline environments](../offline_deployments/_index.md)
