---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Seat usage, compute minutes, storage limits, renewal info.
gitlab_dedicated: yes
title: Troubleshooting GitLab subscription
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you purchase or use subscriptions for GitLab, you might encounter the following issues.

## Payment and card issues

### Error: Credit card declined

When you purchase a GitLab subscription, your credit card might be declined because:

- The credit card details are incorrect. The most common cause for this is an incomplete or fake address.
- The credit card account has insufficient funds.
- The credit card has expired.
- The transaction exceeds the credit limit or the card's maximum transaction amount.
- The [transaction is not allowed](#error-transaction_not_allowed).

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

#### Error: `transaction_not_allowed`

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
  - [Datamato Technologies Private Limited](https://about.gitlab.com/partners/channel-partners/#/1345598)
  - [FineShift Software Private Limited](https://about.gitlab.com/partners/channel-partners/#/1737250)
- For cards issued outside of the United States: Ensure your card is enabled for international use, and verify if there are country-specific restrictions.
- Contact your financial institution: Ask for the reason why your transaction was declined, and request that your card is enabled for this type of transaction.

#### Error: `Attempt_Exceed_Limitation`

When you purchase a GitLab subscription, you might get the error
`Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.`.

This issue occurs when the credit card form is re-submitted three times within one minute or six times within one hour.
To resolve this issue, wait a few minutes and retry the purchase.

## Authentication and account issues

### Error: `must be authenticated to make a purchase`

You might see this error when you try to make a purchase without being signed in to your account.

To resolve this issue, sign in to your GitLab account before attempting to purchase a subscription.

### Error: No purchases listed in the Customers Portal account

To view purchases in the Customers Portal on the **Subscriptions & purchases** page,
you must be added as a contact in your organization for the subscription.

To be added as a contact, [create a ticket with the GitLab Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Namespace and subscription linking issues

### Error: `GitLab namespace is required`

You might see this error when the GitLab namespace is not specified during the purchase process.

To resolve this issue, ensure you select a valid GitLab namespace before proceeding with your purchase.

### Error: `Unable to link subscription to namespace`

On GitLab.com, if you cannot link a subscription to your namespace, you might have insufficient permissions.
Ensure that you have the Owner role for that namespace, and review the [transfer restrictions](../manage_subscription.md#transfer-restrictions).

### Error: `Subscription not found`

You might see this error when you try to modify a subscription that does not exist or cannot be found.

To resolve this issue:

- Verify you are using the correct subscription ID or name.
- Ensure the subscription exists in your account.
- Check that you have access to the subscription you are trying to modify.

If you continue to experience issues, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Namespace validation errors during purchase

When you purchase a GitLab subscription on GitLab.com, you might encounter namespace validation errors that prevent you from completing the purchase.

### Error: `GitLab namespace is not valid`

You might see this error when the namespace:

- Is not specified in the purchase URL.
- Does not exist on GitLab.com.
- Is not owned by your user account.
- Is not a top-level group (it's a subgroup or project).
- Has no billable members.

To resolve this issue:

- Verify the namespace exists and that you have the [Owner role](../../user/permissions.md#roles). If you don't, ask an existing Owner to add you.
- Ensure the namespace is a top-level group. Subscriptions can't be applied to subgroups or projects - apply the subscription to the parent group instead.
- [Verify the namespace has at least one billable user](../manage_seats.md#billable-users). Add members if needed.
- Check that the purchase URL includes the correct `gl_namespace_id` parameter (for example, `?gl_namespace_id=123`).

If you continue to experience issues after trying the steps above, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

### Error: `Subscription does not belong to GitLab namespace`

You might see this error when the subscription you are trying to modify does not belong to the namespace you specified in the purchase URL.

To resolve this issue:

- Verify you are using the correct subscription ID or name.
- Ensure the namespace in the URL matches the namespace that owns the subscription.
- If you need to change which namespace a subscription is linked to, review the [transfer restrictions](../manage_subscription.md#transfer-restrictions).

If you continue to experience issues after trying the steps above, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Product and add-on issues

### Error: `Product is required`

You might see this error when the product is not specified during the purchase process.

To resolve this issue, ensure you select a product before proceeding with your purchase.

### Error: `cannot purchase more product through the Customers Portal`

When you purchase subscription add-ons (such as additional seats, compute minutes, storage, or GitLab Duo Pro), you might see this error.

This issue occurs when you have an active subscription that:

- Was [purchased through a reseller](../billing_account.md#subscription-purchased-through-a-reseller).
- Is a multi-year subscription.

To resolve this issue, contact your [GitLab sales representative](https://customers.gitlab.com/contact_us) for assistance.

### Error: `Product is not available in this purchase flow`

You might see this error when the product you are trying to purchase is not available through the self-service purchase flow.

This can occur because:

- The product requires special configuration or approval.
- The product is only available through direct sales.
- Your account does not meet the requirements for this product.

To resolve this issue, contact your [GitLab sales representative](https://customers.gitlab.com/contact_us) for assistance with your purchase.

#### Error: `Product is not available for sale through the Customers Portal`

You might see this error when:

- The product rate plan has multiple charges, which are not supported in the self-service purchase flow.
- The product rate plan is not available for self-service purchases.

To resolve this issue, contact your [GitLab sales representative](https://customers.gitlab.com/contact_us) for assistance.

## Deployment and configuration issues

### Error: `The deployment type of the purchase does not match your subscription's deployment type`

You might see this error when the deployment type you specified does not match the product you are trying to purchase.

To resolve this issue:

- Verify you are purchasing the correct product for your deployment type.
  - GitLab.com subscriptions are for multi-tenant SaaS deployments.
  - GitLab Self-Managed subscriptions are for on-premises or private cloud deployments.
- Ensure you are using the correct purchase URL for your deployment type.
- If you need a subscription for a different deployment type, start a new purchase with the correct product.

## Infrastructure and synchronization issues

### Error: Subscription data fails to synchronize

On GitLab Self-Managed or GitLab Dedicated, your subscription data might fail to synchronize.
This issue can occur when network traffic between your GitLab instance and certain
IP addresses is not allowed.

To resolve this issue, allow network traffic from your GitLab instance to the IP addresses
`172.64.146.11:443` and `104.18.41.245:443` (`customers.gitlab.com`).

For more information, see [troubleshooting connectivity issues](../../administration/license.md#error-cannot-activate-instance-due-to-a-connectivity-issue).
