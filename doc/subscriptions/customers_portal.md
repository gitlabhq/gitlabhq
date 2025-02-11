---
stage: Fulfillment
group: Subscription Management
description: Payment and company details.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: The Customers Portal
---

For some management tasks for your subscription and account, such as purchasing additional seats or storage and viewing invoices, you use the Customers Portal. See the following pages for specific instructions on managing your subscription:

- [GitLab SaaS subscription](gitlab_com/_index.md)
- [Self-managed subscription](self_managed/_index.md)

If you made your purchase through an authorized reseller, you must contact them directly to make changes to your subscription.
For more information, see [Customers that purchased through a reseller](#customers-that-purchased-through-a-reseller).

## Sign in to Customers Portal

You can sign in to Customers Portal either with your GitLab.com account or a one-time sign-in link sent to your email (if you have not yet [linked your Customers Portal account to your GitLab.com account](#link-a-gitlabcom-account)).

NOTE:
If you registered for Customers Portal with your GitLab.com account, sign in with this account.

To sign in to Customers Portal using your GitLab.com account:

1. Go to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Continue with GitLab.com account**.

To sign in to Customers Portal with your email and to receive a one-time sign-in link:

1. Go to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Sign in with your email**.
1. Provide the **Email** for your Customers Portal profile. You will receive an email with a one-time sign-in link.
1. In the email you received, select **Sign in**.

NOTE:
The one-time sign-in link expires in 24 hours and can only be used once.

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

If you want to transfer ownership of the Customers Portal profile
to another person, after you enter that person's personal details, you must also:

- [Change the linked GitLab.com account](#change-the-linked-account), if you have one linked.

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

### Add a secondary contact

To add a secondary contact for your account:

1. Ensure an account exists in the [Customers Portal](https://customers.gitlab.com/customers/sign_in) for the user you want to add.
1. [Create a ticket with the Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293). Include any relevant material in your request.

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
