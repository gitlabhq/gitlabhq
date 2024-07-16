---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret Detection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Your application might use external resources, including a CI/CD
service, a database, or external storage. Access to these resources
requires authentication, usually using static methods like private
keys and tokens. These methods are called "secrets" because they're
not meant to be shared with anyone else.

People sometimes accidentally commit secrets to Git
repositories. After a sensitive value is pushed to a remote
repository, anyone with access to the repository can use the secret to
impersonate the authorized user for malicious purposes. To address
this risk, you should store your secrets outside your remote
repositories. If a secret is exposed, you should revoke and replace it
as soon as possible.

Secret Detection scans your repository to help prevent your secrets
from being exposed. Secret Detection scanning works on all text files,
regardless of the language or framework used.

GitLab has three methods for detecting secrets, which can be used simultaneously:

- The [pipeline](pipeline/index.md) method detects secrets during the project's CI/CD pipeline. This method cannot reject pushes.
- The [secret push protection](secret_push_protection/index.md) method detects secrets when users push changes to the
  remote Git branch. This method can reject pushes if a secret is detected.
- The [client-side](client/index.md) method runs in your browser, and warns you if the content of text you're about
  to post contains a potential secret.
