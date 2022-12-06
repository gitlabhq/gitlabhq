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
credential stuffing and bots in the sign-in form. GitLab will trigger Arkose Protect if the user:

- Has never signed in before.
- Has failed to sign in twice in a row.
- Has not signed in during the past three months.

## How does it work?

If Arkose Protect determines that the user is suspicious, it presents an interactive challenge below
the `Sign in` button. The challenge needs to be completed to proceed with the sign-in
attempt. If Arkose Protect trusts the user, the challenge runs in transparent mode, meaning that the
user doesn't need to take any additional action and can sign in as usual.

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

## QA tests caveat

Several GitLab QA test suites need to sign in to the app to test its features. This can conflict
with Arkose Protect as it would identify QA users as being malicious because they are being run with
a headless browser. To work around this, ArkoseLabs has allowlisted the unique token
that serves as QA session's User Agent. While this doesn't guarantee that the session won't be
flagged as malicious, Arkose's API returns a specific telltale when we verify the sign in
attempt's token. We are leveraging this telltale to bypass the verification step entirely so that the
test suite doesn't fail. This bypass is done in the `UserVerificationService` class.

## Feedback Job

To help Arkose improve their protection service, we created a daily background job to send them the list of blocked users by us.
This job is performed by the `Arkose::BlockedUsersReportWorker` class.
