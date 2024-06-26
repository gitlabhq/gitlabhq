---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to view a file's Git history in GitLab."
---

# Git file history

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Git file History provides information about the commit history associated
with a file. To use it:

1. Go to your project's **Code > Repository**.
1. In the upper-right corner, select **History**.

When you select **History**, this information is displayed:

![Git log output](img/file_history_output_v12_6.png "History button output")

If you hover over a commit in the UI, the precise date and time of the commit modification
are shown.

The name and email information provided are retrieved from the
[Git configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
of the contributor when a commit is made.

## Limit history range

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423108) in GitLab 16.9.

In these cases you can constrain the search period by adding `committed_before` and `committed_after` dates as parameters.
To do this, add `&` and `committed_before=YYYY-MM-DD` or `committed_after=YYYY-MM-DD` parameters to the URL.

For example:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/commits/master/README.md?ref_type=heads&committed_before=2010-11-22&committed_after=2008-05-15
```

Doing this might be necessary to fix [commit history requests timeouts](https://gitlab.com/gitlab-org/gitaly/-/issues/5426)
in very large repositories.

## Associated `git` command

If you're running `git` from the command line, the equivalent command
is `git log <filename>`. For example, if you want to find `history`
information about a `README.md` file in the local directory, run the
following command:

```shell
git log README.md
```

Git displays output similar to the following, which includes the commit
time in UTC format:

```shell
commit 0e62ed6d9f39fa9bedf7efc6edd628b137fa781a
Author: Mike Jang <mjang@gitlab.com>
Date:   Tue Nov 26 21:44:53 2019 +0000

    Deemphasize GDK as a doc build tool

commit 418879420b1e3a4662067bd07b64bb6988654697
Author: Marcin Sedlak-Jakubowski <msedlakjakubowski@gitlab.com>
Date:   Mon Nov 4 19:58:27 2019 +0100

    Fix typo

commit 21cc1fef11349417ed515557748369cfb235fc81
Author: Jacques Erasmus <jerasmus@gitlab.com>
Date:   Mon Oct 14 22:13:40 2019 +0000

    Add support for modern JS

    Added rollup to the project

commit 2f5e895aebfa5678e51db303b97de56c51e3cebe
Author: Achilleas Pipinellis <axil@gitlab.com>
Date:   Fri Sep 13 14:03:01 2019 +0000

    Remove gitlab-foss Git URLs as we don't need them anymore

    [ci skip]
```
