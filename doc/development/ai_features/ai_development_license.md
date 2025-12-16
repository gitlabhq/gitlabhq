---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
description: Documentation about GitLab Duo licensing options for local development
title: GitLab Duo licensing for local development
---

To use GitLab Duo Features, you need to:

- Use GitLab enterprise edition
- Have an online cloud license
- Have either Premium or Ultimate Subscription License plan
- Have one of the GitLab Duo add-ons in addition to your license plan (GitLab Duo Core, GitLab Duo Pro, or GitLab Duo Enterprise)

This document walks you through how to get ensure these requirements are met for your GDK.

## Set up GitLab Team Member License for GDK

**Why**: Cloud licenses are mandatory for our cloud connected GitLab Duo features for
GitLab Self-Managed and Dedicated customers. As opposed to "legacy" GitLab
licenses, cloud licenses require internet connectivity to validate with
`customers.gitlab.com` (CustomersDot). GitLab periodically checks license
validity, and provides automatic updates to subscription changes through
CustomersDot.

GitLab Duo is available to Premium and Ultimate customers only. You likely want
an Ultimate license for your GDK. Ultimate gets you access to all GitLab Duo
features. Premium gets access to only a subset of GitLab Duo features.

**How**:

1. Follow [the process to obtain an Ultimate license](https://handbook.gitlab.com/handbook/support/internal-support#gitlab-plan-or-license-for-team-members)
   for your local instance. Start with a GitLab Self-Managed Ultimate license. After you have a GitLab Self-Managed license configured, you can always [simulate a SaaS instance](../ee_features.md#simulate-a-saas-instance) and assign individual groups Premium and Ultimate licenses in the admin panel.
1. [Upload your license activation code](../../administration/license.md#activate-gitlab-ee)
1. [Set environment variables](https://gitlab-org.gitlab.io/gitlab-development-kit/contributing/runit/#using-environment-variables) in GDK:

      ```shell
      export GITLAB_LICENSE_MODE=test
      export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
      export CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
      ```

## (Alternatively) Connect to staging AI Gateway

Developers may also choose to connect their local GitLab instance to the staging AI Gateway instance.

To connect to the staging AI Gateway:

- Set the `DEVELOPMENT_AI_GATEWAY_URL` environment variable to `https://cloud.staging.gitlab.com`
- `AI_GATEWAY_URL` is unset and `Ai::Setting.instance.ai_gateway_url` is `nil`
- Restart your GDK.

## Troubleshooting

If you're having issues with your GitLab Duo license setup:

- Run the [GitLab Duo health check](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo) to identify specific issues. Note that if you have GitLab Duo licenses that were generated from a setup script locally, this will show "Cloud Connector access token is missing" but that is OK.
- Verify your license is active by checking the Admin Area
- Ensure your user has a GitLab Duo seat assigned. The GDK setup scripts assign a GitLab Duo
  seat to the `root` user only. If you want to test with other users, make sure
  to [assign them a seat](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- To more deeply debug why the root user cannot access a feature like GitLab Duo Chat, you can run `GlobalPolicy.new(User.first, User.first).debug(:access_duo_chat)`. This [Declarative Policy debug output](../policies.md#scores-order-performance) will help you dive into the specific access logic for more granular debugging.
- Make sure there is only ever one License under `admin/subscriptions` and that it is an online license or open the rails console by running `rails c` in the GitLab project, then run `License.current`.
- If you have several licenses, then open the rails console. Get all of the ids of other licenses and run `License.find(:id).destroy` where the ID is of the unwanted license. Legacy licenses are known to have caused problems with feature access.
- Check logs for any authentication or license validation errors
- For cloud license issues, reach out to `#s_fulfillment_engineering` in Slack
- For AI Gateway connection issues, reach out to `#g_ai_framework` in Slack

## Best Practices

- **Test in both environments**: For thorough testing, consider alternating between multi-tenant and single-tenant setups to ensure your feature works well in both environments.
- **Consult domain documentation**: Review specific feature documentation to understand if there are any environment-specific behaviors you need to consider.
- **Consider end-user context**: Remember that features should work well for both GitLab.com users and self-managed/dedicated customers.

## Additional resources

- [AI Features Documentation](_index.md)
- [Code Suggestions Development](code_suggestions.md)
- [GitLab Duo Enterprise License Access Process for Staging Environment](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/duo/duo_license.md)

## Setting up GitLab Duo for your Staging GitLab.com user account

When working in staging environments, you may need to set up GitLab Duo add-ons for your `staging.gitlab.com` account.

### GitLab Duo Pro

1. Have your account ready at <https://staging.gitlab.com>.
1. [Create a new group](../../user/group/_index.md#create-a-group) or use an existing one as the namespace which will receive the GitLab Duo Pro access.
1. Go to **Settings** > **Billing**.
1. Initiate the purchase flow for the Ultimate plan by clicking on `Upgrade to Ultimate`.
1. After being redirected to <https://customers.staging.gitlab.com>, click on `Continue with your Gitlab.com account`.
1. Purchase the SaaS Ultimate subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com#testing-credit-card-information).
1. Find the newly purchased subscription card, and select from the three dots menu the option `Buy GitLab Duo Pro`.
1. Purchase the GitLab Duo Pro add-on using the same test credit card from the above steps.
1. Go back to <https://staging.gitlab.com> and verify that your group has access to GitLab Duo Pro by navigating to `Settings > GitLab Duo` and managing seats.

### GitLab Duo Enterprise

**Internal use only**: Purchasing a license for GitLab Duo Enterprise is not
self-serviceable; post a request in the `#g_provision` Slack channel to grant
your staging account a GitLab Duo Enterprise license.
