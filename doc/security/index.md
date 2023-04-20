---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index
---

# Secure your installation **(FREE)**

- [Passwords and OAuth tokens storage](password_storage.md)
- [Password length limits](password_length_limits.md)
- [Generated passwords for users created through integrated authentication](passwords_for_integrated_authentication_methods.md)
- [Restrict SSH key technologies and minimum length](ssh_keys_restrictions.md)
- [Rate limits](rate_limits.md)
- [Filtering outbound requests](webhooks.md)
- [Information exclusivity](information_exclusivity.md)
- [Reset user password](reset_user_password.md)
- [Unlock a locked user](unlock_user.md)
- [User File Uploads](user_file_uploads.md)
- [How we manage the CRIME vulnerability](crime_vulnerability.md)
- [Enforce Two-factor authentication](two_factor_authentication.md)
- [Send email confirmation on sign-up](user_email_confirmation.md)
- [Security of running jobs](https://docs.gitlab.com/runner/security/)
- [Proxying images](asset_proxy.md)
- [CI/CD variables](../ci/variables/index.md#cicd-variable-security)
- [Token overview](token_overview.md)
- [Project Import decompressed archive size limits](project_import_decompressed_archive_size_limits.md)
- [Responding to security incidents](responding_to_security_incidents.md)

To harden your GitLab instance and minimize the risk of unwanted user account creation, consider access control features like [Sign up restrictions](../user/admin_area/settings/sign_up_restrictions.md) and [Authentication options](../topics/authentication/index.md) .

Self-managed GitLab customers and administrators are responsible for the security of their underlying hosts, and for keeping GitLab itself up to date. It is important to [regularly patch GitLab](../policy/maintenance.md), patch your operating system and its software, and harden your hosts in accordance with vendor guidance.
