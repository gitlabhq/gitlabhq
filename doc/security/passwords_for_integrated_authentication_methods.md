---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Generated passwords for users created through integrated authentication **(FREE)**

GitLab allows users to set up accounts through integration with external [authentication and authorization providers](../administration/auth/index.md).

These authentication methods do not require the user to explicitly create a password for their accounts.
However, to maintain data consistency, GitLab requires passwords for all user accounts.

For such accounts, we use the [`friendly_token`](https://github.com/heartcombo/devise/blob/f26e05c20079c9acded3c0ee16da0df435a28997/lib/devise.rb#L492) method provided by the Devise gem to generate a random, unique and secure password and sets it as the account password during sign up.

The length of the generated password is the set based on the value of [maximum password length](password_length_limits.md#modify-maximum-password-length-using-configuration-file) as set in the Device configuration. The default value is 128 characters.
