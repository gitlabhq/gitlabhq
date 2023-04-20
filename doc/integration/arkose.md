---
stage: Anti-Abuse
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Arkose Protect

DISCLAIMER:
Arkose Protect is used on GitLab.com and is not supported for self-managed GitLab
instances. The following documents the internal requirements for maintaining
Arkose Protect on GitLab.com. While this feature is theoretically usable in self-managed instances, it
is not recommended at the moment.

GitLab integrates [Arkose Protect](https://www.arkoselabs.com/arkose-protect/) to guard against
credential stuffing and bots in the sign-in form. GitLab triggers Arkose Protect if the user:

- Has never signed in before.
- Has failed to sign in twice in a row.
- Has not signed in during the past three months.

## How does it work?

If Arkose Protect determines that the user is suspicious, it presents an interactive challenge below
the `Sign in` button. The challenge needs to be completed to proceed with the sign-in
attempt. If Arkose Protect trusts the user, the challenge runs in transparent mode, meaning that the
user doesn't need to take any additional action and can sign in as usual.

```mermaid
sequenceDiagram
    participant U as User
    participant G as GitLab
    participant A as Arkose Labs
    U->>G: User loads form <br />(POST /api/:version/users/captcha_check)
    G->>A: Sends device fingerprint and telemetry
    A->>U: Returns Session token and decision on if to challenge
    opt Requires Challenge
        U->>U: User interacts with Challenge iframe
    end
    U->>G: Submits form with Arkose Labs token
    G ->> A: Sends token to be verified
    A ->> G: Returns verification response
    Note over G: records `UserCustomAttribute::risk_band`
    alt session_details.solved == true
        G ->> U: Proceed
    else session_details.solved == false
        G ->> U: Do not proceed
    end
```

## How do we treat malicious sign-in attempts?

Users are not denied access if Arkose Protect considers they are malicious. However,
their risk score is exposed in the administrator console so that we can make more informed decisions when it
comes to manually blocking users. When we decide to block a user, feedback is sent to ArkoseLabs to
improve their risk prediction model.

NOTE:
Enabling the `arkose_labs_prevent_login` feature flag results in sessions with a `High` risk
score being denied access. So far, we have kept this feature flag disabled to evaluate Arkose Protect
predictions and to make sure we are not preventing legitimate users from signing in.

That said, we have seen that interactive challenges are effective in preventing some malicious
sign-in attempts as not completing them prevents attackers from moving on to the next sign-in step.

## Configuration

To enable Arkose Protect:

1. License ArkoseLabs.
1. Get the public and private API keys from the [ArkoseLabs Portal](https://portal.arkoselabs.com/).
1. Enable the ArkoseLabs login challenge. Run the following commands in the Rails console, replacing `<your_public_api_key>` and `<your_private_api_key>` with your own API keys.

   ```ruby
   Feature.enable(:arkose_labs_login_challenge)
   ApplicationSetting.current.update(arkose_labs_public_api_key: '<your_public_api_key>')
   ApplicationSetting.current.update(arkose_labs_private_api_key: '<your_private_api_key>')
   ```

1. Optional. To prevent high risk sessions from signing, enable the `arkose_labs_prevent_login` feature flag. Run the following command in the Rails console:

   ```ruby
   Feature.enable(:arkose_labs_prevent_login)
   ```

## Triage and debug ArkoseLabs issues

You can triage and debug issues raised by ArkoseLabs with:

- The [GitLab production logs](https://log.gprd.gitlab.net).
- The [Arkose logging service](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/arkose/logger.rb).

### View ArkoseLabs Verify API response for a user session

To view an ArkoseLabs Verify API response for a user, [query the GitLab production logs](https://log.gprd.gitlab.net/goto/54b82f50-935a-11ed-9f43-e3784d7fe3ca) with the following KQL:

```plaintext
KQL: json.message:"Arkose verify response" AND json.username:replace_username_here
```

If the query is valid, the result contains debug information about the user's session:

| Response | Description |
|---------|-------------|
| `json.response.session_details.suppressed` | Value is `true` if the challenge was not shown to the user. Always `true` if the user is allowlisted. |
| `json.arkose.risk_band` | Can be `low`, `medium`, or `high`. Ignored on sign in. Use to debug identity verification issues. |
| `json.response.session_details.solved` | Indicates whether the user solved the challenge. Always `true` if the user is allowlisted. |
| `json.response.session_details.previously_verified` | Indicates whether the token has been reused. Default is `false`. If `true`, it might indicate malicious activity. |

### Check if a user failed an ArkoseLabs challenge

To check if a user failed to sign in because the ArkoseLabs challenge was not solved, [query the GitLab production logs](https://log.gprd.gitlab.net/goto/b97c8a80-935a-11ed-85ed-e7557b0a598c) with the following KQL:

```plaintext
KQL: json.message:"Challenge was not solved" AND json.username:replace_username_here`
```

## Allowlists

To ensure end-to-end QA test suites can pass during staging and production, we've [allowlisted](https://developer.arkoselabs.com/docs/verify-api-v4#creating-allowlists-and-denylists) the [GITLAB_QA_USER_AGENT](https://start.1password.com/open/i?a=LKATQYUATRBRDHRRABEBH4RJ5Y&v=6gq44ckmq23vqk5poqunurdgay&i=u2wvs63affaxzi22gnfbjjw2zm&h=gitlab.1password.com). Each QA user receives an `ALLOWLIST` [risk category](https://developer.arkoselabs.com/docs/risk-score).

You can find the usage of the allowlist telltale in our [Arkose::VerifyResponse](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/arkose/verify_response.rb#L38) class.

## Feedback Job

To help Arkose improve their protection service, we created a daily background job to send them the list of blocked users by us.
This job is performed by the `Arkose::BlockedUsersReportWorker` class.

## Test your integration

In staging and development environments only, you can suppress a challenge, or force one to appear.
You can use this feature if you want to receive a specific risk band.

To force a challenge, change your browser [user agent string](https://developer.chrome.com/docs/devtools/device-mode/override-user-agent/). You can find the appropriate string in [1Password](https://start.1password.com/open/i?a=LKATQYUATRBRDHRRABEBH4RJ5Y&v=6gq44ckmq23vqk5poqunurdgay&i=5v3ushqmfgifpwyqohop5gv5xe&h=gitlab.1password.com).

Alternatively, to request specific behaviors, modify the `setConfig` to include a `data.id` property:

- `'ML_defence'` - Force a challenge to appear.
- `'customer_request'` - Suppress a challenge. If you suppress a challenge, ArkoseLabs considers your session safe.

For example, this `setConfig` suppresses a challenge:

```javascript
      arkoseObject.setConfig({
        data: { id: 'customer_request' },
        ...
      });
```

## Additional resources

<!-- markdownlint-disable MD044 -->
The [Anti-abuse team](https://about.gitlab.com/handbook/engineering/development/data-science/anti-abuse/#team-members) owns the ArkoseLabs Protect feature. You can join our ArkoseLabs/GitLab collaboration channel on Slack: [#ext-gitlab-arkose](https://gitlab.slack.com/archives/C02SGF6RLPQ).
<!-- markdownlint-enable MD044 -->

ArkoseLabs also maintains the following resources:

- [ArkoseLabs portal](https://portal.arkoselabs.com/)
- [ArkoseLabs Zendesk](https://support.arkoselabs.com/hc/en-us)
- [ArkoseLabs documentation](https://developer.arkoselabs.com/docs/documentation-guide)
