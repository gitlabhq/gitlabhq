---
stage: Fulfillment
group: Subscription Management
description: Seat usage, compute minutes, storage limits, renewal info.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting GitLab subscription

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed

When you use subscriptions for GitLab.com or GitLab self-managed, you might encounter the following issues.

## Credit card declined

When purchasing a GitLab subscription, your credit card might be declined because:

- The credit card details are incorrect. The most common cause for this is an incomplete or fake address.
- The credit card account has insufficient funds.
- The credit card has expired.
- The transaction exceeds the credit limit or the card's maximum transaction amount.

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Error: `Attempt_Exceed_Limitation`

When purchasing a GitLab subscription, you might get the error
`Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.`.

This issue occurs when the credit card form is re-submitted three times within one minute or six times within one hour.
To resolve this issue, wait a few minutes and retry the purchase.

## Error: `Subscription not allowed to add`

When purchasing subscription add-ons (such as additional seats, compute minutes, storage, or GitLab Duo Pro)
you might get the error `Subscription not allowed to add...`.

This issue occurs when you have an active subscription that:

- Was [purchased through a reseller](../customers_portal.md#customers-that-purchased-through-a-reseller).
- Is a multi-year subscription.

To resolve this issue, contact your [GitLab sales representative](https://about.gitlab.com/sales/) to assist you with the purchase.

## No purchases listed in the Customers Portal account

To view purchases in the Customers Portal on the **Subscriptions & purchases** page,
you must be added as a contact in your organization for the subscription.

To be added as a contact, [create a ticket with the GitLab Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Unable to link subscription to namespace

On GitLab.com, if you cannot link a subscription to your namespace, you might have insufficient permissions.
Ensure that you have the Owner role for that namespace, and review the [transfer restrictions](index.md#transfer-restrictions).

## Subscription data fails to synchronize

On GitLab self-managed, your subscription data might fail to synchronize.
This issue can occur when network traffic between your GitLab instance and certain
IP addresses is not allowed.

To resolve this issue, allow network traffic from your GitLab instance to the IP addresses
`172.64.146.11:443` and `104.18.41.245:443` (`customers.gitlab.com`).
