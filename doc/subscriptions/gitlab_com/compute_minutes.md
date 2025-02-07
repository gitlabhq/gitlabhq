---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Purchase additional compute minutes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

[Compute minutes](../../ci/pipelines/compute_minutes.md) is the resource consumed
when running [CI/CD pipelines](../../ci/_index.md) on GitLab instance runners. You can find
pricing for additional compute minutes on the [GitLab Pricing page](https://about.gitlab.com/pricing/#compute-minutes).

Additional compute minutes:

- Are valid for 12 months from date of purchase or until all compute minutes are consumed,
  whichever comes first. Expiry of compute minutes is not enforced.
- Are used only after the monthly quota included in your subscription runs out.
- Are [carried over to the next month](#monthly-rollover-of-purchased-compute-minutes),
  if any remain at the end of the month.
- Bought on a trial subscription are available after the trial ends or upgrading to a paid plan.
- Remain available when you change subscription tiers, including changes between paid tiers or to the Free tier.

## Purchase compute minutes for a group

Prerequisites:

- You must have the Owner role for the group.

You can purchase additional compute minutes for your group.
You cannot transfer purchased compute minutes from one group to another,
so be sure to select the correct group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select **Pipelines**.
1. Select **Buy additional compute minutes**. You are taken to the Customers Portal.
1. Enter the desired quantity of compute minute packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select a payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkboxes.
1. Select **Buy compute minutes**.

After your payment is processed, the additional compute minutes are added to your group
namespace.

## Purchase compute minutes for a personal namespace

To purchase additional compute minutes for your personal namespace:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Usage Quotas**.
1. Select **Buy additional compute minutes**. You are taken to the Customers Portal.
1. In the **Subscription details** section, select the name of the user from the dropdown list.
1. Enter the desired quantity of compute minute packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select a payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkboxes.
1. Select **Buy compute minutes**.

After your payment is processed, the additional compute minutes are added to your personal
namespace.

## Monthly rollover of purchased compute minutes

If you purchase additional compute minutes and don't use the full amount, the remaining amount
rolls over to the next month. Additional compute minutes are a one-time purchase and
do not renew or refresh each month.

For example, if you have a monthly quota of 10,000 compute minutes:

- On April 1, you purchase 5,000 additional compute minutes, so you have 15,000 minutes
  available for April.
- During April, you use 13,000 minutes, so you used 3,000 of the 5,000 additional compute minutes.
- On May 1, [the monthly quota resets](../../ci/pipelines/compute_minutes.md#monthly-reset-of-compute-usage)
  and the unused compute minutes roll over. So you have 2,000 additional compute minutes remaining
  and a total of 12,000 available for May.

## Troubleshooting

### Error: `Last name can't be blank`

You might get an error "Last name can't be blank" when purchasing compute minutes.
This issue occurs when a last name is missing from the **Full name** field of your profile.

To resolve the issue:

- Ensure that your user profile has a last name filled in:

  1. On the left sidebar, select your avatar.
  1. Select **Edit profile**.
  1. Update the **Full name** field to have both first name and last name, then save the changes.

- Clear your browser cache and cookies, then try the purchase process again.
- If the error persists, try using a different web browser or an incognito/private browsing window.

### Error: `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again`

You might get the error `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.`
when purchasing compute minutes.

This issue occurs when the credit card form is re-submitted too quickly
(three submissions in one minute or six submissions in one hour).

To resolve this issue, wait a few minutes and try the purchase process again.
