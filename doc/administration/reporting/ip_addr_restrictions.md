---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IP address restrictions
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

IP address restrictions help prevent malicious users hiding their activities behind multiple IP addresses.

GitLab maintains a list of the unique IP addresses used by a user to make requests over a specified period. When the
specified limit is reached, any requests made by the user from a new IP address are rejected with a `403 Forbidden` error.

IP addresses are cleared from the list when no further requests have been made by the user from the IP address in the specified time period.

NOTE:
When a runner runs a CI/CD job as a particular user, the runner IP address is also stored against the user's list of
unique IP addresses. Therefore, the IP addresses per user limit should take into account the number of configured active runners.

## Configure IP address restrictions

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Reporting**.
1. Expand **Spam and Anti-bot Protection**.
1. Update the IP address restrictions settings:
   1. Select the **Limit sign in from multiple IP addresses** checkbox to enable IP address restrictions.
   1. Enter a number in the **IP addresses per user** field, greater than or equal to `1`. This number specifies the
      maximum number of unique IP addresses a user can access GitLab from in the specified time period before requests
      from a new IP address are rejected.
   1. Enter a number in the **IP address expiration time** field, greater than or equal to `0`. This number specifies the
      time in seconds an IP address counts towards the limit for a user, taken from the time the last request was made.
1. Select **Save changes**.
