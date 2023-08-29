---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Service Desk **(FREE ALL)**

With Service Desk, your customers
can email you bug reports, feature requests, or general feedback.
Service Desk provides a unique email address, so they don't need their own GitLab accounts.

Service Desk emails are created in your GitLab project as new issues.
Your team can respond directly from the project, while customers interact with the thread only
through email.

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
  - [Customize emails sent to the requester](configure.md#customize-emails-sent-to-the-requester)
  - [Use a custom template for Service Desk tickets](configure.md#use-a-custom-template-for-service-desk-tickets)
  - [Support Bot user](configure.md#support-bot-user)
  - [Custom email address (Beta)](configure.md#custom-email-address)
  - [Use an additional Service Desk alias email](configure.md#use-an-additional-service-desk-alias-email)
  - [Configure email ingestion in multi-node environments](configure.md#configure-email-ingestion-in-multi-node-environments)
- [Use Service Desk](using_service_desk.md#use-service-desk)
  - [As an end user (issue creator)](using_service_desk.md#as-an-end-user-issue-creator)
  - [As a responder to the issue](using_service_desk.md#as-a-responder-to-the-issue)
  - [Email contents and formatting](using_service_desk.md#email-contents-and-formatting)
  - [Privacy considerations](using_service_desk.md#privacy-considerations)

## Troubleshooting Service Desk

### Emails to Service Desk do not create issues

Your emails might be ignored because they contain one of the
[email headers that GitLab ignores](../../../administration/incoming_email.md#rejected-headers).
