# Automatic CE->EE merge

GitLab Community Edition is merged automatically every 3 hours into the
Enterprise Edition (look for the [`CE Upstream` merge requests]).

This merge is done automatically in a
[scheduled pipeline](https://gitlab.com/gitlab-org/release-tools/-/jobs/43201679).
If a merge is already in progress, the job [doesn't create a new one](https://gitlab.com/gitlab-org/release-tools/-/jobs/43157687).

**If you are pinged in a `CE Upstream` merge request to resolve a conflict,
please resolve the conflict as soon as possible or ask someone else to do it!**

>**Note:**
It's ok to resolve more conflicts than the one that you are asked to resolve. In
that case, it's a good habit to ask for a double-check on your resolution by
someone who is familiar with the code you touched.

[`CE Upstream` merge requests]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests?label_name%5B%5D=CE+upstream

## Always merge EE merge requests before their CE counterparts

**In order to avoid conflicts in the CE->EE merge, you should always merge the
EE version of your CE merge request first, if present.**

The rationale for this is that as CE->EE merges are done automatically every few
hours, it can happen that:

1. A CE merge request that needs EE-specific changes is merged
1. The automatic CE->EE merge happens
1. Conflicts due to the CE merge request occur since its EE merge request isn't
  merged yet
1. The automatic merge bot will ping someone to resolve the conflict **that are
  already resolved in the EE merge request that isn't merged yet**

That's a waste of time, and that's why you should merge EE merge request before
their CE counterpart.

## Avoiding CE->EE merge conflicts beforehand

To avoid the conflicts beforehand, check out the
[Guidelines for implementing Enterprise Edition features](ee_features.md).

In any case, the CI `ee_compat_check` job will tell you if you need to open an
EE version of your CE merge request.

### Conflicts detection in CE merge requests

For each commit (except on `master`), the `ee_compat_check` CI job tries to
detect if the current branch's changes will conflict during the CE->EE merge.

The job reports what files are conflicting and how to setup a merge request
against EE.

#### How the job works

1. Generates the diff between your branch and current CE `master`
1. Tries to apply it to current EE `master`
1. If it applies cleanly, the job succeeds, otherwise...
1. Detects a branch with the `ee-` prefix or `-ee` suffix in EE
1. If it exists, generate the diff between this branch and current EE `master`
1. Tries to apply it to current EE `master`
1. If it applies cleanly, the job succeeds

In the case where the job fails, it means you should create an `ee-<ce_branch>`
or `<ce_branch>-ee` branch, push it to EE and open a merge request against EE
`master`.
At this point if you retry the failing job in your CE merge request, it should
now pass.

Notes:

- This task is not a silver-bullet, its current goal is to bring awareness to
  developers that their work needs to be ported to EE.
- Community contributors shouldn't be required to submit merge requests against
  EE, but reviewers should take actions by either creating such EE merge request
  or asking a GitLab developer to do it **before the merge request is merged**.
- If you branch is too far behind `master`, the job will fail. In that case you
  should rebase your branch upon latest `master`.
- Code reviews for merge requests often consist of multiple iterations of
  feedback and fixes. There is no need to update your EE MR after each
  iteration. Instead, create an EE MR as soon as you see the
  `ee_compat_check` job failing. After you receive the final approval
  from a Maintainer (but **before the CE MR is merged**) update the EE MR.
  This helps to identify significant conflicts sooner, but also reduces the
  number of times you have to resolve conflicts.
- Please remember to
  [always have your EE merge request merged before the CE version](#always-merge-ee-merge-requests-before-their-ce-counterparts).
- You can use [`git rerere`](https://git-scm.com/blog/2010/03/08/rerere.html)
  to avoid resolving the same conflicts multiple times.

---

[Return to Development documentation](README.md)
