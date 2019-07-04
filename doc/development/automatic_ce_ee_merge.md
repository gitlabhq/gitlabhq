# Automatic CE->EE merge

Commits pushed to CE `master` are automatically merged into EE `master` roughly
every 5 minutes. Changes are merged using the `recursive=ours` merge strategy in
the context of EE. This means that any merge conflicts are resolved by taking
the EE changes and discarding the CE changes. This removes the need for
resolving conflicts or reverting changes, at the cost of **absolutely
requiring** EE merge requests to be created whenever a CE merge request causes
merge conflicts.  Failing to do so can result in changes not making their way
into EE.

## Always create an EE merge request if there are conflicts

In CI there is a job called `ee_compat_check`, which checks if a CE MR causes
merge conflicts with EE. If this job reports conflicts, you **must** create an
EE merge request. If you are an external contributor you can ask the reviewer to
do this for you.

## Always merge EE merge requests before their CE counterparts

**In order to avoid conflicts in the CE->EE merge, you should always merge the
EE version of your CE merge request first, if present.**

Failing to do so will lead to CE changes being discarded when merging into EE,
if they cause merge conflicts.

## Avoiding CE->EE merge conflicts beforehand

To avoid the conflicts beforehand, check out the
[Guidelines for implementing Enterprise Edition features](ee_features.md).

In any case, the CI `ee_compat_check` job will tell you if you need to open an
EE version of your CE merge request.

### Conflicts detection in CE merge requests

For each commit (except on `master`), the `ee_compat_check` CI job tries to
detect if the current branch's changes will conflict during the CE->EE merge.

The job reports what files are conflicting and how to set up a merge request
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
- You can use [`git rerere`](https://git-scm.com/docs/git-rerere)
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
   description `Ports [CE-MR-LINK] to EE`
1. Once all the jobs are passing in both CE and EE, you've addressed the
   feedback from your own team, and got them approved, the merge requests can be merged.
1. When both MRs are ready, the EE merge request will be merged first, and the
   CE-equivalent will be merged next.

**Important notes:**

- The commit SHA can be easily found from the GitLab UI. From a merge request,
  open the tab **Commits** and click the copy icon to copy the commit SHA.
- To cherry-pick a **commit range**, such as (A > B > C > D) use:

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

- To cherry-pick multiple commits, such as B and D in a range (A > B > C > D), use:

  ```shell
  git cherry-pick commit-B-SHA commit-D-SHA
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

## FAQ

### How does automatic merging work?

The automatic merging is performed using a project called [Merge
Train](https://gitlab.com/gitlab-org/merge-train/). This project will clone CE
and EE master, and merge CE master into EE master using `git merge
--strategy=recursive --strategy-option=ours`. This process runs multiple times
per hour.

For more information on the exact implementation you can refer to the source
code.

### Why merge automatically?

As we work towards continuous deployments and a single repository for both CE
and EE, we need to first make sure that all CE changes make their way into CE as
fast as possible. Past experiences and data have shown that periodic CE to EE
merge requests do not scale, and often take a very long time to complete. For
example, [in this
comment](https://gitlab.com/gitlab-org/release/framework/issues/49#note_114614619)
we determined that the average time to close an upstream merge request is around
5 hours, with peaks up to several days. Periodic merge requests are also
frustrating to work with, because they often include many changes unrelated to
your own changes.

To resolve these problems, we now merge changes using the `ours` strategy to
automatically resolve merge conflicts. This removes the need for resolving
conflicts in a periodic merge request, and allows us to merge changes from CE
into EE much faster.

### My CE merge request caused conflicts after it was merged. What do I do?

If you notice this, you should set up an EE merge request that resolves these
conflicts as **soon as possible**. Failing to do so can lead to your changes not
being available in EE, which may break tests. This in turn would prevent us from
being able to deploy.

### Won't this setup be risky?

No, not if there is an EE merge request for every CE merge request that causes
conflicts _and_ that EE merge request is merged first. In the past we may have
been a bit more relaxed when it comes to enforcing EE merge requests, but to
enable automatic merging we have to start requiring such merge requests even for
the smallest conflicts.

### Some files I work with often conflict, how can I best deal with this?

If you find you keep running into merge conflicts, consider refactoring the file
so that the EE specific changes are not intertwined with CE code. For Ruby code
you can do this by moving the EE code to a separate module, which can then be
injected into the appropriate classes or modules. See [Guidelines for
implementing Enterprise Edition features](ee_features.md) for more information.

---

[Return to Development documentation](README.md)
