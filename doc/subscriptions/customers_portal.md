---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Customers Portal is a comprehensive self-service hub for purchasing and managing GitLab subscriptions and billing.
title: The Customers Portal
---

The Customers Portal is your comprehensive self-service hub for managing GitLab subscriptions and billing. You can purchase GitLab products, manage your subscriptions throughout the entire subscription lifecycle, view and pay invoices, and access your billing details and contact information.

See the following pages for specific instructions on managing your subscription:

- [GitLab SaaS subscription](gitlab_com/_index.md)
- [GitLab Self-Managed subscription](self_managed/_index.md)
- [Manage subscription](manage_subscription.md)

If you made your purchase through an authorized reseller, you must contact them directly to make changes to your subscription.
For more information, see [Customers that purchased through a reseller](#customers-that-purchased-through-a-reseller).

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

The first time you sign in to the Customers Portal with a one-time sign-in link,
you must confirm your email address to maintain access to the Customers Portal. If you sign in
to the Customers Portal through GitLab.com, you don't need to confirm your email address.

You must also confirm any updates to the profile email address. You will receive
an automatic email with instructions about how to confirm, which you can [resend](https://customers.gitlab.com/customers/confirmation/new)
if required.

## Change profile owner information

The profile owner's email address is used for the [Customers Portal legacy sign-in](#sign-in-to-customers-portal).
If the profile owner is also a [billing account manager](#subscription-and-billing-contacts),
their personal details are used on invoices, and for license and subscription-related emails.

To change profile details, including name and email address:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **My profile > Profile settings**.
1. Edit **Your personal details**.
1. Select **Save changes**.

You can also [transfer ownership of the Customers Portal profile and billing account](https://support.gitlab.com/hc/en-us/articles/17767356437148-How-to-transfer-subscription-ownership) to another person.

## Change your company details

To change your company details, including company name and tax ID:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Billing account settings**.
1. Scroll down to the **Company information** section.
1. Edit the company details.
1. Select **Save changes**.

## Subscription and billing contacts

### Change your subscription contact

The subscription contact is the primary contact for your billing account. They receive subscription event notifications and information about applying subscription.

To change the subscription contact:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Company information** section, then to **Subscription contact**.
1. To select a different subscription contact, select from the **Billing account manager** dropdown list.
1. Edit the contact details.
1. Select **Save changes**.

### Add a billing account manager

Billing account managers can view and edit subscriptions, payment methods, and account settings, as well as pay and download invoices.

To add another billing account manager for your account:

1. Ensure an account exists in the [Customers Portal](https://customers.gitlab.com/customers/sign_in) for the user you want to add.
1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Billing account managers** section.
1. Select **Invite billing account manager**.
1. Enter the email address of the user you want to add.
1. Select **Invite**.

The invited user receives an email with an invitation to the Customers Portal.
The invitation is valid for seven days.
If the user does not accept the invitation before it expires, you can send them a new invitation.
You can have maximum 15 pending invitations at a time.

### Remove a billing account manager

You can remove billing account managers from your account at any time.
After you remove a billing account manager, they no longer have access to view or edit your billing account information.

To remove a billing account manager:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Billing account managers** section.
1. In the list, next to the billing account manager you want to remove, select **Remove**.
1. In the confirmation dialog, select **Remove** to confirm the action.

### Revoke a billing account manager invitation

You can revoke invitations that have not yet been accepted.
Users that have been invited but have not yet accepted the invitation display the name **Awaiting user registration**.

To revoke an invitation:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. Scroll to the **Billing account managers** section.
1. In the list, next to the invited user with the **Awaiting user registration** name, select **Remove**.
1. In the confirmation dialog, select **Remove** to revoke the invitation.

### Change your billing contact

The billing contact receives all invoices and subscription event notifications.

To change the billing contact:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
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

### Troubleshooting your billing or subscription contact's name

If the billing account manager's email is linked to contacts with different first or last names, you will be prompted to update the name.

If you are the billing account manager, follow the instructions to [update your personal profile](#change-profile-owner-information).

If you are not the billing account manager, notify them to update their personal profile.

### Troubleshooting your subscription contact

If the subscription contact is no longer a billing account manager, you will be prompted to select a new contact. Follow the instructions to [change your subscription contact](#change-your-subscription-contact).

## Change your payment method

Purchases in the Customers Portal require a credit card on record as a payment method. You can add
multiple credit cards to your account, so that purchases for different products are charged to the
correct card.

If you would like to use an alternative method to pay,
[contact our Sales team](https://customers.gitlab.com/contact_us).

To change your payment method:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. **Edit** an existing payment method's information or **Add new payment method**.
1. Select **Save Changes**.

### Set a default payment method

Automatic renewal of a subscription is charged to your default payment method. To mark a payment
method as the default:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Billing account settings**.
1. **Edit** the selected payment method and check the **Make default payment method** checkbox.
1. Select **Save Changes**.

### Delete a default payment method

You cannot delete your default payment method directly through the Customers Portal. To delete a default payment method, [contact our Billing team](https://customers.gitlab.com/contact_us) for assistance.

## Pay for an invoice

You can pay for your invoices in the Customers Portal with a credit card.

To pay for an invoice:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the left sidebar, select **Invoices**.
1. On the invoice you want to pay for, select **Pay for invoice**.
1. Complete the payment form.

If you would like to use an alternative payment method,
[contact our Billing team](https://customers.gitlab.com/contact_us#contact-billing-team).

## Link a GitLab.com account

Follow this guideline if you have a legacy Customers Portal profile to sign in.

To link a GitLab.com account to your Customers Portal profile:

1. Trigger a one-time sign-in link to your email from the [Customers Portal](https://customers.gitlab.com/customers/sign_in?legacy=true).
1. Locate the email and click on the one-time sign-in link to sign in to your Customers Portal account.
1. Select **My profile > Profile settings**.
1. Under **Your GitLab.com account**, select **Link account**.
1. Sign in to the [GitLab.com](https://gitlab.com/users/sign_in) account you want to link to the Customers Portal profile.

## Change the linked account

If you want to link your Customers Portal account to a different GitLab.com account,
you must use your GitLab.com account to register for a new Customers Portal profile.

If you want to change subscription contacts, you can instead do either of the following:

- [Change the billing contact](#change-your-billing-contact).
- [Change the subscription contact](#change-your-subscription-contact).

If you have a legacy Customers Portal profile that is not linked to a GitLab.com account, you may still [sign in](https://customers.gitlab.com/customers/sign_in?legacy=true) using a one-time sign-in link sent to your email. However, you should [create](https://gitlab.com/users/sign_up) and [link a GitLab.com account](#change-the-linked-account) to ensure continued access to the Customers Portal.

To change the GitLab.com account linked to your Customers Portal profile:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. In a separate browser tab, go to [GitLab.com](https://gitlab.com/users/sign_in) and ensure you are not logged in.
1. On the Customers Portal page, select **My profile > Profile settings**.
1. Under **Your GitLab.com account**, select **Change linked account**.
1. Sign in to the [GitLab.com](https://gitlab.com/users/sign_in) account you want to link to the Customers Portal profile.

## Tax ID for non-US customers

A Tax ID is a unique number assigned by tax authorities to businesses registered for Value Added Tax (VAT), Goods and Services Tax (GST), or similar indirect taxes.

Providing a valid Tax ID may reduce your tax burden by allowing us to apply reverse charge mechanisms instead of charging VAT/GST on your invoices. Without a valid Tax ID, we charge applicable VAT/GST rates based on your location.

If your business isn't registered for indirect taxes (due to size thresholds or other reasons), we apply the standard VAT/GST rate according to local regulations.

For detailed Tax ID formats by country and additional information, see our [complete Tax ID reference guide](https://handbook.gitlab.com/handbook/finance/tax/#frequently-asked-questions---tax-id-for-non-us-customers).

## Customers that purchased through a reseller

If you purchased a subscription through an authorized reseller (including GCP and AWS marketplaces), you have access to the Customers Portal to:

- View your subscription.
- Associate your subscription with the relevant group (GitLab.com) or download the license (GitLab Self-Managed).
- Manage contact information.

Other changes and requests must be done through the reseller, including:

- Changes to the subscription.
- Purchase of additional seats, Storage, or Compute.
- Requests for invoices, because those are issued by the reseller, not GitLab.

Resellers do not have access to the Customers Portal, or their customers' accounts.

After your subscription order is processed, you will receive several emails:

- A "Welcome to the Customers Portal" email, including instructions on how to sign in.
- A purchase confirmation email with instructions on how to provision access.

## Get support

If you encounter issues or have questions about your GitLab subscription, visit the [Contact us](https://customers.gitlab.com/contact_us) page.
This page lists resources, services, and contact options of the sales, billing, and support teams, ensuring quick access to the right help.
