---
stage: Fulfillment
group: Subscription Management
description: Seat usage, compute minutes, storage limits, renewal info.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab subscription
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

When you purchase or use subscriptions for GitLab.com or GitLab Self-Managed, you might encounter the following issues.

## Credit card declined

When you purchase a GitLab subscription, your credit card might be declined because:

- The credit card details are incorrect. The most common cause for this is an incomplete or fake address.
- The credit card account has insufficient funds.
- The credit card has expired.
- The transaction exceeds the credit limit or the card's maximum transaction amount.
- The [transaction is not allowed](#error-transaction_not_allowed).

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

### Error: `transaction_not_allowed`

When you purchase a GitLab subscription, you might get an error that states:

```plaintext
Transaction declined.402 - [card_error/card_declined/transaction_not_allowed]
Your card does not support this type of purchase.
```

This error indicates that the type of transaction you are making is restricted by your card issuer.
It is a security measure designed to protect your account.

Your transaction might be declined because of one or more of the following reasons:

- Your card was issued in India and the transaction does not comply with [RBI's e-mandate rules](https://www.rbi.org.in/Scripts/NotificationUser.aspx?Id=12051&Mode=0).
- Your card isn't activated for online purchases.
- Your card has specific usage limitations.
  For example, it is a debit card that is limited to local transactions only.
- The transaction triggers your bank's security protocols.

To resolve this issue, try the following:

- For cards issued in India: Process your transaction through an authorized local reseller.
  Reach out to one of the following GitLab partners in India:

  - [Datamato Technologies Private Limited](https://partners.gitlab.com/english/directory/partner/1345598/datamato-technologies-private-limited)
  - [FineShift Software Private Limited](https://partners.gitlab.com/English/directory/partner/1737250/fineshift-software-private-limited)

- For cards issued outside of the United States: Ensure your card is enabled for international use, and verify if there are country-specific restrictions.
- Contact your financial institution: Ask for the reason why your transaction was declined, and request that your card is enabled for this type of transaction.

## Error: `Attempt_Exceed_Limitation`

When you purchase a GitLab subscription, you might get the error
`Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.`.

This issue occurs when the credit card form is re-submitted three times within one minute or six times within one hour.
To resolve this issue, wait a few minutes and retry the purchase.

## Error: `Subscription not allowed to add`

When you purchase subscription add-ons (such as additional seats, compute minutes, storage, or GitLab Duo Pro)
you might get the error `Subscription not allowed to add...`.

This issue occurs when you have an active subscription that:

- Was [purchased through a reseller](../customers_portal.md#customers-that-purchased-through-a-reseller).
- Is a multi-year subscription.

To resolve this issue, contact your [GitLab sales representative](https://customers.gitlab.com/contact_us) to assist you with the purchase.

## No purchases listed in the Customers Portal account

To view purchases in the Customers Portal on the **Subscriptions & purchases** page,
you must be added as a contact in your organization for the subscription.

To be added as a contact, [create a ticket with the GitLab Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Unable to link subscription to namespace

On GitLab.com, if you cannot link a subscription to your namespace, you might have insufficient permissions.
Ensure that you have the Owner role for that namespace, and review the [transfer restrictions](_index.md#transfer-restrictions).

## Subscription data fails to synchronize

On GitLab Self-Managed, your subscription data might fail to synchronize.
This issue can occur when network traffic between your GitLab instance and certain
IP addresses is not allowed.

To resolve this issue, allow network traffic from your GitLab instance to the IP addresses
`172.64.146.11:443` and `104.18.41.245:443` (`customers.gitlab.com`).
