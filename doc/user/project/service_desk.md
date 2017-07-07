# Service Desk

> [Introduced][ee-149] in [GitLab Enterprise Edition Premium 9.1][eep-9.1].

## Overview

Service Desk is a module that allows your team to connect directly
with any external party through email right inside of GitLab; no external tools required.
An ongoing conversation right where your software is built ensures that user feedback ends up directly where needed,
helping you build the right features to solve your user's real problems.

Provide efficient email support to your customers, who can email bug reports,
feature requests, or any other general feedback directly into your GitLab project as a new issue.
In turn, your team can respond straight from the project.

As Service Desk is built right into GitLab itself, the complexity and inefficiencies
of multiple tools and external integrations are eliminated, significantly shortening
the cycle time from feedback to software update.

## Use cases

For instance, let's assume you develop a game for iOS or Android.
The codebase is hosted in your GitLab instance, built and deployed
with GitLab CI.

1. Offer email support to your paying customers, who can email you directly from their app
1. The email they send creates an issue in the appropriate project
1. Your team members reply to that issue thread to follow up with your customer
1. Your team starts working on implementing code to solve your customer's problem
1. When your team finishes the implementation, their merged merge request will close the issue
1. The customer will have been attended successfully through GitLab, without having real access to your GitLab instance
1. Your team saved time by not having to leave GitLab (or setup any integrations) to follow up with your customer

## How it works

GitLab Service Desk is a simple way to allow people to create issues in your
GitLab instance without needing their own user account.

It provides a unique email address for end users to create issues in a project,
and replies can be sent either through the GitLab interface or by email. End
users will only see the thread through email.

## Configuring Service Desk

> **Note:**
Service Desk is enabled on GitLab.com. If you're a
[Silver subscriber](https://about.gitlab.com/gitlab-com/),
you can skip the step 1 below; you only need to enable it per project.

1.   [Set up reply by email][reply-by-email] for the GitLab instance. This must
     support [email sub-addressing][email-sub-addressing].
2.   Navigate to your project's **Settings** and scroll down to the **Service Desk**
     section.
3.   If you have the correct access and an Enterprise Edition Premium license,
     you will see an option to set up Service Desk:

     ![Activate Service Desk option](img/service_desk_disabled.png)
4.   Checking that box will enable Service Desk for the project, and show a
     unique email address to email issues to the project. These issues will be
     [confidential], so they will only be visible to project members.

     **Warning**: as the screenshot below shows, this email address can be used
     by anyone to create an issue on this project, whether or not they have
     access to your GitLab instance. We recommend **putting this behind an
     alias** so that it can be changed if needed, and
     **[enabling Akismet][akismet]** on your GitLab instance to add spam
     checking to this service.

     ![Service Desk enabled](img/service_desk_enabled.png)
5.   Service Desk is now enabled for this project!

## Using Service Desk

### As an end user (issue creator)

To create a Service Desk issue, an end user doesn't need to know anything about
the GitLab instance. They just send an email to the address they are given, and
receive an email back confirming receipt:

![Service Desk enabled](img/service_desk_confirmation_email.png)

This also gives the end user an option to unsubscribe.

If they don't choose to unsubscribe, then any new comments added to the issue
will be sent as emails:

![Service Desk reply email](img/service_desk_reply.png)

And any responses they send will be displayed in the issue itself.

### As a responder to the issue

For responders to the issue, everything works as usual. Messages from the end
user will show as coming from the special Support Bot user, but apart from that,
you can read and write comments as you normally do:

![Service Desk issue thread](img/service_desk_thread.png)

> Note that the project's visibility (private, internal, public) does not affect Service Desk. 

[ee-149]: https://gitlab.com/gitlab-org/gitlab-ee/issues/149 "Service Desk with email"
[ee]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition landing page"
[eep-9.1]: https://about.gitlab.com/2017/04/22/gitlab-9-1-released/#service-desk-eep
[reply-by-email]: ../../administration/reply_by_email.md#set-it-up
[email-sub-addressing]: ../../administration/reply_by_email.md#email-sub-addressing
[confidential]: ./issues/confidential_issues.md "Confidential issues"
[akismet]: ../../integration/akismet.md
