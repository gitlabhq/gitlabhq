# Akismet

GitLab leverages [Akismet](http://akismet.com) to protect against spam. Currently
GitLab uses Akismet to prevent users who are not members of a project from
creating spam via the GitLab API. Detected spam will be rejected, and
an entry in the "Spam Log" section in the Admin page will be created.

> *Note:* As of 8.10 GitLab also submits issues created via the WebUI by non
project members to Akismet to prevent spam.

Privacy note: GitLab submits the user's IP and user agent to Akismet. Note that
adding a user to a project will disable the Akismet check and prevent this
from happening.

## Configuration

To use Akismet:

1. Go to the URL: https://akismet.com/account/

2. Sign-in or create a new account.

3. Click on "Show" to reveal the API key.

4. Go to Applications Settings on Admin Area (`admin/application_settings`)

5. Check the `Enable Akismet` checkbox

6. Fill in the API key from step 3.

7. Save the configuration.

![Screenshot of Akismet settings](img/akismet_settings.png)
