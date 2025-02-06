---
stage: GitLab Dedicated
group: Environment Automation
description: Maintenance procedures, including regular upgrades, zero-downtime deployments, and emergency maintenance protocols.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maintenance
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

GitLab Dedicated instances receive regular maintenance to ensure security, reliability, and optimal performance.

## Maintenance windows

GitLab leverages [weekly maintenance windows](../../administration/dedicated/maintenance.md#maintenance-windows) to keep your instance up to date, fix security issues, and ensure the overall reliability and performance of your environment.

## Upgrades and patches

Your instance receives regular upgrades during your preferred maintenance window. These upgrades include the latest patch release for the minor version that is one version behind the current GitLab release. For example, if the latest GitLab version is 16.8, your GitLab Dedicated instance runs on 16.7.

Monthly updates include:

- One minor release
- Two patch releases

To view details about your instance, including upcoming scheduled maintenance and the current GitLab version, sign in to Switchboard.

For more information, see the [GitLab release and maintenance policy](../../policy/maintenance.md).

### Zero-downtime upgrades

Deployments follow the process for [zero-downtime upgrades](../../update/zero_downtime.md) to ensure [backward compatibility](../../development/multi_version_compatibility.md) during an upgrade. When no infrastructure changes or maintenance tasks require downtime, using the instance during an upgrade is possible and safe.

During a GitLab version update, static assets may change and are only available in one of the two versions. To mitigate this situation, three techniques are adopted:

1. Each static asset has a unique name that changes when its content changes.
1. The browser caches each static asset.
1. Each request from the same browser is routed to the same server temporarily.

These techniques together give a strong assurance about asset availability:

- During an upgrade, a user routed to a server running the new version receives assets from the same server, eliminating the risk of receiving a broken page.
- If routed to the old version, a regular user has assets cached in their browser.
- If not cached, they receive the requested page and assets from the same server.
- If the specific server is upgraded during the requests, they may still be routed to another server running the same version.
- If the new server is running the upgraded version, and the requested asset changed, then the page may show some user interface glitches.

The effects of an upgrade are usually unnoticeable. However, in rare cases, a new user might experience temporary interface inconsistencies:

- The user connects for the first time during an upgrade.
- They are initially routed to a server running the old version.
- Their subsequent asset requests are directed to a server with the new version.
- The requested assets have changed in the new version.

If this unlikely sequence occurs, refreshing the page resolves any visual inconsistencies.

NOTE:
Implementing a caching proxy in your network further reduces this risk.

## Emergency maintenance

[Emergency maintenance](../../administration/dedicated/maintenance.md#emergency-maintenance) addresses high-severity issues that affect your instance's security, availability, or reliability. When critical patch releases are available, GitLab Dedicated instances are upgraded as soon as possible using emergency maintenance procedures.
