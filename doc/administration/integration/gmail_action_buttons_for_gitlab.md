# Gmail actions buttons for GitLab

GitLab supports [Google actions in email](https://developers.google.com/gmail/markup/actions/actions-overview).

If correctly setup, emails that require an action will be marked in Gmail.

![gmail_actions_button.png](img/gmail_action_buttons_for_gitlab.png)

To get this functioning, you need to be registered with Google.
[See how to register with Google in this document.](https://developers.google.com/gmail/markup/registering-with-google)

*This process has a lot of steps so make sure that you fulfill all requirements set by Google.*
*Your application will be rejected by Google if you fail to do so.*

Pay close attention to:

* Email account used by GitLab to send notification emails needs to have "Consistent history of sending a high volume of mail from your domain (order of hundred emails a day minimum to Gmail) for a few weeks at least".
* "A very very low rate of spam complaints from users."
* Emails must be authenticated via DKIM or SPF
* Before sending the final form("Gmail Schema Whitelist Request"), you must send a real email from your production server. This means that you will have to find a way to send this email from the email address you are registering. You can do this by, for example, forwarding the real email from the email address you are registering or going into the rails console on the GitLab server and triggering the email sending from there.

You can check how it looks going through all the steps laid out in the "Registering with Google" doc in [this GitLab.com issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/1517).
