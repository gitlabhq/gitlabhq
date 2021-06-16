---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrating from CVS **(FREE)**

[CVS](https://savannah.nongnu.org/projects/cvs) is an old centralized version
control system similar to [SVN](svn.md).

## CVS vs Git

The following list illustrates the main differences between CVS and Git:

- **Git is distributed.** On the other hand, CVS is centralized using a client-server
  architecture. This translates to Git having a more flexible workflow since
  your working area is a copy of the entire repository. This decreases the
  overhead when switching branches or merging for example, since you don't have
  to communicate with a remote server.
- **Atomic operations.** In Git all operations are
  [atomic](https://en.wikipedia.org/wiki/Atomic_commit), either they succeed as
  whole, or they fail without any changes. In CVS, commits (and other operations)
  are not atomic. If an operation on the repository is interrupted in the middle,
  the repository can be left in an inconsistent state.
- **Storage method.** Changes in CVS are per file (changeset), while in Git
  a committed file(s) is stored in its entirety (snapshot). That means it's
  very easy in Git to revert or undo a whole change.
- **Revision IDs.** The fact that in CVS changes are per files, the revision ID
  is depicted by version numbers, for example `1.4` reflects how many times a
  given file has been changed. In Git, each version of a project as a whole
  (each commit) has its unique name given by SHA-1.
- **Merge tracking.** Git uses a commit-before-merge approach rather than
  merge-before-commit (or update-then-commit) like CVS. If while you were
  preparing to create a new commit (new revision) somebody created a
  new commit on the same branch and pushed to the central repository, CVS would
  force you to first update your working directory and resolve conflicts before
  allowing you to commit. This is not the case with Git. You first commit, save
  your state in version control, then you merge the other developer's changes.
  You can also ask the other developer to do the merge and resolve any conflicts
  themselves.
- **Signed commits.** Git supports signing your commits with GPG for additional
  security and verification that the commit indeed came from its original author.
  GitLab can [integrate with GPG](../repository/gpg_signed_commits/index.md)
  and show whether a signed commit is correctly verified.

_Some of the items above were taken from this great
[Stack Overflow post](https://stackoverflow.com/a/824241/974710). For a more
complete list of differences, consult the
Wikipedia article on [comparing the different version control software](https://en.wikipedia.org/wiki/Comparison_of_version_control_software)._

## Why migrate

CVS is old with no new release since 2008. Git provides more tools to work
with (`git bisect` for one) which makes for a more productive workflow.
Migrating to Git/GitLab will benefit you:

- **Shorter learning curve**, Git has a big community and a vast number of
  tutorials to get you started (see our [Git topic](../../../topics/git/index.md)).
- **Integration with modern tools**, migrating to Git and GitLab you can have
  an open source end-to-end software development platform with built-in version
  control, issue tracking, code review, CI/CD, and more.
- **Support for many network protocols**. Git supports SSH, HTTP/HTTPS and rsync
  among others, whereas CVS supports only SSH and its own insecure `pserver`
  protocol with no user authentication.

## How to migrate

Here's a few links to get you started with the migration:

- [Migrate using the `cvs-fast-export` tool](https://gitlab.com/esr/cvs-fast-export)
- [Stack Overflow post on importing the CVS repository](https://stackoverflow.com/a/11490134/974710)
- [Convert a CVS repository to Git](https://www.techrepublic.com/blog/linux-and-open-source/convert-cvs-repositories-to-git/)
- [Man page of the `git-cvsimport` tool](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-cvsimport.html)
- [Migrate using `reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html#conversion)
