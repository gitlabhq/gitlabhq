---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DAST on-demand scan
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

Do not run DAST scans against a production server. Not only can it perform any function that a user can, such
as clicking buttons or submitting forms, but it may also trigger bugs, leading to modification or loss of production data.
Only run DAST scans against a test server.

{{< /alert >}}

## On-demand scans

{{< history >}}

- Runner tags selection [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111499) in GitLab 16.3.
- Browser based on-demand DAST scans available in GitLab 17.0 and later because [proxy-based DAST was removed in the same version](../../../update/deprecations.md#proxy-based-dast-deprecated).

{{< /history >}}

An on-demand DAST scan runs outside the DevOps lifecycle. Changes in your repository don't trigger
the scan. You must either start it manually, or schedule it to run. For on-demand DAST scans,
a [site profile](profiles.md#site-profile) defines **what** is to be scanned, and a
[scanner profile](profiles.md#scanner-profile) defines **how** the application is to be scanned.

An on-demand scan can be run in active or passive mode:

- **Passive mode**: The default mode, which runs a [Passive Browser based scan](browser/_index.md#passive-scans).
- **Active mode**: Runs an [Active Browser based scan](browser/_index.md#active-scans) which is potentially harmful to the site being scanned. To
  minimize the risk of accidental damage, running an active scan requires a
  [validated site profile](profiles.md#site-profile-validation).

### View on-demand DAST scans

To view on-demand scans:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **On-demand scans**.

On-demand scans are grouped by their status. The scan library contains all available on-demand
scans.

### Run an on-demand DAST scan

Prerequisites:

- You must have permission to run an on-demand DAST scan against a protected branch. The default
  branch is automatically protected. For more information, see
  [Pipeline security on protected branches](../../../ci/pipelines/_index.md#pipeline-security-on-protected-branches).

To run an existing on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **On-demand scans**.
1. Select the **Scan library** tab.
1. In the scan's row, select **Run scan**.

   If the branch saved in the scan no longer exists, you must:

   1. [Edit the scan](#edit-an-on-demand-scan).
   1. Select a new branch.
   1. Save the edited scan.

The on-demand DAST scan runs, and the project's dashboard shows the results.

#### Create an on-demand scan

Create an on-demand scan to:

- Run it immediately.
- Save it to be run in the future.
- Schedule it to be run at a specified schedule.

To create an on-demand DAST scan:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **On-demand scans**.
1. Select **New scan**.
1. Complete the **Scan name** and **Description** fields.
1. In the **Branch** dropdown list, select the desired branch.
1. Optional. Select the runner tags.
1. Select **Select scanner profile** or **Change scanner profile** to open the drawer, and either:
   - Select a scanner profile from the drawer, **or**
   - Select **New profile**, create a [scanner profile](profiles.md#scanner-profile), then select **Save profile**.
1. Select **Select site profile** or **Change site profile** to open the drawer, and either:
   - Select a site profile from the **Site profile library** drawer, or
   - Select **New profile**, create a [site profile](profiles.md#site-profile), then select **Save profile**.
1. To run the on-demand scan:

   - Immediately, select **Save and run scan**.
   - In the future, select **Save scan**.
   - On a schedule:

     - Turn on the **Enable scan schedule** toggle.
     - Complete the schedule fields.
     - Select **Save scan**.

The on-demand DAST scan runs as specified and the project's dashboard shows the results.

### View details of an on-demand scan

Prerequisites:

- You must be able to push to the branch associated with the DAST scan.

To view details of an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** ({{< icon name="ellipsis_v" >}}), then select **Edit**.

### Edit an on-demand scan

Prerequisites:

- You must be able to push to the branch associated with the DAST scan.

To edit an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** ({{< icon name="ellipsis_v" >}}), then select **Edit**.
1. Edit the saved scan's details.
1. Select **Save scan**.

### Delete an on-demand scan

Prerequisites:

- You must be able to push to the branch associated with the DAST scan.

To delete an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** ({{< icon name="ellipsis_v" >}}), then select **Delete**.
1. On the confirmation dialog, select **Delete**.
