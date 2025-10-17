---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Change billing account data and payment methods, pay for invoices, and link your GitLab account in the Customers Portal.
title: Manage billing account
---

Customers Portal is your comprehensive self-service hub for [managing GitLab subscriptions](manage_subscription.md) and billing.
You can purchase GitLab products, manage your subscriptions throughout the entire subscription lifecycle, view and pay invoices,
and access your billing details and contact information.

If you made your purchase through an authorized reseller, you must contact them directly to make changes to your subscription.
For more information, see [customers that purchased through a reseller](#subscription-purchased-through-a-reseller).

## Sign in to Customers Portal

You can sign in to Customers Portal either with your GitLab.com account or a one-time sign-in link sent to your email (if you have not yet [linked your Customers Portal account to your GitLab.com account](#link-a-gitlabcom-account)).

{{< alert type="note" >}}

If you registered for Customers Portal with your GitLab.com account, sign in with this account.

{{< /alert >}}

To sign in to Customers Portal using your GitLab.com account:

1. Go to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Continue with GitLab.com account**.

To sign in to Customers Portal with your email and to receive a one-time sign-in link:

1. Go to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Sign in with your email**.
1. Provide the **Email** for your Customers Portal profile. You will receive an email with a one-time sign-in link.
1. In the email you received, select **Sign in**.

{{< alert type="note" >}}

The one-time sign-in link expires in 24 hours and can only be used once.

{{< /alert >}}

## Confirm Customers Portal email address

The first time you sign in to Customers Portal with a one-time sign-in link,
you must confirm your email address to maintain access to Customers Portal. If you sign in
to Customers Portal through GitLab.com, you don't need to confirm your email address.

You must also confirm any updates to the profile email address. You will receive
an automatic email with instructions about how to confirm, which you can [resend](https://customers.gitlab.com/customers/confirmation/new)
if required.

## Change profile owner information

The profile owner's email address is used for the [Customers Portal legacy sign-in](#sign-in-to-customers-portal).
If the profile owner is also a [billing account manager](#subscription-and-billing-contacts),
their personal details are used on invoices, and for license and subscription-related emails.

To change profile details, including name and email address:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **My profile** > **Profile settings**.
1. Edit **Your personal details**.
1. Select **Save changes**.

## Change your company details

To change your company details, including company name and tax ID:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Billing account settings**.
1. Scroll down to the **Company information** section.
1. Edit the company details.
1. Select **Save changes**.

## Subscription and billing contacts

Users involved in subscription management can have three distinct roles
with varying levels of permissions and visibility into the subscription:

- Billing account manager: Has access to view and edit subscriptions, payment methods, and billing account settings. Can pay and download invoices, and update the subscription contact to any listed billing account manager.
- Subscription contact (or "Sold to" contact): The subscription owner and primary contact
  for your billing account. Receives notifications about subscription events and information
  about applying the subscription. This role is also a billing account manager by default.
- Billing contact (or "Bill to" contact): Receives all invoices and notifications about
  subscription events. Does not have a Customers Portal account with access to the subscription
  unless this role is also a billing account manager.

One user can have all three roles.

### Change your subscription contact

To change the subscription contact:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Company information** section, then to **Subscription contact**.
1. To select a different subscription contact, select from the **Billing account manager** dropdown list.
1. Edit the contact details.
1. Select **Save changes**.

### Add a billing account manager

To add another billing account manager for your account:

1. Ensure an account exists in [Customers Portal](https://customers.gitlab.com/customers/sign_in) for the user you want to add.
1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Billing account managers** section.
1. Select **Invite billing account manager**.
1. Enter the email address of the user you want to add.
1. Select **Invite**.

The invited user receives an email with an invitation to Customers Portal.
The invitation is valid for seven days.
If the user does not accept the invitation before it expires, you can send them a new invitation.
You can have maximum 15 pending invitations at a time.

### Remove a billing account manager

You can remove billing account managers from your account at any time.
After you remove a billing account manager, they no longer have access to view or edit your billing account information.

To remove a billing account manager:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Billing account managers** section.
1. In the list, next to the billing account manager you want to remove, select **Remove**.
1. In the confirmation dialog, select **Remove** to confirm the action.

### Revoke a billing account manager invitation

You can revoke invitations that have not yet been accepted.
Users that have been invited but have not yet accepted the invitation display the name **Awaiting user registration**.

To revoke an invitation:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Billing account managers** section.
1. In the list, next to the invited user with the **Awaiting user registration** name, select **Remove**.
1. In the confirmation dialog, select **Remove** to revoke the invitation.

### Change your billing contact

The billing contact receives all invoices and subscription event notifications.

To change the billing contact:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Company information** section, then to **Billing contact**.

   - To change your billing contact to your subscription contact:

     1. Select **Billing contact is the same as subscription contact**.
     1. Select **Save changes**.

   - To change your billing contact to a different billing account manager:

     1. Clear the **Billing contact is the same as subscription contact** checkbox.
     1. Select a different billing account manager from the **User** dropdown list.
     1. Edit the contact details.
     1. Select **Save changes**.

   - To change your billing contact to a custom contact:

     1. Clear the **Billing contact is the same as subscription contact** checkbox.
     1. Select **Enter a custom contact** from the **User** dropdown list.
     1. Enter the contact details.
     1. Select **Save changes**.

## Change your payment method

Purchases in Customers Portal require a credit card on record as a payment method. You can add
multiple credit cards to your account, so that purchases for different products are charged to the
correct card.

If you would like to use an alternative method to pay,
[contact our Sales team](https://customers.gitlab.com/contact_us).

To change your payment method:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. **Edit** an existing payment method's information or **Add new payment method**.
1. Select **Save Changes**.

### Set a default payment method

Automatic renewal of a subscription is charged to your default payment method. To mark a payment
method as the default:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. **Edit** the selected payment method and select the **Make default payment method** checkbox.
1. Select **Save Changes**.

### Delete a default payment method

You cannot delete your default payment method directly through Customers Portal. To delete a default payment method, [contact our Billing team](https://customers.gitlab.com/contact_us) for assistance.

## Pay for an invoice

You can pay for your invoices in Customers Portal with a credit card.

To pay for an invoice:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Invoices**.
1. On the invoice you want to pay for, select **Pay for invoice**.
1. Complete the payment form.

If you would like to use an alternative payment method,
[contact our Billing team](https://customers.gitlab.com/contact_us#contact-billing-team).

## Link a GitLab.com account

Follow this guideline if you have a legacy Customers Portal profile to sign in.

To link a GitLab.com account to your Customers Portal profile:

1. Trigger a one-time sign-in link to your email from your [Customers Portal](https://customers.gitlab.com/customers/sign_in?legacy=true) account.
1. Locate the email and select the one-time sign-in link to sign in to your Customers Portal account.
1. Select **My profile** > **Profile settings**.
1. Under **Your GitLab.com account**, select **Link account**.
1. Sign in to the [GitLab.com](https://gitlab.com/users/sign_in) account you want to link to the Customers Portal profile.

## Change the linked account

If you want to link your Customers Portal account to a different GitLab.com account,
you must use your GitLab.com account to register for a new Customers Portal profile.

If you want to change subscription contacts, you can instead do either of the following:

- [Change the billing contact](#change-your-billing-contact).
- [Change the subscription contact](#change-your-subscription-contact).

If you have a legacy Customers Portal profile that is not linked to a GitLab.com account, you may still
[sign in](https://customers.gitlab.com/customers/sign_in?legacy=true) using a one-time sign-in link sent to your email.
However, you should [create](https://gitlab.com/users/sign_up) and [link a GitLab.com account](#change-the-linked-account)
to ensure continued access to Customers Portal.

To change the GitLab.com account linked to your Customers Portal profile:

1. Sign in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. In a separate browser tab, go to [GitLab.com](https://gitlab.com/users/sign_in) and ensure you are not logged in.
1. On the Customers Portal page, select **My profile** > **Profile settings**.
1. Under **Your GitLab.com account**, select **Change linked account**.
1. Sign in to the [GitLab.com](https://gitlab.com/users/sign_in) account you want to link to the Customers Portal profile.

## Transfer subscription ownership

You can transfer subscription ownership in Customers Portal to or from a contact.

### To a new billing account manager

To transfer subscription ownership to a contact who is not listed as a billing account manager:

1. Invite the contact as a billing account manager.
1. After the contact accepts the invitation, change the subscription contact to the new billing account manager.

### To a new subscription contact

If you are the current subscription contact and want to transfer ownership to a different person who doesn't have a Customers Portal account:

1. Change your profile owner information to the new contact's details.
1. Have the new contact sign in to Customers Portal with their email address using a one-time sign-in link.
1. Have the new contact change the linked GitLab.com account to their own GitLab.com account.

### From a contact who has left the organization

If you have access to the subscription contact's email mailbox:

1. Sign in to Customers Portal with the subscription contact's email address using a one-time sign-in link.
1. Change the subscription contact information to your details.
1. Change the linked account to your GitLab.com account.

If you don't have access to the subscription contact's email mailbox,
[contact Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)
to request transferring the subscription ownership.
You must provide proof of ownership for Support to process your request.

You can use the following template for the Support request:

```plaintext
Hi Support,

Please update subscription ownership for my subscription/billing account. I confirm that I am not able to make this change in the Customers Portal. Here are the relevant details:

- Old subscription contact's email address:
- New subscription contact's email address:
- (Optional) Subscription or Billing account name:
- Proof of ownership:
```

## Tax ID for non-US customers

A Tax ID is a unique number assigned by tax authorities to businesses registered for Value Added Tax (VAT), Goods and Services Tax (GST), or similar indirect taxes.

Providing a valid Tax ID may reduce your tax burden by allowing us to apply reverse charge mechanisms instead of charging VAT/GST on your invoices. Without a valid Tax ID, we charge applicable VAT/GST rates based on your location.

If your business isn't registered for indirect taxes (due to size thresholds or other reasons), we apply the standard VAT/GST rate according to local regulations.

For detailed Tax ID formats by country and additional information, see our [complete Tax ID reference guide](https://handbook.gitlab.com/handbook/finance/tax/#frequently-asked-questions---tax-id-for-non-us-customers).

## Troubleshooting

If you encounter issues or have questions about your GitLab subscription,
visit the [Contact us](https://customers.gitlab.com/contact_us) page.
Access resources, services, and contact options of the sales, billing, and support teams
to get quick access to the help you need.

### Subscription purchased through a reseller

If you purchased a subscription through an authorized reseller (including GCP and AWS marketplaces), you have access to Customers Portal to:

- View your subscription.
- Associate your subscription with the relevant group (GitLab.com) or download the license (GitLab Self-Managed).
- Manage contact information.

Other changes and requests must be done through the reseller, including:

- Changes to the subscription.
- Purchase of additional seats, Storage, or Compute.
- Requests for invoices, because those are issued by the reseller, not GitLab.

Resellers do not have access to Customers Portal, or their customers' accounts.

After your subscription order is processed, you will receive several emails:

- A "Welcome to the Customers Portal" email, including instructions on how to sign in.
- A purchase confirmation email with instructions on how to provision access.

### Billing and subscription contact's names don't match

If the billing account manager's email is linked to contacts with different first or last names,
you will be prompted to update the name.

If you are the billing account manager, follow the instructions to [update your personal profile](#change-profile-owner-information).

If you are not the billing account manager, notify them to update their personal profile.

### Subscription contact is no longer account manager

If the subscription contact is no longer a billing account manager, you will be prompted to select a new contact.
Follow the instructions to [change your subscription contact](#change-your-subscription-contact).

### Error: `Email has already been taken`

If the email address you want to register with is already in use in Customers Portal, you can either:

- Provide an alternative email address.
- Transfer the subscription ownership.
