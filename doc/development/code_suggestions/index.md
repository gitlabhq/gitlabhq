---
stage: Create
group: Code Creation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Code Suggestions documentation for developers interested in contributing features or bugfixes."
---

# Code Suggestions development guidelines

## Code Suggestions development setup

The recommended setup for locally developing and debugging Code Suggestions is to have all 3 different components running:

- IDE Extension (e.g. GitLab Workflow extension for VS Code).
- Main application configured correctly (e.g. GDK).
- [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).

This should enable everyone to see locally any change in an IDE being sent to the main application transformed to a prompt which is then sent to the respective model.

### Setup instructions

1. Install and run locally the [GitLab Workflow extension for VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CONTRIBUTING.md#configuring-development-environment):
   1. Add the `"gitlab.debug": true` info to the Code Suggestions development config:
      1. In VS Code, go to the Extensions page and find "GitLab Workflow" in the list.
      1. Open the extension settings by clicking a small cog icon and select "Extension Settings" option.
      1. Check a "GitLab: Debug" checkbox.
   1. If you'd like to test that Code Suggestions is working from inside the GitLab Workflow extension for VS Code, then follow the [steps to set up a personal access token](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup) with your GDK inside the new window of VS Code that pops up when you run the "Run and Debug" command.
      - Once you complete the steps below, to test you are hitting your local `/code_suggestions/completions` endpoint and not production, follow these steps:
        1. Inside the new window, in the built in terminal select the "Output" tab then "GitLab Language Server" from the drop down menu on the right.
        1. Open a new file inside of this VS Code window and begin typing to see Code Suggestions in action.
        1. You will see completion request URLs being fetched that match the Git remote URL for your GDK.

1. Main Application (GDK):
   1. Install the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#one-line-installation).
   1. Enable Feature Flag ```ai_duo_code_suggestions_switch```:
      1. In your terminal, go to your `gitlab-development-kit` > `gitlab` directory.
      1. Run `gdk rails console` or `bundle exec rails c` to start a Rails console.
      1. [Enable the Feature Flag](../../administration/feature_flags.md#enable-or-disable-the-feature) for the Code Suggestions tokens API by calling `Feature.enable(:ai_duo_code_suggestions_switch)` from the console.
   1. [Setup AI Gateway](../ai_features/index.md#required-install-ai-gateway).
   1. Run your GDK server with `gdk start` if it's not already running.

### Setup instructions to use staging AI Gateway

When testing interactions with the AI Gateway, you might want to integrate your local GDK
with the deployed staging AI Gateway. To do this:

1. You need a cloud staging license that has the Code Suggestions add-on,
   because add-ons are enabled on staging. Follow [these instructions](#setup-instructions-to-use-gdk-with-the-code-suggestions-add-on) to add the add-on to your license (you can reach out to `#s_fulfillment_engineering` if you have any problems). See this [handbook page](https://handbook.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses) for how to request a license for local development.
1. Set environment variables to point customers-dot to staging, and the AI Gateway to staging:

   ```shell
   export GITLAB_LICENSE_MODE=test
   export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
   export AI_GATEWAY_URL=https://cloud.staging.gitlab.com/ai
   ```

1. Restart the GDK.
1. Ensure you followed the necessary [steps to enable the Code Suggestions feature](../../user/project/repository/code_suggestions/index.md).
1. Test out the Code Suggestions feature by opening the Web IDE for a project.

### Setup instructions to use GDK with the Code Suggestions Add-on

1. Add a **GitLab Ultimate Self-Managed** subscription with a [Duo Pro subscription add-on](../../subscriptions/subscription-add-ons.md) to your GDK instance.

   1. Sign in to the [staging Customers Portal](https://customers.staging.gitlab.com) by selecting the **Continue with GitLab.com account** button.
   If you do not have an existing account, you are prompted to create one.
   1. If you do not have an existing cloud activation code, visit the **Ultimate Self-Managed Subscription** page using the [buy subscription flow link](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/8aa922840091ad5c5d96ada43d0065a1b6198841/doc/flows/buy_subscription.md).
   1. Purchase the subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com/#testing-credit-card-information).
   1. Once you have a subscription, on the subscription card, select the ellipse menu **...** > **Buy Duo Pro add-on**.
   1. Use the previously saved credit card information, and the same number of seats as in the subscription.

   After this step is complete, you will have an activation code for a _GitLab Ultimate Self-Managed subscription with a Duo Pro add-on_.

1. Follow the [activation instructions](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/doc/license/cloud_license.md?ref_type=heads#testing-activation):

   1. Set environment variables.

      ```shell
      export GITLAB_LICENSE_MODE=test
      export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
      export GITLAB_SIMULATE_SAAS=0
      ```

   On a non-GDK instance, you can set the variables using `gitlab_rails['env']` in the `gitlab.rb` file:

      ```shell
      gitlab_rails['env'] = {
      'GITLAB_LICENSE_MODE' => 'test',
      'CUSTOMER_PORTAL_URL' => 'https://customers.staging.gitlab.com',
      'AI_GATEWAY_URL' => 'https://cloud.staging.gitlab.com/ai'
      }
      ```

   1. Restart your GDK.
   1. Go to `/admin/subscription`.
   1. Optional. Remove any active license.
   1. Add the new activation code.

1. Inside your GDK, navigate to **Admin area** > **GitLab Duo Pro**, go to `/admin/code_suggestions`
1. Filter users to find `root` and click the toggle to assign a GitLab Duo Pro add-on seat to the root user

### Setup instructions to use the Duo Pro add-on with a **staging** GitLab.com account

1. Have your account ready at <https://staging.gitlab.com>
1. [Create a new group](../../user/group/index.md#create-a-group) or use an existing one as the namespace which will receive the Duo Pro access
1. Navigate to `Settings > Billing`
1. Initiate the purchase flow for the Ultimate plan by clicking on `Upgrade to Ultimate`
1. After being redirected to <https://customers.staging.gitlab.com>, click on `Continue with your Gitlab.com account`
1. Purchase the SaaS Ultimate subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com#testing-credit-card-information)
1. Find the newly purchased subscription card, and select from the three dots menu the option `Buy GitLab Duo Pro`
1. Purchase the GitLab Duo Pro add-on using the same test credit card from the above steps
1. Go back to <https://staging.gitlab.com> and verify that your group has access to Duo Pro by navigating to `Settings > GitLab Duo` and managing seats
