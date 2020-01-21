---
type: howto, reference
---

# Email from GitLab **(STARTER ONLY)**

GitLab provides a simple tool to administrators for emailing all users, or users of
a chosen group or project, right from the Admin Area. Users will receive the email
at their primary email address.

## Use-cases

- Notify your users about a new project, a new feature, or a new product launch.
- Notify your users about a new deployment, or that will be downtime expected
  for a particular reason.

## Sending emails to users from within GitLab

1. Navigate to the **Admin Area > Overview > Users** and press the
   **Send email to users** button.

   ![admin users](email1.png)

1. Compose an email and choose where it will be sent (all users or users of a
   chosen group or project):

   ![compose an email](email2.png)

## Unsubscribing from emails

Users can choose to unsubscribe from receiving emails from GitLab by following
the unsubscribe link in the email. Unsubscribing is unauthenticated in order
to keep this feature simple.

On unsubscribe, users will receive an email notification that unsubscribe happened.
The endpoint that provides the unsubscribe option is rate-limited.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
