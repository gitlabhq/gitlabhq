# Automatic CE->EE merge

GitLab Community Edition is merged automatically every 3 hours into the
Enterprise Edition (look for the [`CE Upstream` merge requests]).

This merge is done automatically in a
[scheduled pipeline](https://gitlab.com/gitlab-org/release-tools/-/jobs/43201679).

## What to do if you are pinged in a `CE Upstream` merge request to resolve a conflict?

1. Please resolve the conflict as soon as possible or ask someone else to do it
  - It's ok to resolve more conflicts than the one that you are asked to resolve.
    In that case, it's a good habit to ask for a double-check on your resolution
    by someone who is familiar with the code you touched.
1. Once you have resolved your conflicts, push to the branch (no force-push)
1. Assign the merge request to the next person that has to resolve a conflict
1. If all conflicts are resolved after your resolution is pushed, keep the merge
  request assigned to you: **you are now responsible for the merge request to be
  green**
1. If you need any help, you can ping the current [release managers], or ask in
  the `#ce-to-ee` Slack channel

A few notes about the automatic CE->EE merge job:

- If a merge is already in progress, the job
  [doesn't create a new one](https://gitlab.com/gitlab-org/release-tools/-/jobs/43157687).
- If there is nothing to merge (i.e. EE is up-to-date with CE), the job doesn't
  create a new one
- The job posts messages to the `#ce-to-ee` Slack channel to inform what's the
  current CE->EE merge status (e.g. "A new MR has been created", "A MR is still pending")

[`CE Upstream` merge requests]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests?label_name%5B%5D=CE+upstream
[release managers]: https://about.gitlab.com/release-managers/

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

### Cherry-picking from CE to EE

For avoiding merge conflicts, we use a method of creating equivalent branches
for CE and EE. If the `ee-compat-check` job fails, this process is required.

This method only requires that you have cloned both CE and EE into your computer.
If you don't have them yet, please go ahead and clone them:

- Clone CE repo: `git clone git@gitlab.com:gitlab-org/gitlab-ce.git`
- Clone EE repo: `git clone git@gitlab.com:gitlab-org/gitlab-ee.git`

And the only additional setup we need is to add CE as remote of EE and vice-versa:

- Open two terminal windows, one in CE, and another one in EE:
  - In EE: `git remote add ce git@gitlab.com:gitlab-org/gitlab-ce.git`
  - In CE: `git remote add ee git@gitlab.com:gitlab-org/gitlab-ee.git`

That's all setup we need, so that we can cherry-pick a commit from CE to EE, and
from EE to CE.

Now, every time you create an MR for CE and EE:

1. Open two terminal windows, one in CE, and another one in EE
1. In the CE terminal:
  1. Create the CE branch, e.g., `branch-example`
  1. Make your changes and push a commit (commit A)
  1. Create the CE merge request in GitLab
1. In the EE terminal:
  1. Create the EE-equivalent branch ending with `-ee`, e.g.,
  `git checkout -b branch-example-ee`
  1. Fetch the CE branch: `git fetch ce branch-example`
  1. Cherry-pick the commit A: `git cherry-pick commit-A-SHA`
  1. If Git prompts you to fix the conflicts, do a `git status`
  to check which files contain conflicts, fix them, save the files
  1. Add the changes with `git add .` but **DO NOT commit** them
  1. Continue cherry-picking: `git cherry-pick --continue`
  1. Push to EE: `git push origin branch-example-ee`
1. Create the EE-equivalent MR and link to the CE MR from the
description "Ports [CE-MR-LINK] to EE"
1. Once all the jobs are passing in both CE and EE, you've addressed the
feedback from your own team, and got them approved, the merge requests can be merged.
1. When both MRs are ready, the EE merge request will be merged first, and the
CE-equivalent will be merged next.

**Important notes:**

- The commit SHA can be easily found from the GitLab UI. From a merge request,
open the tab **Commits** and click the copy icon to copy the commit SHA.
- To cherry-pick a **commit range**, such as [A > B > C > D] use:

    ```shell
    git cherry-pick "oldest-commit-SHA^..newest-commit-SHA"
    ```

    For example, suppose the commit A is the oldest, and its SHA is `4f5e4018c09ed797fdf446b3752f82e46f5af502`,
    and the commit D is the newest, and its SHA is `80e1c9e56783bd57bd7129828ec20b252ebc0538`.
    The cherry-pick command will be:

    ```shell
    git cherry-pick "4f5e4018c09ed797fdf446b3752f82e46f5af502^..80e1c9e56783bd57bd7129828ec20b252ebc0538"
    ```

- To cherry-pick a **merge commit**, use the flag `-m 1`. For example, suppose that the
merge commit SHA is `138f5e2f20289bb376caffa0303adb0cac859ce1`:

    ```shell
    git cherry-pick -m 1 138f5e2f20289bb376caffa0303adb0cac859ce1
    ```
- To cherry-pick multiple commits, such as B and D in a range [A > B > C > D], use:

    ```shell
    git cherry-pick commmit-B-SHA commit-D-SHA
    ```

    For example, suppose commit B SHA = `4f5e4018c09ed797fdf446b3752f82e46f5af502`,
    and the commit D SHA = `80e1c9e56783bd57bd7129828ec20b252ebc0538`.
    The cherry-pick command will be:

    ```shell
    git cherry-pick 4f5e4018c09ed797fdf446b3752f82e46f5af502 80e1c9e56783bd57bd7129828ec20b252ebc0538
    ```

    This case is particularly useful when you have a merge commit in a sequence of
    commits and you want to cherry-pick all but the merge commit.

- If you push more commits to the CE branch, you can safely repeat the procedure
to cherry-pick them to the EE-equivalent branch. You can do that as many times as
necessary, using the same CE and EE branches.
- If you submitted the merge request to the CE repo and the `ee-compat-check` job passed,
you are not required to submit the EE-equivalent MR, but it's still recommended. If the
job failed, you are required to submit the EE MR so that you can fix the conflicts in EE
before merging your changes into CE.

---

[Return to Development documentation](README.md)
