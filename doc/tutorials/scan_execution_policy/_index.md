---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Set up a scan execution policy'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This tutorial shows you how to create and apply a
[scan execution policy](../../user/application_security/policies/scan_execution_policies.md).
These policies enforce application security tools as part of the CI/CD pipeline. In this tutorial,
you create a policy to enforce secret detection in the CI/CD pipeline of two projects.

In this tutorial, you:

- [Create project A](#create-project-a).
- [Create the scan execution policy](#create-the-scan-execution-policy).
- [Test the scan execution policy with project A](#test-the-scan-execution-policy-with-project-a).
- [Create project B](#create-project-b).
- [Link project B to the security policy project](#link-project-b-to-the-security-policy-project).
- [Test the scan execution policy with project B](#test-the-scan-execution-policy-with-project-b).

## Before you begin

- You need permission to create new projects in an existing group.

## Create project A

In a standard workflow, you might already have an existing project. In this
tutorial, you're starting with nothing, so the first step is to create a project.

To create project A:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **New project**.
1. Select **Create blank project**.
1. Complete the fields. For **Project name**, enter `go-example-a`.
1. Select **Create project**.
1. Select **Add (`+`) > New file**.
1. Enter `helloworld.go` in the filename.
1. Copy and paste the following example Go code into the file.

   ```go
   package main
   import "fmt"
   func main() {
       fmt.Println("Hello world")
   }
   ```

1. Select **Commit changes**.

The next step is to create a scan execution policy. When the first security policy is created, a
policy project is created. The policy project stores the security policies created in any projects
that are linked to it. Keeping policies separate from the projects they protect makes your security
configuration reusable and easier to maintain.

## Create the scan execution policy

To create the scan execution policy:

1. On the left sidebar, select **Search or go to** and search for the `go-example-a` project.
1. Go to **Secure > Policies**.
1. Select **New policy**.
1. In the **Scan execution policy** section, select **Select policy**.
1. Complete the fields.
   - **Name**: Enforce secret detection.
   - **Policy status**: Enabled.
   - **Actions**: Run a Secret Detection scan.
   - **Conditions**: Triggers every time a pipeline runs for all branches.
1. Select **Configure with a merge request**.

   The policy project `go-example-a - Security project` is created, and a merge request is created.

1. Optional. Review the generated policy YAML in the merge request's **Changes** tab.
1. Go to the **Overview** tab and select **Merge**.
1. On the left sidebar, select **Search or go to** and search for the `go-example-a` project.
1. Go to **Secure > Policies**.

You now have a scan execution policy that runs a secret detection scan on every MR, for any branch.
Test the policy by creating a merge request in project A.

## Test the scan execution policy with project A

To test the scan execution policy:

1. On the left sidebar, select **Search or go to** and find the project named `go-example-a`.
1. Go to **Code > Repository**.
1. Select the `helloworld.go` file.
1. Select **Edit > Edit single file**.
1. Add the following line immediately after the `fmt.Println("hello world")` line:

   ```plaintext
   var GitLabFeedToken = "feed_token=eFLISqaBym4EjAefkl58"
   ```

1. In the **Target Branch** field, enter `feature-a`.
1. Select **Commit changes**.
1. When the merge request page opens, select **Create merge request**.

   Let's check if the scan execution policy worked. Remember that we specified that secret detection
   is to run every time a pipeline runs, for any branch.

1. In the merge request just created, go the **Pipelines** tab and select the created pipeline.

   Here you can see that a secret detection job ran. Let's check if it detected the test secret.

1. Select the secret detection job.

   Near the bottom of the job's log, the following output confirms that the example secret was detected.

   ```plaintext
   [INFO] [secrets] [2023-09-04T03:46:36Z] ▶ 3:46AM INF 1 commits scanned.
   [INFO] [secrets] [2023-09-04T03:46:36Z] ▶ 3:46AM INF scan completed in 60ms
   [INFO] [secrets] [2023-09-04T03:46:36Z] ▶ 3:46AM WRN leaks found: 1
   ```

You've seen the policy work for one project. Create another project and apply the same policy.

## Create project B

To create project B:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **New project**.
1. Select **Create blank project**.
1. Complete the fields. For **Project name**, enter `go-example-b`.
1. Select **Create project**.
1. Select **Add (`+`) > New file**.
1. Enter `helloworld.go` in the filename.
1. Copy and paste the following example Go code into the file.

   ```go
   package main
   import "fmt"
   func main() {
       fmt.Println("Hello world")
   }
   ```

1. Select **Commit changes**.

Now that you have another project, you link it to the same policy project.

## Link project B to the security policy project

To link project B to the security policy project:

1. On the left sidebar, select **Search or go to** and find the `go-example-b` project.
1. Go to **Secure > Policies**.
1. Select **Edit policy project**.
1. Select the dropdown list, then search for the security policy project created at the start of
   this tutorial.
1. Select **Save**.

Linking project B to the same policy project resulted in the same policy being applied. A scan
execution policy runs a secret detection scan on every MR, for any branch. Let's test the
policy by creating an MR in project B.

## Test the scan execution policy with project B

To test the scan execution policy:

1. On the left sidebar, select **Search or go to** and find the `go-example-b` project.
1. Go to **Code > Repository**.
1. Select the `helloworld.go` file.
1. Select **Edit > Edit single file**.
1. Add the following line immediately after the `fmt.Println("hello world")` line:

   ```plaintext
   var AdobeClient = "4ab4b080d9ce4072a6be2629c399d653"
   ```

1. In the **Target Branch** field, enter `feature-b`.
1. Select **Commit changes**.
1. When the merge request page opens, select **Create merge request**.

   Let's check if the scan execution policy worked. Remember that we specified that secret detection
   is to run every time a pipeline runs, for any branch.

1. In the merge request just created, go the **Pipelines** tab and select the created pipeline.

1. In the merge request just created, select the pipeline's ID.

   Here you can see that a secret detection job ran. Let's check if it detected the test secret.

1. Select the secret detection job.

   Near the bottom of the job's log, the following output confirms that the example secret was detected.

   ```plaintext
   [INFO] [secrets] [2023-09-04T04:22:28Z] ▶ 4:22AM INF 1 commits scanned.
   [INFO] [secrets] [2023-09-04T04:22:28Z] ▶ 4:22AM INF scan completed in 58.2ms
   [INFO] [secrets] [2023-09-04T04:22:28Z] ▶ 4:22AM WRN leaks found: 1
   ```

Congratulations. You've learned how to create a scan execution policy and enforce it on projects.
