# Migrating from TFS

[TFS](https://www.visualstudio.com/tfs/) is a set of tools developed by Microsoft
which also includes a centralized version control system (TFVC) similar to Git.

In this document, we emphasize on the TFVC to Git migration.

## TFVC vs Git

The following list illustrates the main differences between TFVC and Git:

- **Git is distributed** whereas TFVC is centralized using a client-server
  architecture. This translates to Git having a more flexible workflow since
  your working area is a copy of the entire repository. This decreases the
  overhead when switching branches or merging for example, since you don't have
  to communicate with a remote server.
- **Storage method.** Changes in CVS are per file (changeset), while in Git
  a committed file(s) is stored in its entirety (snapshot). That means that's
  very easy in Git to revert or undo a whole change.

_Check also Microsoft's documentation on the
[comparison of Git and TFVC](https://www.visualstudio.com/en-us/docs/tfvc/comparison-git-tfvc)
and the Wikipedia article on
[comparing the different version control software](https://en.wikipedia.org/wiki/Comparison_of_version_control_software)._

## Why migrate

Migrating to Git/GitLab there is:

- **No licensing costs**, Git is GPL while TFVC is proprietary.
- **Shorter learning curve**, Git has a big community and a vast number of
  tutorials to get you started (see our [Git topic](../../../topics/git/index.md)).
- **Integration with modern tools**, migrating to Git and GitLab you can have
  an open source end-to-end software development platform with built-in version
  control, issue tracking, code review, CI/CD, and more.

## How to migrate

The best option to migrate from TFVC to Git is to use the
[`git-tfs`](https://github.com/git-tfs/git-tfs) tool. A specific guide for the
migration exists:
[Migrate TFS to Git](https://github.com/git-tfs/git-tfs/blob/master/doc/usecases/migrate_tfs_to_git.md).
