---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: Documentation about GitLab Duo licensing options for local development
title: GitLab Duo licensing for local development
---

This document explains the different licensing options available for GitLab Duo features in local development environments.

> **Note:** When developing GitLab Duo features, it's important to test in both multi-tenant (GitLab.com) and single-tenant (Self-managed/Dedicated) environments where appropriate. There is no default or recommended approach - the setup you choose should be based on your specific testing requirements.

## Overview

GitLab Duo features require either Duo Pro or Duo Enterprise licensing. When developing locally, there are multiple approaches to set up licensing, each serving different development needs.

This guide helps you understand:

- Which licensing approach to use for your specific development needs
- How to set up each licensing option
- The trade-offs between different approaches

## Quick reference

You should choose a license setup based on your development needs. Each approach provides a different testing environment:

| Development Scenario | License Setup | Instructions |
|----------------------|---------------------------|-------------|
| Multi-tenant setup (GitLab.com) | Local license with Rake task | [Option A](#option-a-local-license-with-rake-task-multi-tenantgitlabcom-mode) |
| Single-tenant setup (Self-managed/Dedicated) | Local license with Rake task in self-managed mode | [Option B](#option-b-local-license-with-rake-task-in-self-managed-mode-single-tenant-setup) |
| Full dog-fooding experience | Cloud license via CustomersDot | [Option C](#option-c-cloud-license-via-customersdot) |

## Prerequisites for all options

### Install AI gateway

**Why:** Duo features (except for Duo Workflow) route LLM requests through the AI gateway.

**How:**
Follow [these instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#install)
to install the AI gateway with GDK. We recommend this route for most users.

You can also install AI gateway by:

1. [Cloning the repository directly](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).
1. [Running the server locally](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally).

We only recommend this for users who have a specific reason for *not* running
the AI gateway through GDK.

### Set up GitLab Team Member License

**Why:** GitLab Duo is available to Premium and Ultimate customers only. You
likely want an Ultimate license for your GDK. Ultimate gets you access to
all GitLab Duo features.

**How:**

Follow [the process to obtain an EE license](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses)
for your local instance and [upload the license](../../administration/license_file.md).

To verify that the license is applied, go to **Admin area** > **Subscription**
and check the subscription plan.

## Option A: Local license with Rake task (Multi-tenant/GitLab.com mode)

This approach configures your environment to behave like GitLab.com (multi-tenant) for Duo features development.

### When to use

- When you need to test in a multi-tenant environment (similar to GitLab.com)
- When developing features that are specific to or need validation in GitLab.com
- When testing integration points that behave differently in multi-tenant mode

### Setup steps

- Ensure that you have a [GitLab Team Member License](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses) and that it is [activated](../../administration/license_file.md).
- Run the Rake task to set up Duo features for a group:

```shell
GITLAB_SIMULATE_SAAS=1 bundle exec 'rake gitlab:duo:setup'
```

- Restart your GDK:

```shell
gdk restart
```

- This Rake task creates a Duo Enterprise add-on attached to your group and assigns a Duo add-on seat to the 'root' user.

> **Note:** This Rake task primarily creates database records to simulate licensing in your development environment. With `GITLAB_SIMULATE_SAAS=1`, the environment is configured to behave like GitLab.com and allows self-signing tokens automatically.

- If you need to set up a Duo Pro add-on instead, run this Rake task:

```shell
GITLAB_SIMULATE_SAAS=1 bundle exec 'rake gitlab:duo:setup[pro]'
```

### Pros

- Quick setup for multi-tenant testing
- No need to connect to external services
- Simulates the GitLab.com environment
- No need to set `CLOUD_CONNECTOR_SELF_SIGN_TOKENS` as it's handled automatically

### Cons

- Not a true representation of how real cloud customers would experience the setup
- May mask issues that only appear in production environments with real cloud licensing

## Option B: Local license with Rake task in self-managed mode (Single-tenant setup)

This approach configures your environment to behave like a self-managed or Dedicated GitLab instance (single-tenant).

### When to use

- When you need to test in a single-tenant environment (similar to Self-managed or Dedicated)
- When developing features that are specific to or need validation in self-managed or Dedicated environments
- When testing integration points that behave differently in single-tenant mode

### Setup steps

- Ensure that you have a [GitLab Team Member License](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses) and that it is [activated](../../administration/license_file.md).
- Run the Rake task to set up Duo features for the instance in self-managed mode:

```shell
GITLAB_SIMULATE_SAAS=0 bundle exec 'rake gitlab:duo:setup'
```

- Restart your GDK:

```shell
gdk restart
```

- This Rake task creates a Duo Enterprise add-on attached to your instance and assigns a Duo add-on seat to the 'root' user.

> **Note:** This Rake task primarily creates database records to simulate licensing in your development environment.

- For self-managed mode, you need to configure environment variables for self-signing tokens:

```shell
# <GDK-root>/env.runit

export CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
```

- Restart GDK again to apply the change.

> **Note:** In self-managed mode, `CLOUD_CONNECTOR_SELF_SIGN_TOKENS` is required to allow your local GitLab instance to issue tokens itself, without syncing with CustomersDot. With `GITLAB_SIMULATE_SAAS=1` (Option A), this variable is not needed but can be left in place when switching between modes as it doesn't interfere with multi-tenant operation.

### Pros

- Quick setup for single-tenant testing
- No need to connect to external services
- Simulates self-managed/Dedicated environments

### Cons

- Not a true representation of how real self-managed customers would experience the setup
- May mask issues that only appear in production environments with real cloud licensing

## Option C: Cloud license via CustomersDot

This approach uses a real cloud license through CustomersDot, providing the most authentic testing environment that matches what customers experience.

### When to use

- When testing or updating functionality related to cloud licensing
- When you need to use the staging AI Gateway or want to run CustomersDot and the AI gateway locally
- When you want to fully dog-food the customer experience
- When troubleshooting issues specific to license validation in production

### Setup steps

- Add a **Self-Managed Ultimate** subscription with a [Duo Pro or Duo Enterprise subscription add-on](../../subscriptions/subscription-add-ons.md) to your GDK instance.
  - Sign in to the [staging Customers Portal](https://customers.staging.gitlab.com) by selecting the **Continue with GitLab.com account** button. If you do not have an existing account, you are prompted to create one.
  - If you do not have an existing cloud activation code, visit the **Self-Managed Ultimate Subscription** page using the [buy subscription flow link](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/8aa922840091ad5c5d96ada43d0065a1b6198841/doc/flows/buy_subscription.md).
  - Purchase the subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com/#testing-credit-card-information).
  - Once you have a subscription, on the subscription card, select the ellipse menu **...** > **Buy Duo Pro add-on** (or Duo Enterprise if needed).
  - Use the previously saved credit card information, and the same number of seats as in the subscription.

- Follow the activation instructions:

  - Set environment variables:

      ```shell
      export GITLAB_LICENSE_MODE=test
      export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
      ```

  - **Note on GDK and AI Gateway:** While GDK can include AI Gateway as part of its distribution, developers may run AI Gateway with different configurations or ports. Currently, GitLab instances need explicit configuration of the AI Gateway URL, even in development environments.

  - If you need to connect to the staging AI Gateway, configure it through the Admin UI (this option is only available with Ultimate license and active Duo Enterprise add-on):

    1. Go to **Admin Area** > **Settings** > **GitLab Duo** > **Self-hosted models**
    1. Set the **AI Gateway URL** to `https://cloud.staging.gitlab.com/ai`
    1. Click **Save changes**

  - Alternatively, you can set the AI gateway URL in a Rails console (useful when you don't have access to the Admin UI):

      ```ruby
      Ai::Setting.instance.update!(ai_gateway_url: 'https://cloud.staging.gitlab.com/ai')
      ```

  - Restart your GDK.
  - Go to `/admin/subscription`.
  - Optional. Remove any active license.
  - Add the new activation code.

- Inside your GDK, navigate to **Admin area** > **GitLab Duo Pro**, go to `/admin/code_suggestions`
- Filter users to find `root` and click the toggle to assign a GitLab Duo Pro add-on seat to the root user.

### Pros

- Provides the most authentic testing environment
- Required for testing with staging AI Gateway
- Tests the complete flow including cloud license validation
- Most closely mirrors customer experience

### Cons

- Significantly more complex to set up
- Requires interaction with external services
- Time-consuming to configure

### Future improvements

> **Note:** There are ongoing plans to streamline the configuration of AI Gateway in development environments to reduce manual setup steps. In the future, we aim to automate this process as part of the GDK setup. For now, please follow the manual configuration steps described above.

## Setting up Duo on your GitLab.com staging account

When working in staging environments, you may need to set up Duo add-ons for your staging account. This is different from setting up your local development environment.

> **Note:** This section contains the same information as the previous [Staging account setup](staging_accounts.md) document, which now redirects here.

### Duo Pro

1. Have your account ready at <https://staging.gitlab.com>.
1. [Create a new group](../../user/group/_index.md#create-a-group) or use an existing one as the namespace which will receive the Duo Pro access.
1. Go to **Settings > Billing**.
1. Initiate the purchase flow for the Ultimate plan by clicking on `Upgrade to Ultimate`.
1. After being redirected to <https://customers.staging.gitlab.com>, click on `Continue with your Gitlab.com account`.
1. Purchase the SaaS Ultimate subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com#testing-credit-card-information).
1. Find the newly purchased subscription card, and select from the three dots menu the option `Buy GitLab Duo Pro`.
1. Purchase the GitLab Duo Pro add-on using the same test credit card from the above steps.
1. Go back to <https://staging.gitlab.com> and verify that your group has access to Duo Pro by navigating to `Settings > GitLab Duo` and managing seats.

### Duo Enterprise

**Internal use only:** Given that purchasing a license for Duo Enterprise is not self-serviceable, post a request in the `#g_provision` Slack channel to grant access to your customer staging account with a Duo Enterprise license.

## Testing your setup

In the Admin Area, you can run [a health check](../../user/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)
to see if Duo is correctly set up.

## Troubleshooting

If you're having issues with your Duo license setup:

- Verify your license is active by checking the Admin Area
- Ensure your user has a Duo seat assigned
- Run the [Duo health check](../../user/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo) to identify specific issues
- Check logs for any authentication or license validation errors
- For cloud license issues, reach out to `#s_fulfillment_engineering` in Slack
- For AI Gateway connection issues, reach out to `#g_cloud_connector` in Slack

## Best Practices

- **Test in both environments**: For thorough testing, consider alternating between multi-tenant and single-tenant setups to ensure your feature works well in both environments.
- **Consult domain documentation**: Review specific feature documentation to understand if there are any environment-specific behaviors you need to consider.
- **Consider end-user context**: Remember that features should work well for both GitLab.com users and self-managed/dedicated customers.

## Additional resources

- [AI Features Documentation](../ai_features/_index.md)
- [Code Suggestions Development](../ai_features/code_suggestions.md)
- [License Management Guidelines for Code Suggestions](../ai_features/code_suggestions.md#setup-instructions-to-use-gdk-with-the-code-suggestions-add-on)
- [Duo Enterprise License Access Process for Staging Environment](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/duo/duo_license.md?ref_type=heads)
