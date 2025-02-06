---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gmail actions
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab supports [Google actions in email](https://developers.google.com/gmail/markup/actions/actions-overview).
When you configure this integration, emails that require an action are marked in Gmail.

![Gmail actions button](img/gmail_action_buttons_for_gitlab_v8.png)

To get this functioning, you must be registered with Google. For instructions, see
[Register with Google](https://developers.google.com/gmail/markup/registering-with-google).

This process has many steps. Make sure that you fulfill all requirements set by
Google to avoid your application being rejected by Google.

In particular, note:

<!-- vale gitlab_base.InclusiveLanguage = NO -->

- The email account used by GitLab to send notification emails must:
  - Have a "Consistent history of sending a high volume of mail from your domain
    (order of hundred emails a day minimum to Gmail) for a few weeks at least".
  - Have a very low rate of spam complaints from users.
- Emails must be authenticated via DKIM or SPF.
- Before sending the final form (**Gmail Schema Whitelist Request**), you must
  send a real email from your production server. This means that you must find
  a way to send this email from the email address you are registering. You can
  do this by forwarding the real email from the email address you are
  registering. You can also go into the Rails console on the GitLab server and
  trigger sending the email from there.

<!-- vale gitlab_base.InclusiveLanguage = YES -->

You can check how it looks going through all the steps laid out in the "Registering with Google" doc in [this GitLab.com issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1517).
