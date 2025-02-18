---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Environment Setup | Users
---

## Administrator user

E2E test framework utilizes administrator user for certain resource creation, like `user` or for changing certain instance level settings. It is not necessary to explicitly configure administrator user for environments used in [test-pipelines](../test_pipelines.md) because these environments automatically create administrator user with known default credentials and personal access token. If administrator user requires different credentials, these can be configured through following environment variables:

- `GITLAB_ADMIN_USERNAME`
- `GITLAB_ADMIN_PASSWORD`
- `GITLAB_QA_ADMIN_ACCESS_TOKEN`: this variable is optional and would be created via UI using administrator credentials when not set.

Administrator user can be accessed via global accessor method `QA::Runtime::User::Store.admin_user`.

## Test user

All tests running against one of the [test-pipelines](../test_pipelines.md) automatically create a new test user for each test. Resource instance of this user is then made globally available via `QA::Runtime::User::Store.test_user` accessor method. All user related actions like signing in or creating other objects via API by default will use this user's credentials or personal access token. Automatic user creation is performed by using administrator user personal access token which is pre-seeded automatically on all ephemeral environments used in [test-pipelines](../test_pipelines.md).

### Using single user

It is advised to not run all tests using single user but certain environments impose limitations for generating new user for each test. In order to forcefully disable unique test user creation, environment variable `QA_CREATE_UNIQUE_TEST_USERS` should be set to false. Example reason why unique user creation might be disabled:

- environment does have administrator user available and can create new users but it has only one top level group with ultimate license. In such case, a single user which is a member of this group has to be used due to new unique users not having access to the common group with ultimate license.

In such case, `test user` is initialized using credentials from environments variables - `GITLAB_USERNAME` and `GITLAB_PASSWORD`. Additionally, to provide a pre-configured personal access token for test user, `GITLAB_QA_ACCESS_TOKEN` variable can be set.

### No admin environments

Certain environments might not have administrator user and have no ability to create one. For tests to work when running against such environment, test user must be configured via environment variables mentioned in [Using single user](#using-single-user) section. Additionally, to prevent test framework from trying to initialize administrator user, environment variable `QA_NO_ADMIN_ENV` must be set to `true`.

#### Additional test user

In case the test is running on an environment with no admin environment or an environment that doesn't allow user creation, it is possible to use a second pre-configured user in the test.
Credentials for this user must be configured using `GITLAB_QA_USERNAME_1` and `GITLAB_QA_PASSWORD_1` environment variables.
The instance of the user can be accessed using the method `QA::Runtime::User::Store.additional_test_user`.
This method also ensures that on environments that allow for user fabrication, the test will create a new unique user rather than relying on a pre-configured one.

## Disable email verification

If [email verification](../../../../security/email_verification.md) is enabled on the test environment (via the `require_email_verification` feature flag), a user cannot log in under certain conditions (e.g., logging in the first time from a new location) unless they enter a verification code that is sent to their email address.

To disable email verification you can disable the `require_email_verification` feature flag, which will disable email verification for all users on the instance. Alternatively, you can skip verification for individual users by enabling the `skip_require_email_verification` feature flag for that user.
