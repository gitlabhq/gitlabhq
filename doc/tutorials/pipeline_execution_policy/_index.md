---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "Tutorial: Set up a pipeline execution policy"
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This tutorial shows you how to create and configure a [pipeline execution policy](../../user/application_security/policies/pipeline_execution_policies.md) with `inject_policy` strategy. You can use these policies to ensure that required pipelines are always run in projects that the policy is linked to.

In this tutorial, you can create a pipeline execution policy, link it to a test project, and verify that the pipeline executes.

To set up a pipeline execution policy, you:

1. [Create a test project](#create-a-test-project).
1. [Create a CI/CD configuration file](#create-a-cicd-configuration-file).
1. [Add a pipeline execution policy](#add-a-pipeline-execution-policy).
1. [Test the pipeline execution policy](#test-the-pipeline-execution-policy).

## Before you begin

To complete this tutorial, you need:

- Permissions to create projects in an existing group.
- Permissions to create and link to security policies.

## Create a test project

To begin, create a test project to apply your pipeline execution policy to:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **New project**.
1. Select **Create blank project**.
1. Complete the fields.
   - **Project name**: `my-pipeline-execution-policy`.
   - Select the **Enable Static Application Security Testing (SAST)** checkbox.
1. Select **Create project**.

## Create a CI/CD configuration file

Next, create the CI/CD configuration file that you want your pipeline execution policy to enforce:

1. Select **Code** > **Repository**.
1. From the **Add** (+) dropdown list, select **New file**.
1. In the **Filename** field, enter `pipeline-config.yml`.
1. In the file's content, copy the following:

   ```yaml
   # This file defines the CI/CD jobs that will be enforced by the pipeline execution policy
   enforced-security-scan:
     stage: .pipeline-policy-pre
     script:
       - echo "Running enforced security scan from pipeline execution policy"
       - echo "This job cannot be skipped by developers"
       - echo "Checking for security vulnerabilities..."
       - echo "Security scan completed successfully"
     rules:
       - when: always

   enforced-test-job:
     stage: test
     script:
      - echo "Running enforced test job in test stage"
      - echo "Creating test stage if it doesn't exist"
      - echo "Performing mandatory testing requirements..."
      - echo "Enforced tests completed successfully"
    rules:
      - when: always

   enforced-compliance-check:
     stage: .pipeline-policy-post
     script:
       - echo "Running enforced compliance check"
       - echo "Verifying pipeline compliance requirements"
       - echo "Compliance check passed"
     rules:
       - when: always
   ```

1. In the **Commit message** field, enter `Add pipeline execution policy configuration`.
1. Select **Commit changes**.

## Add a pipeline execution policy

Next, add a pipeline execution policy to your test project:

1. Select **Secure** > **Policies**.
1. Select **New policy**.
1. In **Pipeline execution policy**, select **Select policy**.
1. Complete the fields.
   - **Name**: `Enforce Security and Compliance Jobs`
   - **Description**: `Enforces required security and compliance jobs across all pipelines`
   - **Policy status**: **Enabled**

1. Set **Actions** to the following:

   ```plaintext
   Inject into into the .gitlab-ci.yml with the pipeline execution file from My Pipeline Execution Policy
   Filepath: [group]/my-pipeline-execution/policy/pipeline-config.yml
   ```

1. Select **Configure with a merge request**.

1. Review the generated policy YAML in the merge request's **Changes** tab. The policy should look similar to:

   ```yaml
   ---
   pipeline_execution_policy:
   - name: Enforce Security and Compliance Jobs
     description: Enforces required security and compliance jobs across all pipelines
     enabled: true
     pipeline_config_strategy: inject_policy
     content:
       include:
       - project: [group]/my-pipeline-execution-policy
         file: pipeline-config.yml
     skip_ci:
       - allowed: false
   ```

1. Go to the **Overview** tab and select **Merge**. This step creates a new project called `My Pipeline Execution Policy - Security Policy Project`. Security policy projects are used to store security policies so the same policy can be enforced across multiple projects.

1. On the left sidebar, select **Search or go to** and find the `my-pipeline-execution-policy` project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.

1. Select **Secure** > **Policies**.

   You can see the list of policies added in the previous steps.

## Test the pipeline execution policy

Now test your pipeline execution policy by creating a merge request:

1. Select **Code** > **Repository**.
1. From the **Add** (+) dropdown list, select **New file**.
1. In the **Filename** field, enter `test-file.txt`.
1. In the file's content, add:

   ```plaintext
   This is a test file to trigger the pipeline execution policy.
   ```

1. In the **Commit message** field, enter `Add test file to trigger pipeline`.
1. In the **Target Branch** field, enter `test-policy-branch`.
1. Select **Commit changes**.
1. When the merge request page opens, select **Create merge request**.

   Wait for the pipeline to complete. This could take a few minutes.

1. In the merge request, select the **Pipelines** tab and select the created pipeline.

   You should see the enforced jobs running:
   - `enforced-security-scan` in the `.pipeline-policy-pre` stage (runs first)
   - `enforced-test-job` in the `test` stage (injected by the policy)
   - `enforced-compliance-check` in the `.pipeline-policy-post` stage (runs last)

1. Select the `enforced-security-scan` job to view its logs and confirm it executed the security scan as defined in the policy.

The pipeline execution policy successfully enforced the required jobs, ensuring they run regardless of what the developer includes in their project's `.gitlab-ci.yml` file.

You now know how to set up and use pipeline execution policies to enforce the use of required CI/CD jobs across projects in your organization!

## Next steps

- Learn more about [pipeline execution policy configuration strategies](../../user/application_security/policies/pipeline_execution_policies.md#pipeline-configuration-strategies).
- Explore [advanced pipeline execution policy examples](../../user/application_security/policies/pipeline_execution_policies.md#examples).
