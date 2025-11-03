---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Protect your project with pipeline secret detection'
---

<!-- vale gitlab_base.FutureTense = NO -->

If your application uses external resources, you usually need to authenticate your application with a secret,
like a token or key. If a secret is pushed to a remote repository, anyone with access to the repository can impersonate
you or your application.

Pipeline secret detection uses a CI/CD job to check your GitLab project for secrets. In this tutorial,
you'll create a project, configure pipeline secret detection, and learn how to analyze its results:

1. [Create a project](#create-a-project)
1. [Check the job output](#check-the-job-output)
1. [Enable merge request pipelines](#enable-merge-request-pipelines)
1. [Add a fake secret](#add-a-fake-secret)
1. [Triage the secret](#triage-the-secret)
1. [Remediate a leak](#remediate-a-leak)

## Before you begin

Before you begin this tutorial, make sure you have the following:

- A GitLab.com account. To take advantage of all the features of pipeline secret detection, you should use an account with Ultimate if you have one.
- Some familiarity with CI/CD.

## Create a project

First, create a project and enable secret detection:

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) > **New project/repository**. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Create blank project**.
1. Enter the project details:
   1. Enter a name and project slug.
   1. From the **Project deployment target (optional)** dropdown list, select **No deployment planned**.
   1. Select the **Initialize repository with a README** checkbox. This will give you a place to add content to the project later.
   1. Select the **Enable Secret Detection** checkbox.
1. Select **Create project**.

A new project is created and initialized with a README and `.gitlab-ci.yml` file.
The CI/CD configuration includes the `Security/Secret-Detection.gitlab-ci.yml` template,
which enables pipeline secret detection in the project.

## Check the job output

Pipeline secret detection runs in a CI/CD job called `secret_detection`.
Scan results are written to the CI/CD job log. Each scan also produces a comprehensive report as a job artifact.

To check the results of the most recent scan:

1. On the left sidebar, select **Build** > **Jobs**.
1. Select the most recent `secret_detection` job. If you haven't run a new pipeline, there should be only one job.
1. Check the log output for the following:
   - Information about the scan, including the analyzer version and ruleset. Your project uses the default ruleset because you enabled secret detection automatically.
   - Whether any secrets were detected. You should see `no leaks found`.
1. To download the full report, under **Job artifacts**, select **Download**.

## Enable merge request pipelines

So far, we've used pipeline secret detection to scan commits in the
default branch. But to analyze commits in merge requests before you
merge them to the default branch, you need to enable merge request
pipelines.

To do this:

1. Add the following lines to your `.gitlab-ci.yml` file:

   ```yaml
   variables:
     AST_ENABLE_MR_PIPELINES: "true"
   ```

1. Save the changes and commit them to the `main` branch of your project.

## Add a fake secret

Next, let's complicate the output of the job by "leaking" a fake secret in a merge request:

1. Check out a new branch:

   ```shell
   git checkout -b pipeline-sd-tutorial
   ```

1. Edit your project README and add the following lines.
   Be sure to remove the spaces before and after the `-` to match the exact format of a personal access token:

   ```markdown
   # To make the example work, remove
   # the spaces before and after the dash:
   glpat - 12345678901234567890
   ```

1. Commit and push your changes, then open a merge request to merge them to the default branch.

   A merge request pipeline is automatically run.
1. Wait for the pipeline to finish, then check the job log. You should see `WRN leaks found: 1`.
1. Download the job artifact and check to make sure it contains the following information:
   - The secret type. In this example, the type is `"GitLab personal access token"`.
   - A description of what the secret is used for, with some steps you can take to remediate the leak.
   - The severity of the leak. Because personal access tokens can be used to impersonate users on GitLab.com, this leak is `Critical`.
   - The raw text of the secret.
   - Some information about where the secret is located:

     ```json
     "file": "README.md",
     "line_start": 97,
     "line_end": 97,
     ```

     In this example, the secret is on line 97 of the file `README.md`.

### Using the merge request security widget

{{< details >}}

- Tier: Ultimate

{{< /details >}}

A secret detected on a non-default branch is called a "finding."
When a finding is merged to the default branch, it becomes a "vulnerability."

The merge request security widget displays a list of findings that could become vulnerabilities
if the merge request is merged.

To view the widget:

1. Select the merge request you created in the previous step.
1. Find the merge request security widget, which starts with **Security scanning**.
1. On the widget, select **Show details** ({{< icon name="chevron-down" >}}).
1. Review the displayed information. You should see **Secret detection detected 1 new potential vulnerability**.

For a detailed view of all the findings in a merge request, select **View all pipeline findings**.

## Triage the secret

{{< details >}}

- Tier: Ultimate

{{< /details >}}

On GitLab Ultimate, job output is also written to:

- The pipeline's **Security** tab.
- If a finding becomes a vulnerability, the vulnerability report.

To demonstrate how you can triage a secret by using the UI, let's create a vulnerability and change its
status in the vulnerability report:

1. Merge the MR you created in the last step, then wait for the pipeline to finish.

   The fake secret is added to `main`, which causes the finding to become a vulnerability.
1. On the left sidebar, select **Secure** > **Vulnerability report**.
1. Select the vulnerability's **Description** to view:
   - Details about the secret type.
   - Remediation guidance.
   - Information about when and where the vulnerability was detected.
1. Select **Edit vulnerability** > **Change status**.
   1. From the **Status** dropdown list, select **Dismiss as... Used in tests**.
   1. Add a comment that explains why you added the fake secret to your project.
   1. Select **Change status**.

The vulnerability no longer appears on the front page of the vulnerability report.

## Remediate a leak

If you add a secret to a remote repository, that secret is no longer secure and must be revoked as soon as possible.
You should revoke and replace secrets even if they haven't been merged to your default branch.

The exact steps you take to remediate a leak will depend on your organization's security policies,
but at a minimum, you should:

1. Revoke the secret. When a secret is revoked, it is no longer valid and cannot be used to impersonate legitimate activity.
1. Remove the secret from your repository.

Specific remediation guidance is written to the `secret-detection` job log, and is available on the vulnerability report details page.
