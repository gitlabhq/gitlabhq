---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Set up Duo on your GitLab.com staging account
---

## Duo Pro

1. Have your account ready at <https://staging.gitlab.com>.
1. [Create a new group](../../user/group/_index.md#create-a-group) or use an existing one as the namespace which will receive the Duo Pro access.
1. Go to **Settings > Billing**.
1. Initiate the purchase flow for the Ultimate plan by clicking on `Upgrade to Ultimate`.
1. After being redirected to <https://customers.staging.gitlab.com>, click on `Continue with your Gitlab.com account`.
1. Purchase the SaaS Ultimate subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com#testing-credit-card-information).
1. Find the newly purchased subscription card, and select from the three dots menu the option `Buy GitLab Duo Pro`.
1. Purchase the GitLab Duo Pro add-on using the same test credit card from the above steps.
1. Go back to <https://staging.gitlab.com> and verify that your group has access to Duo Pro by navigating to `Settings > GitLab Duo` and managing seats.

## Duo Enterprise

**Internal use only:** Given that purchasing a license for Duo Enterprise is not self-serviceable, post a request in the `#g_provision` Slack channel to grant access to your customer staging account with a Duo Enterprise license.
