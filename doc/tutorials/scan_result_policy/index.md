---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Set up a merge request approval policy'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This tutorial shows you how to create and configure a [merge request approval policy](../../user/application_security/policies/merge_request_approval_policies.md). These policies can be set to take action based on scan results.
For example, in this tutorial, you'll set up a policy that requires approval from two specified users if a vulnerability is detected in a merge request.

To set up a merge request approval policy:

1. [Create a test project](#create-a-test-project).
1. [Add a merge request approval policy](#add-a-merge-request-approval-policy).
1. [Test the merge request approval policy](#test-the-merge-request-approval-policy).

## Before you begin

The namespace used for this tutorial must:

- Contain a minimum of three users, including your own. If you don't have two other users, you must first
  create them. For details, see [Creating users](../../user/profile/account/create_accounts.md).

## Create a test project

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Complete the fields.
   - **Project name**: `sast-scan-result-policy`.
   - Select the **Enable Static Application Security Testing (SAST)** checkbox.
1. Select **Create project**.
1. Go to the newly created project and create [protected branches](../../user/project/repository/branches/protected.md).

## Add a merge request approval policy

Next, you'll add a merge request approval policy to your test project:

1. On the left sidebar, select **Search or go to** and find the `sast-scan-result-policy` project.
1. Select **Secure > Policies**.
1. Select **New policy**.
1. In **Merge request approval policy**, select **Select policy**.
1. Complete the fields.
   - **Name**: `sast-scan-result-policy`
   - **Policy status**: **Enabled**
1. Add the following rule:

   ```plaintext
   IF |Security Scan| from |SAST| find(s) more than |0| |All severity levels| |All vulnerability states| vulnerabilities in an open merge request targeting |All protected branches|
   ```

1. Set **Actions** to the following:

   ```plaintext
   THEN Require approval from | 2 | of the following approvers:
   ```

1. Select two users.
1. Select **Configure with a merge request**.

   The application creates a new project to store the policies linked to it, and creates a merge request to define the policy.

1. Select **Merge**.
1. On the left sidebar, select **Search or go to** and find the `sast-scan-result-policy` project.
1. Select **Secure > Policies**.

   You can see the list of policies added in the previous steps.

## Test the merge request approval policy

Nice work, you've created a merge request approval policy. To test it, create some vulnerabilities and check the result:

1. On the left sidebar, select **Search or go to** and find the `sast-scan-result-policy` project.
1. Select **Code > Repository**.
1. From the **Add** (**{plus}**) dropdown list, select **New file**.
1. In the **Filename** field enter `main.ts`.
1. In the file's content, copy the following:

   ```typescript
   // Non-literal require - tsr-detect-non-literal-require
   var lib: String = 'fs'
   require(lib)

   // Eval with variable - tsr-detect-eval-with-expression
   var myeval: String = 'console.log("Hello.");';
   eval(myeval);

   // Unsafe Regexp - tsr-detect-unsafe-regexp
   const regex: RegExp = /(x+x+)+y/;

   // Non-literal Regexp - tsr-detect-non-literal-regexp
   var myregexpText: String = "/(x+x+)+y/";
   var myregexp: RegExp = new RegExp(myregexpText);
   myregexp.test("(x+x+)+y");

   // Markup escaping disabled - tsr-detect-disable-mustache-escape
   var template: Object = new Object;
   template.escapeMarkup = false;

   // Detects HTML injections - tsr-detect-html-injection
   var element: Element =  document.getElementById("mydiv");
   var content: String = "mycontent"
   Element.innerHTML = content;

   // Timing attack - tsr-detect-possible-timing-attacks
   var userInput: String = "Jane";
   var auth: String = "Jane";
   if (userInput == auth) {
     console.log(userInput);
   }
   ```

1. In the **Commit message** field, enter `Add vulnerable file`.
1. In the **Target Branch** field, enter `test-branch`.
1. Select **Commit changes**. The **New merge request** form opens.
1. Select **Create merge request**.
1. In the new merge request, select `Create merge request`.

   Wait for the pipeline to complete. This could be a few minutes.

The merge request security widget confirms that security scanning detected one potential
vulnerability. As defined in the merge request approval policy, the merge request is blocked and waiting for
approval.

You now know how to set up and use merge request approval policies to catch vulnerabilities!
