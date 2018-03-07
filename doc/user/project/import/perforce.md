# Migrating from Perforce Helix

[Perforce Helix](https://www.perforce.com/) provides a set of tools which also
include a centralized, proprietary version control system similar to Git.

## Perforce vs Git

The following list illustrates the main differences between Perforce Helix and
Git:

1. In general the biggest difference is that Perforce branching is heavyweight
   compared to Git's lightweight branching. When you create a branch in Perforce,
   it creates an integration record in their proprietary database for every file
   in the branch, regardless how many were actually changed. Whereas Git was
   implemented with a different architecture so that a single SHA acts as a pointer
   to the state of the whole repo after the changes, making it very easy to branch.
   This is what made feature branching workflows so easy to adopt with Git.
1. Also, context switching between branches is much easier in Git. If your manager
   said 'You need to stop work on that new feature and fix this security
   vulnerability' you can do so very easily in Git.
1. Having a complete copy of the project and its history on your local machine
   means every transaction is superfast and Git provides that. You can branch/merge
   and experiment in isolation, then clean up your mess before sharing your new
   cool stuff with everyone.
1. Git also made code review simple because you could share your changes without
   merging them to master, whereas Perforce had to implement a Shelving feature on
   the server so others could review changes before merging.

## Why migrate

Perforce Helix can be difficult to manage both from a user and an admin
perspective. Migrating to Git/GitLab there is:

- **No licensing costs**, Git is GPL while Perforce Helix is proprietary.
- **Shorter learning curve**, Git has a big community and a vast number of
  tutorials to get you started.
- **Integration with modern tools**, migrating to Git and GitLab you can have
  an open source end-to-end software development platform with built-in version
  control, issue tracking, code review, CI/CD, and more.

## How to migrate

Git includes a built-in mechanism (`git p4`) to pull code from Perforce and to
submit back from Git to Perforce.

Here's a few links to get you started:

- [git-p4 manual page](https://www.kernel.org/pub/software/scm/git/docs/git-p4.html)
- [git-p4 example usage](https://git.wiki.kernel.org/index.php/Git-p4_Usage)
- [Git book migration guide](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git#_perforce_import)

Note that `git p4` and `git filter-branch` are not very good at
creating small and efficient Git pack files. So it might be a good
idea to spend time and CPU to properly repack your repository before
sending it for the first time to your GitLab server. See
[this StackOverflow question](https://stackoverflow.com/questions/28720151/git-gc-aggressive-vs-git-repack/).
