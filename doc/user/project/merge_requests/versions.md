---
type: reference, concepts
---

# Merge requests versions

Every time you push to a branch that is tied to a merge request, a new version
of merge request diff is created. When you visit a merge request that contains
more than one pushes, you can select and compare the versions of those merge
request diffs.

![Merge request versions](img/versions.png)

## Selecting a version

By default, the latest version of changes is shown. However, you
can select an older one from version dropdown.

![Merge request versions dropdown](img/versions_dropdown.png)

Merge request versions are based on push not on commit. So, if you pushed 5
commits in a single push, it will be a single option in the dropdown. If you
pushed 5 times, that will count for 5 options.

You can also compare the merge request version with an older one to see what has
changed since then.

![Merge request versions compare](img/versions_compare.png)

Comments are disabled while viewing outdated merge versions or comparing to
versions other than base.

Every time you push new changes to the branch, a link to compare the last
changes appears as a system note.

![Merge request versions system note](img/versions_system_note.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
