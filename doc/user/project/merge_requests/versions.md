# Merge requests versions

> **Notes:**
> - [Introduced][ce-5467] in GitLab 8.12.
> - Comments are disabled while viewing outdated merge versions or comparing to
>   versions other than base.
> - Merge request versions are based on push not on commit. So, if you pushed 5
>   commits in a single push, it will be a single option in the dropdown. If you
>   pushed 5 times, that will count for 5 options.

Every time you push to a branch that is tied to a merge request, a new version
of merge request diff is created. When you visit a merge request that contains
more than one pushes, you can select and compare the versions of those merge
request diffs.

![Merge request versions](img/versions.png)

---

By default, the latest version of changes is shown. However, you
can select an older one from version dropdown.

![Merge request versions dropdown](img/versions_dropdown.png)

---

You can also compare the merge request version with an older one to see what has
changed since then.

![Merge request versions compare](img/versions_compare.png)

---

Every time you push new changes to the branch, a link to compare the last
changes appears as a system note.

![Merge request versions system note](img/versions_system_note.png)

[ce-5467]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5467
