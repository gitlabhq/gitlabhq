# Akismet

> *Note:* Before 8.11 only issues submitted via the API and for non-project
members were submitted to Akismet.

GitLab leverages [Akismet](http://akismet.com) to protect against spam. Currently
GitLab uses Akismet to prevent the creation of spam issues on public projects. Issues
created via the WebUI or the API can be submitted to Akismet for review.

Detected spam will be rejected, and an entry in the "Spam Log" section in the
Admin page will be created.

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
