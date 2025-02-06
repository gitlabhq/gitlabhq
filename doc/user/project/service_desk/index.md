---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service Desk
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

NOTE:
This feature is not under active development, but
[community contributions](https://about.gitlab.com/community/contribute/) are welcome.
To determine if the feature as it is meets your needs, explore the existing documentation or see the
[open issues for the Service Desk category](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=opened&label_name%5B%5D=Category%3AService%20Desk&first_page_size=100)
to learn more about work that hasn't been done yet.
The decision to deprioritize Service Desk has been made to
focus on building and extending the work item framework which
the Service Desk category will also benefit from long-term.

With Service Desk, your customers
can email you bug reports, feature requests, or general feedback.
Service Desk provides a unique email address, so they don't need their own GitLab accounts.

Service Desk emails are created in your GitLab project as new issues.
Your team can respond directly from the project, while customers interact with the thread only
through email.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video overview, see [Introducing GitLab Service Desk (GitLab 16.7)](https://www.youtube.com/watch?v=LDVQXv3I5rI).
<!-- Video published on 2023-12-19 -->

## Service Desk workflow

For example, let's assume you develop a game for iOS or Android.
The codebase is hosted in your GitLab instance, built and deployed
with GitLab CI/CD.

Here's how Service Desk works for you:

1. You provide a project-specific email address to your paying customers, who can email you directly
   from the application.
1. Each email they send creates an issue in the appropriate project.
1. Your team members go to the Service Desk issue tracker, where they can see new support
   requests and respond inside associated issues.
1. Your team communicates with the customer to understand the request.
1. Your team starts working on implementing code to solve your customer's problem.
1. When your team finishes the implementation, the merge request is merged and the issue
   is closed automatically.

Meanwhile:

- The customer interacts with your team entirely through email, without needing access to your
  GitLab instance.
- Your team saves time by not having to leave GitLab (or set up integrations) to follow up with
  your customer.

## Related topics

- [Configure Service Desk](configure.md)
  - [Improve your project's security](configure.md#improve-your-projects-security)
  - [Customize emails sent to external participants](configure.md#customize-emails-sent-to-external-participants)
  - [Use a custom template for Service Desk tickets](configure.md#use-a-custom-template-for-service-desk-tickets)
  - [Support Bot user](configure.md#support-bot-user)
  - [Default ticket visibility](configure.md#default-ticket-visibility)
  - [Reopen issues when an external participant comments](configure.md#reopen-issues-when-an-external-participant-comments)
  - [Custom email address](configure.md#custom-email-address)
  - [Use an additional Service Desk alias email](configure.md#use-an-additional-service-desk-alias-email)
  - [Configure email ingestion in multi-node environments](configure.md#configure-email-ingestion-in-multi-node-environments)
- [Use Service Desk](using_service_desk.md)
  - [As an end user (issue creator)](using_service_desk.md#as-an-end-user-issue-creator)
  - [As a responder to the issue](using_service_desk.md#as-a-responder-to-the-issue)
  - [Email contents and formatting](using_service_desk.md#email-contents-and-formatting)
  - [Convert a regular issue to a Service Desk ticket](using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket)
  - [Privacy considerations](using_service_desk.md#privacy-considerations)
- [External Participants](external_participants.md)
  - [Service Desk tickets](external_participants.md#service-desk-tickets)
  - [As an external participant](external_participants.md#as-an-external-participant)
  - [As a GitLab user](external_participants.md#as-a-gitlab-user)

## Troubleshooting Service Desk

### Emails to Service Desk do not create issues

- Your emails might be ignored because they contain one of the
  [email headers that GitLab ignores](../../../administration/incoming_email.md#rejected-headers).
- Emails might get dropped if the sender email domain is using strict DKIM rules and there is a verification
  failure due to forwarding emails to the project-specific Service Desk address.
  A typical DKIM failure message, which can be found in email headers, might look like:

  ```plaintext
  dkim=fail (signature did not verify) ... arc=fail
  ```

  The exact wording of the failure message may vary depending on the specific email system or tools in use.
  Also see [this article on DKIM failures](https://automatedemailwarmup.com/blog/dkim-fail/) for more
  information and potential solutions.

### Email ingestion doesn't work in 16.6.0

GitLab Self-Managed `16.6.0` introduced a regression that prevents `mail_room` (email ingestion) from starting.
Service Desk and other reply-by-email features don't work.
[Issue 432257](https://gitlab.com/gitlab-org/gitlab/-/issues/432257) tracks fixing this problem.

The workaround is to run the following commands in your GitLab installation
to patch the affected files:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
patch -p1 -d /opt/gitlab/embedded/service/gitlab-rails < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

:::TabTitle Docker

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
cd /opt/gitlab/embedded/service/gitlab-rails
patch -p1 < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

::EndTabs
