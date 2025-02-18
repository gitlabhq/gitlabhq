---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Spam protection and CAPTCHA
---

This guide provides an overview of how to add spam protection and CAPTCHA support to new areas of the
GitLab application.

## Add spam protection and CAPTCHA support to a new area

To add this support, you must implement the following areas as applicable:

1. [Model and Services](model_and_services.md): The basic prerequisite
   changes to the backend code which are required to add spam or CAPTCHA API and UI support
   for a feature which does not yet have support.
1. [REST API](rest_api.md): The changes needed to add
   spam or CAPTCHA support to Grape REST API endpoints. Refer to the related
   [REST API documentation](../../api/rest/troubleshooting.md#requests-detected-as-spam).
1. [GraphQL API](graphql_api.md): The changes needed to add spam or CAPTCHA support to GraphQL
   mutations. Refer to the related
   [GraphQL API documentation](../../api/graphql/_index.md#resolve-mutations-detected-as-spam).
1. [Web UI](web_ui.md): The various possible scenarios encountered when adding
   spam/CAPTCHA support to the web UI, depending on whether the UI is JavaScript API-based (Vue or
   plain JavaScript) or HTML-form (HAML) based.

You should also perform manual exploratory testing of the new feature. Refer to
[Exploratory testing](exploratory_testing.md) for more information.

## Spam-related model and API fields

Multiple levels of spam flagging determine how spam is handled. These levels are referenced in
[`Spam::SpamConstants`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/services/spam/spam_constants.rb#L4-4),
and used various places in the application, such as
[`Spam::SpamActionService#perform_spam_service_check`](https://gitlab.com/gitlab-org/gitlab/blob/d7585b56c9e7dc69414af306d82906e28befe7da/app/services/spam/spam_action_service.rb#L61-61).

The possible values include:

- `BLOCK_USER`
- `DISALLOW`
- `CONDITIONAL_ALLOW`
- `OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM`
- `ALLOW`
- `NOOP`

## Related topics

- [Spam and CAPTCHA support in the GraphQL API](../../api/graphql/_index.md#resolve-mutations-detected-as-spam)
- [Spam and CAPTCHA support in the REST API](../../api/rest/troubleshooting.md#requests-detected-as-spam)
- [reCAPTCHA Spam and Anti-bot Protection](../../integration/recaptcha.md)
- [Akismet and spam logs](../../integration/akismet.md)
