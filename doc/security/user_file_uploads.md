# User File Uploads

Images attached to issues, merge requests or comments do not require authentication
to be viewed if someone knows the direct URL. This direct URL contains a random
32-character ID that prevents unauthorized people from guessing the URL to an
image containing sensitive information. We don't enable authentication because
these images need to be visible in the body of notification emails, which are
often read from email clients that are not authenticated with GitLab, like
Outlook, Apple Mail, or the Mail app on your mobile device.

Note that non-image attachments do require authentication to be viewed.
