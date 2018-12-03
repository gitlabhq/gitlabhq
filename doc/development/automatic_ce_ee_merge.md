# Automatic CE->EE merge

Whenever a commit is pushed to the CE `master` branch, it is automatically
merged into the EE `master` branch. If the commit produces any conflicts, it is
instead reverted from CE `master`. When this happens, a merge request will be
set up automatically that can be used to reinstate the changes. This merge
request will be assigned to the author of the conflicting commit, or the merge
request author if the commit author could not be associated with a GitLab user.
If no author could be found, the merge request is assigned to a random member of
the Delivery team. It is then up to this team member to figure out who to assign
the merge request to.

Because some commits can not be reverted if new commits depend on them, we also
run a job periodically that processes a range of commits and tries to merge or
revert them. This should ensure that all commits are either merged into EE
`master`, or reverted, instead of just being left behind in CE.

## Always merge EE merge requests before their CE counterparts

**In order to avoid conflicts in the CE->EE merge, you should always merge the
EE version of your CE merge request first, if present.**

The rationale for this is that as CE->EE merges are done automatically, it can
happen that:

1. A CE merge request that needs EE-specific changes is merged.
1. The automatic CE->EE merge happens.
1. Conflicts due to the CE merge request occur since its EE merge request isn't
   merged yet.
1. The CE changes are reverted.

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

## How to reinstate changes

When a commit is reverted, the corresponding merge request to reinstate the
changes will include all the details necessary to ensure the changes make it
back into CE and EE. However, you still need to manually set up an EE merge
request that resolves the conflicts.

Each merge request used to reinstate changes will have the "reverted" label
applied. Please do not remove this label, as it will be used to determine how
many times commits are reverted and how long it takes to reinstate the changes.

An example merge request can be found in [CE merge request
23280](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/23280).

## How it works

The automatic merging is performed using a project called [Merge
Train](https://gitlab.com/gitlab-org/merge-train/). For every commit to merge or
revert, we generate patches using `git format-patch` which we then try to apply
using `git am --3way`. If this succeeds we push the changes to EE, if this fails
we decide what to do based on the failure reason:

1. If the patch could not be applied because it was already applied, we just
   skip it.
1. If the patch caused conflicts, we revert the source commits.

Commits are reverted in reverse order, ensuring that if commit B depends on A,
and both conflict, we first revert B followed by reverting A.

## FAQ

### Why?

We want to work towards being able to deploy continuously, but this requires
that `master` is always stable and has all the changes we need. If CE `master`
can not be merged into EE `master` due to merge conflicts, this prevents _any_
change from CE making its way into EE. Since GitLab.com runs on EE, this
effectively prevents us from deploying changes.

Past experiences and data have shown that periodic CE to EE merge requests do
not scale, and often take a very long time to complete. For example, [in this
comment](https://gitlab.com/gitlab-org/release/framework/issues/49#note_114614619)
we determined that the average time to close an upstream merge request is around
5 hours, with peaks up to several days. Periodic merge requests are also
frustrating to work with, because they often include many changes unrelated to
your own changes.

Automatically merging or reverting commits allows us to keep merging changes
from CE into EE, as we never have to wait hours for somebody to resolve a set of
merge conflicts.

### Does the CE to EE merge take into account merge commits?

No. When merging CE changes into EE, merge commits are ignored.

### My changes are reverted, but I set up an EE MR to resolve conflicts

Most likely the automatic merge job ran before the EE merge request was merged.
If this keeps happening, consider reporting a bug in the [Merge Train issue
tracker](https://gitlab.com/gitlab-org/merge-train/issues).

### My changes keep getting reverted, and this is really annoying!

This is understandable, but the solution to this is fairly straightforward:
simply set up an EE merge request for every CE merge request, and resolve your
conflicts before the changes are reverted.

### Will we allow certain people to still merge changes, even if they conflict?

No.

### Some files I work with often conflict, how can I best deal with this?

If you find you keep running into merge conflicts, consider refactoring the file
so that the EE specific changes are not intertwined with CE code. For Ruby code
you can do this by moving the EE code to a separate module, which can then be
injected into the appropriate classes or modules. See [Guidelines for
implementing Enterprise Edition features](ee_features.md) for more information.

### Will changelog entries be reverted automatically?

Only if the changelog was added in the commit that was reverted. If a changelog
entry was added in a separate commit, it is possible for it to be left behind.
Since changelog entries are related to the changes in question, there is no real
reason to commit the changelog separately, and as such this should not be a big
problem.
