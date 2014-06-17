# Slack integration

## On Slack

To enable Slack integration you must create an Incoming WebHooks integration on Slack;

1.  Sign in to [Slack](https://slack.com) (https://YOURSUBDOMAIN.slack.com/services)
1.  Click on the Integrations menu at the top of the page.
1.  Add a new Integration.
1.  Pick Incoming WebHooks
1.  Choose the channel name you want to send notifications to, in the Settings section
1.  Add Integrations.
    - Optional step; You can change bot's name and avatar by clicking "change the name of your bot", and "change the icon" after that you have to click "Save settings".

Now, Slack is ready to get external hooks. Before you leave this page don't forget to get the Token that you'll need on GitLab. You can find it by clicking Expand button, located in the "Instructions for creating Incoming WebHooks" section. It's a random alpha-numeric text 24 characters long.

## On GitLab

After Slack is ready we need to setup GitLab. Here are the steps to achieve this.

1.  Sign in to GitLab

1.  Pick the repository you want.

1.  Navigate to Settings -> Services -> Slack

1.  Fill in your Slack details

    - Mark as active it
    - Type your subdomain's prefix (If your subdomain is https://somedomain.slack.com you only have to type the somedomain)
    - Type in the token you got from Slack
    - Type in the channel name you want to use (eg. #announcements)

Have fun :)

*P.S. You can set "branch,pushed,Compare changes" as highlight words on your Slack profile settings, so that you can be aware of new commits when somebody pushes them.*
