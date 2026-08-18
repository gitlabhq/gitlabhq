# Security Fix Process

Confidential security vulnerabilities follow a dedicated workflow on the
**security repositories** so the vulnerability and its fix are not disclosed
before the coordinated patch release.

## Identifying a security fix

Treat an issue as a security fix ONLY when all three conditions hold:

- The issue is **confidential**.
- The issue has the `~security` label.
- The issue does NOT have the `~security-fix-in-public` label.

DO NOT infer this from the issue content, title, or description — decide
strictly on the labels and confidentiality above. If you are unsure whether the
process applies, report back to the user rather than deciding from the content.

## What to do

- Prepare the fix on a branch whose name starts with `security-` (for example
  `security-fix-<name>`). This is the key requirement: the `security-` prefix
  lets tooling and the security remote block accidental exposure.
  If the user intends to use a branch that is not prefixed by `security-` you must
  explain why we must use a `security-` prefixed branch to them and push back.
- DO NOT push to `gitlab-org/gitlab`. Security fixes go to the security repository
  [`gitlab-org/security/gitlab`](https://gitlab.com/gitlab-org/security/gitlab),
  and only after running `scripts/security-harness` (which installs a Git
  `pre-push` hook that blocks pushing to any other remote).
- DO NOT disclose the vulnerability or fix outside the confidential security
  issue and the security-repo merge requests: do not comment on or cross-link it
  from the original canonical issue or any public issue, merge request, or epic.

## Further process

The rest of the workflow — the security implementation issue, merge requests,
backports, approvals, and release — is primarily the user's responsibility and is
described in the
[Preparing security fixes runbook](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md).
Report back to the user with the next steps.
