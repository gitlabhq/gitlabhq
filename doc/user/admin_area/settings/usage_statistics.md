# Usage statistics

GitLab Inc. will periodically collect information about your instance in order
to perform various actions.

All statistics are opt-out, you can disable them from the admin panel.

## Version check

GitLab can inform you when an update is available and the importance of it.

No information other than the GitLab version and the instance's domain name
are collected.

In the **Overview** tab you can see if your GitLab version is up to date. There
are three cases: 1) you are up to date (green), 2) there is an update available
(yellow) and 3) your version is vulnerable and a security fix is released (red).

In any case, you will see a message informing you of the state and the
importance of the update.

If enabled, the version status will also be shown in the help page (`/help`)
for all signed in users.

## Usage ping

> [Introduced][ee-557] in GitLab Enterprise Edition 8.10. More statistics
[were added][ee-735] in GitLab Enterprise Edition
8.12. [Moved to GitLab Community Edition][ce-23361] in 9.1.

GitLab sends a weekly payload containing usage data to GitLab Inc. The usage
ping uses high-level data to help our support and sales teams. It does not send
any project names, usernames, or any other specific data. The information from
the usage ping is not anonymous, it is linked to the hostname of the instance.

You can view the exact JSON payload in the administration panel
(`/admin/application_settings`). Here you can also disable the usage ping.
