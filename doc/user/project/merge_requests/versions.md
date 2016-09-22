# Merge requests versions

> Will be [introduced][ce-5467] in GitLab 8.12.

Every time you push to a branch that is tied to a merge request, a new version
of merge request diff is created. When you visit a merge request that contains
more than one pushes, you can select and compare the versions of those merge
request diffs.

![Merge Request Versions](img/versions.png)

By default, the latest version of changes is shown. However, you
can select an older one from version dropdown.

![Merge Request Versions](img/versions-dropdown.png)

You can also compare the merge request version with older one to see what is
changed since then.

![Merge Request Versions](img/versions-compare.png)

Please note that comments are disabled while viewing outdated merge versions
or comparing to versions other than base.

---

>**Note:**
Merge request versions are based on push not on commit. So, if you pushed 5
commits in a single push, it will be a single option in the dropdown. If you
pushed 5 times, that will count for 5 options.

[ce-5467]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5467
