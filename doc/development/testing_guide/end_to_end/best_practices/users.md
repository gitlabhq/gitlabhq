---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Environment Setup | Users

Most tests ([orchestrated and instance-level](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#the-two-types-of-qa-tests)) [run as the default `root` user](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/runtime/user.rb#L16). However, some require additional users. If the test framework has administrator access to the test environment it can create users itself. If administrator access is not available you will need to create users before being able to run certain tests.

## Disable email verification

If [email verification](../../../../security/email_verification.md) is enabled on the test environment (via the `require_email_verification` feature flag), a user cannot log in under certain conditions (e.g., logging in the first time from a new location) unless they enter a verification code that is sent to their email address.

To disable email verification you can disable the `require_email_verification` feature flag, which will disable email verification for all users on the instance. Alternatively, you can skip verification for individual users by enabling the `skip_require_email_verification` feature flag for that user.
