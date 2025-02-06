---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test OIDC/OAuth in GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To test OIDC/OAuth in GitLab, you must:

1. [Enable OIDC/OAuth](#enable-oidcoauth-in-gitlab)
1. [Test OIDC/OAuth with your client application](#test-oidcoauth-with-your-client-application)
1. [Verify OIDC/OAuth authentication](#verify-oidcoauth-authentication)

## Prerequisites

Before you can test OIDC/OAuth on GitLab, you must:

- Have a publicly accessible instance.
- Be an administrator for that instance.
- Have a client application that you want to use to test OIDC/OAuth.

## Enable OIDC/OAuth in GitLab

First, you must create OIDC/OAuth application on your GitLab instance. To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Applications**.
1. Select **Add new application**.
1. Fill in the details for your client application, including the name, redirect URI, and allowed scopes.
1. Make sure the `openid` scope is enabled.
1. Select **Save application** to create the new OAuth application.

## Test OIDC/OAuth with your client application

After you've created your OAuth application in GitLab, you can use it to test OIDC/OAuth:

1. You can use <https://openidconnect.net> as the OIDC/OAuth playground.
1. Sign out of GitLab.
1. Visit your client application and initiate the OIDC/OAuth flow, using the GitLab OAuth application you created in the previous step.
1. Follow the prompts to sign in to GitLab and authorize the client application to access your GitLab account.
1. After you've completed the OIDC/OAuth flow, your client application should have received an access token that it can use to authenticate with GitLab.

## Verify OIDC/OAuth authentication

To verify that OIDC/OAuth authentication is working correctly on GitLab, you can perform the following checks:

1. Check that the access token you received in the previous step is valid and can be used to authenticate with GitLab. You can do this by making a test API request to GitLab, using the access token to authenticate. For example:

   ```shell
   curl --header "Authorization: Bearer <access_token>" https://mygitlabinstance.com/api/v4/user
   ```

    Replace `<access_token>` with the actual access token you received in the previous step. If the API request succeeds and returns information about the authenticated user, then OIDC/OAuth authentication is working correctly.

1. Check that the scopes you specified in your OAuth application are being enforced correctly. You can do this by making API requests that require the specific scopes and checking that they succeed or fail as expected.

That's it! With these steps, you should be able to test OIDC/OAuth authentication on your GitLab instance using your client application.
