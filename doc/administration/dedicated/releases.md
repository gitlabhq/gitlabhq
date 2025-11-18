---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Release schedules, versioning model, and patch processes for GitLab Dedicated instances.
title: GitLab Dedicated releases and versioning
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated follows a specific versioning model and release schedule
for your instance to balance stability with access to new features and security patches.

## Versioning model

Your instance runs on the previous minor version (`N-1`) relative to the
current GitLab release. For example, when GitLab 16.9 is available,
your instance runs GitLab 16.8.

This approach provides:

- Stability: Additional time for testing and validation before deployment.
- Security: Critical patches are still applied promptly through emergency maintenance.
- Predictability: Regular upgrade schedule aligned with monthly release cycles.

New features become available on your instance approximately 1 month after their
initial GitLab release.

## Check your GitLab version

You can check your GitLab version through GitLab itself or through Switchboard.

To check your GitLab version:

- In GitLab: On the left sidebar, at the bottom, select **Help** ({{< icon name="question" >}}) > **Help**,
  or visit `https://your-instance-url/help` directly.
- In Switchboard: See [tenant overview](tenant_overview.md).

## Release rollout schedule

Your instance is upgraded during scheduled maintenance windows according
to a staggered timeline that begins 5 days after each GitLab release.

Upgrades occur during your assigned maintenance window according to the following
schedule, where `T` is the date of a minor GitLab release:

| Calendar days after release | Instance upgrades begin |
| --------------------------- | ----------------------- |
| `T`+5                       | EMEA and Americas (Option 1) regions |
| `T`+6                       | Asia Pacific region     |
| `T`+10                      | Americas (Option 2) region |

For example, GitLab 16.9 released on 2024-02-15. Instances in the EMEA and Americas
(Option 1) regions were upgraded to 16.8 on 2024-02-20, 5 days after the 16.9 release.

If maintenance is deferred due to operational constraints, upgrades occur
in the next available maintenance window.

## Update frequency

Your instance receives regular updates during your preferred maintenance window:

Monthly updates include:

- One minor release
- Two patch releases

Additional updates might include:

- Critical security patches through emergency maintenance
- Infrastructure improvements
- Performance optimizations

## Patch validation timeline

Critical patches follow an accelerated timeline to ensure security vulnerabilities are addressed quickly:

1. Development: Bug fixes must be merged into the stable branch at least two business days before the expected patch release date.
1. Patch release: A patch is released for a security vulnerability or critical bug.
1. Validation (0-24 hours): The patch is validated in staging environments.
1. Emergency deployment: The patch is deployed to your instance through emergency maintenance procedures.

### Patch release schedule

Monthly releases occur during the week that follows the third Thursday of each month.

Critical patches are released twice monthly on:

- Wednesday before the monthly release week
- Wednesday after the monthly release week

For example, if the third Thursday is January 16, 2025:

- Monthly release week: January 20-24, 2025
- First patch release: January 15, 2025 (Wednesday before)
- Second patch release: January 29, 2025 (Wednesday after)

Non-critical patches are deployed to your instance in the next scheduled maintenance window.

## Internal releases

Internal releases are private releases used to remediate critical security vulnerabilities and high-severity bugs on GitLab
Dedicated instances before public disclosure. These releases are deployed through
[emergency maintenance procedures](maintenance.md#emergency-maintenance).

Critical fixes that can't wait for the next scheduled patch are delivered through internal releases to ensure your
instance remains secure and stable.

## Bug fixes

GitLab engineering teams work to include bug fixes and performance improvements
in your version during scheduled maintenance windows.
These fixes are included proactively without action required from you.

### Request a bug fix

You can request a specific bug fix if it hasn't been included in your version.

To request a bug fix:

1. Submit a support ticket with a link to the merge request or issue that contains the fix.
1. Wait for a response about whether the request is approved.

If approved, the fix is included in your next scheduled maintenance window.

{{< alert type="note" >}}

Not all fixes can be backported due to dependencies, complexity, or compatibility
considerations. Each request is evaluated individually.

{{< /alert >}}

## Related topics

- [GitLab Dedicated maintenance operations](maintenance.md)
- [GitLab release and maintenance policy](../../policy/maintenance.md)
