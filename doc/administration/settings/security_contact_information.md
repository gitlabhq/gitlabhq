---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Provide public security contact information
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/433210) in GitLab 16.7.

Organizations can facilitate the responsible disclosure of security issues by
providing public contact information. GitLab supports using a
[`security.txt`](https://securitytxt.org/) file for this purpose.

Administrators can add a `security.txt` file using the GitLab UI or the
[REST API](../../api/settings.md#update-application-settings).
Any content added is made available at
`https://gitlab.example.com/.well-known/security.txt`. Authentication is not
required to view this file.

To configure a `security.txt` file:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Add security contact information**.
1. In **Content for security.txt**, enter security contact information in the
   format documented at <https://securitytxt.org/>.
1. Select **Save changes**.

For information about how to respond if you receive a report, see
[Responding to security incidents](../../security/responding_to_security_incidents.md).

## Example `security.txt` file

The format of this information is documented at <https://securitytxt.org/>.
An example `security.txt` file is:

```plaintext
Contact: mailto:security@example.com
Expires: 2024-12-31T23:59Z
```
