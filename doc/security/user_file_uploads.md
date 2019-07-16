---
type: reference
---

# User File Uploads

Images that are attached to issues, merge requests, or comments
do not require authentication to be viewed if they are accessed directly by URL.
This direct URL contains a random 32-character ID that prevents unauthorized
people from guessing the URL for an image, thus there is some protection if an
image contains sensitive information.

Authentication is not enabled because images must be visible in the body of
notification emails, which are often read from email clients that are not
authenticated with GitLab, such as Outlook, Apple Mail, or the Mail app on your
mobile device.

>**Note:**
Non-image attachments do require authentication to be viewed.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
