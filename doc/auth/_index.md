---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authentication and authorization
description: User identity, authentication, permissions, access controls, and security best practices.
---

GitLab uses authentication and authorization to protect your resources without limiting collaboration.

Authentication verifies who you are using methods such as passwords, two-factor authentication,
SSH keys, access tokens, and external identity providers like SAML and OAuth. Authorization
determines what you can do with roles and granular permissions to control access to groups,
projects, and resources. Together, these systems create a security framework that scales from
individual users to enterprise organizations.

Understanding the GitLab security model helps you implement access controls that balance security
requirements with operational efficiency.

{{< cards >}}

- [User identity](../administration/auth/_index.md)
- [User authentication](user_authentication.md)
- [User permissions](user_permissions.md)
- [Authentication best practices](auth_practices.md)
- [Authentication glossary](auth_glossary.md)

{{< /cards >}}
