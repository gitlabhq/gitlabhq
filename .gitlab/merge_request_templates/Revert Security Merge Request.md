[Reverting a security merge request] is not encouraged because it rollbacks a security fix
compromising the integrity of GitLab.com, self-managed and in-house instances. If a security merge request
introduced a bug, the next steps will depend on the severity of the security issue, the impact of
the bug introduced and the timeline of the patch release. Consult the [other ways of mitigating the bug]
before continuing with the revert.

## Purpose of the revert

<!-- Please write down the reason why the revert is required, the severity of the security issue
and the severity the bug fix and due date of the patch release -->

* Severity of the security issue: {+ severity +}
* Severity of the bug: {+ severity +}
* Due date of the [ongoing patch release]: {+ yyyy/mm/dd +}

## Checklist:

- [ ] Stage team has contacted AppSec and [release managers] and explained why the revert is necessary.
- [ ] The security issue has been removed from the [patch release].
- [ ] **AppSec Approval: AppSec agrees and understands the vulnerability will be disclosed without being fixed when the patch release is published**


[Reverting a security merge request]: https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/security/bugs_introduced_by_security_merge_request.md?ref_type=heads
[other ways of mitigating the bug]: https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/security/bugs_introduced_by_security_merge_request.md?ref_type=heads
[patch release]: https://gitlab.com/gitlab-org/gitlab/-/issues/?label_name%5B%5D=upcoming%20security%20release
[release managers]: https://about.gitlab.com/community/release-managers/
