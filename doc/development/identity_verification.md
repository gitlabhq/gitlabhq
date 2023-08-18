---
stage: Data Science
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Identity verification development

For information on this feature that are not development-specific, see the [feature documentation](../security/identity_verification.md).

## Feature flags

Because of the many registration paths and multiple verification stages, identity verification has several feature flags.

Before you enable these features, ensure [hard email confirmation](../security/user_email_confirmation.md) is enabled and [Arkose](../integration/arkose.md#configuration) is configured properly.

| Feature flag name | Description |
|---------|-------------|
| `identity_verification` | Turns on email verification for all registration paths |
| `identity_verification_phone_number` | Turns on phone verification for medium risk users for all flows (the Arkose challenge flag for the specific flow and the `identity_verification` flag must be enabled for this to have effect) |
| `identity_verification_credit_card` | Turns on credit card verification for high risk users for all flows (the Arkose challenge flag for the specific flow and the `identity_verification` flag must be enabled for this to have effect) |
| `arkose_labs_signup_challenge` | Enables Arkose challenge for all flows, except the Trial and OAuth flows |
| `arkose_labs_trial_signup_challenge` | Enables Arkose challenge for the Trial flow (the `arkose_labs_signup_challenge` flag must be enabled as well for this to have effect) |
| `arkose_labs_oauth_signup_challenge` | Enables Arkose challenge for the OAuth flow |

## Logging

You can triage and debug issues raised by identity verification with the [GitLab production logs](https://log.gprd.gitlab.net).

### View logs associated to a user and email verification

To view logs associated to the [email stage](../security/identity_verification.md#email-verification) for a user:

- Query the GitLab production logs with the following KQL:

  ```plaintext
  KQL: json.controller:"IdentityVerificationController" AND json.username:replace_username_here
  ```

Valuable debugging information can be found in the `json.action` and `json.location` columns.

### View logs associated to a user and phone verification

To view logs associated to the [phone stage](../security/identity_verification.md#phone-number-verification) for a user:

- Query the GitLab production logs with the following KQL:

  ```plaintext
  KQL: json.message: "IdentityVerification::Phone" AND json.username:replace_username_here
  ```

On rows where `json.event` is `Failed Attempt`, you can find valuable debugging information in the `json.reason` column such as:

| Reason  | Description |
|---------|-------------|
| `invalid_phone_number` | Either there was a typo in the phone number, or the user used a VOIP number. GitLab does not allow users to sign up with non-mobile phone numbers. |
| `invalid_code` | The user entered an incorrect verification code. |
| `rate_limited` | The user had 10 or more failed attempts, so they were rate-limited for one hour. |
| `related_to_banned_user` | The user tried a phone number already related to a banned user. |

#### View Telesign SMS status update logs

To view logs of Telesign status updates for an SMS sent to a user:

1. Get a `telesign_reference_id` value for an SMS sent to a specific user:

   ```plaintext
   json.message: "IdentityVerification::Phone" AND json.username:<username>`
   ```

1. Search for status update logs associated with `telesign_reference_id` value:

   ```plaintext
   json.message: "IdentityVerification::Phone" AND json.event: "Telesign transaction status update" AND json.telesign_reference_id:replace_ref_id_value_here`
   ```

Status update logs include the following fields:

| Field  | Description |
|---------|-------------|
| `telesign_status` | Delivery status of the SMS. See the [Telesign documentation](https://developer.telesign.com/enterprise/reference/smscallbacks#status-codes) for possible status codes and their descriptions. |
| `telesign_status_updated_on` | A timestamp indicating when the SMS delivery status was last updated. |
| `telesign_errors` | Errors that occurred during delivery. See the [Telesign documentation](https://developer.telesign.com/enterprise/reference/smscallbacks#status-codes) for possible error codes and their descriptions. |

### View logs associated to a user and credit card verification

To view logs associated to the [credit card stage](../security/identity_verification.md#credit-card-verification) for a user:

- Query the GitLab production logs with the following KQL:

  ```plaintext
  KQL: json.message: "IdentityVerification::CreditCard" AND json.username:replace_username_here
  ```

On rows where `json.event` is `Failed Attempt`, you can find valuable debugging information in the `json.reason` column such as:

| Reason  | Description |
|---------|-------------|
| `rate_limited` | The user had 10 or more failed attempts, so they were rate-limited for one hour. |
| `related_to_banned_user` | The user tried a credit card number already related to a banned user. |

### View logs associated with high-risk users

To view logs associated with the [credit card stage](../security/identity_verification.md#credit-card-verification) for high-risk users:

- Query the GitLab production logs with the following KQL:

  ```plaintext
  json.controller:"SubscriptionsController" AND json.action:"payment_form" AND json.params.value:"cc_registration_validation"
  ```

## Code walkthrough

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a walkthrough and high level explanation of the code, see [Identity Verification - Code walkthrough](https://www.youtube.com/watch?v=DIsnMiNzND8).

## QA Integration

For end-to-end production and staging tests to function properly, GitLab [allows QA users to bypass identity verification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117633).

## Additional resources

<!-- markdownlint-disable MD044 -->
The [Anti-abuse team](https://about.gitlab.com/handbook/engineering/development/data-science/anti-abuse/#team-members) owns identity verification. You can join our channel on Slack: [#g_anti-abuse](https://gitlab.slack.com/archives/C03EH5HCLPR).
<!-- markdownlint-enable MD044 -->

For help with Telesign:

<!-- markdownlint-disable MD044 -->
- Telesign/GitLab collaboration channel on Slack: [#gitlab-telesign-support](https://gitlab.slack.com/archives/C052EAXB6BY)
<!-- markdownlint-enable MD044 -->
- Telesign support contact: `support@telesign.com`
- [Telesign portal](https://teleportal.telesign.com/)
- [Telesign documentation](https://developer.telesign.com/enterprise/docs/get-started-with-docs)
