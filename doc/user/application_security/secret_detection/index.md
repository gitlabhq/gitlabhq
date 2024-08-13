---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret detection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Your application might use external resources, including a CI/CD
service, a database, or external storage. Access to these resources
requires authentication, usually using static methods like private
keys and tokens. These methods are called "secrets" because they're
not meant to be shared with anyone else.

To minimize the risk of exposing your secrets, always store secrets outside of the repository. However, secrets are sometimes accidentally committed to Git
repositories. After a sensitive value is pushed to a remote
repository, anyone with access to the repository can use the secret to
impersonate the authorized user.
Secret detection monitors your activity to help prevent your secrets
from being exposed. GitLab has three methods for detecting secrets, which
you can use simultaneously:

- The [pipeline](pipeline/index.md) method detects secrets during the project's CI/CD pipeline.
  Pipeline secret detection works with all text files, regardless of language or framework.
  This method cannot reject pushes.
- The [secret push protection](secret_push_protection/index.md) method detects secrets when users push changes to the
  remote Git branch. This method can reject pushes if a secret is detected.
- The [client-side](client/index.md) method runs in your browser, and warns you if the content of text you're about
  to post contains a potential secret.

If a secret is committed to a repository, GitLab records the exposure
in the Vulnerability Report. For some secret types, GitLab can even
automatically revoke the exposed secret. You should always revoke and
replace exposed secrets as soon as possible.

## Related topics

- [Vulnerability Report](../vulnerability_report/index.md)
- [Automatic response to leaked secrets](automatic_response.md)
