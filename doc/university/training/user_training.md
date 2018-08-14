---
comments: false
---

# GitLab Git Workshop

---

# Agenda

1. Brief history of Git
1. GitLab walkthrough
1. Configure your environment
1. Workshop

---

# Git introduction

https://git-scm.com/about

- Distributed version control
  - Does not rely on connection to a central server
  - Many copies of the complete history
- Powerful branching and merging
- Adapts to nearly any workflow
- Fast, reliable and stable file format

---

# Help!

Use the tools at your disposal when you get stuck.

- Use '`git help <command>`' command
- Use Google
- Read documentation at https://git-scm.com

---

# GitLab Walkthrough

![fit](logo.png)

---

# Configure your environment

- Windows: Install 'Git for Windows'

> https://git-for-windows.github.io

- Mac: Type '`git`' in the Terminal application.

> If it's not installed, it will prompt you to install it.

- Debian: '`sudo apt-get install git-all`'
or Red Hat '`sudo yum install git-all`'

---

# Git Workshop

## Overview

1. Configure Git
1. Configure SSH Key
1. Create a project
1. Committing
1. Feature branching
1. Merge requests
1. Feedback and Collaboration

---

# Configure Git

One-time configuration of the Git client

```bash
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

---

# Configure SSH Key

```bash
ssh-keygen -t rsa -b 4096 -C "you@computer-name"
```

```bash
# You will be prompted for the following information. Press enter to accept the defaults. Defaults appear in parentheses.
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/you/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/you/.ssh/id_rsa.
Your public key has been saved in /Users/you/.ssh/id_rsa.pub.
The key fingerprint is:
39:fc:ce:94:f4:09:13:95:64:9a:65:c1:de:05:4d:01 you@computer-name
```

Copy your public key and add it to your GitLab profile

```bash
cat ~/.ssh/id_rsa.pub
```

```bash
ssh-rsa AAAAB3NzaC1yc2EAAAADAQEL17Ufacg8cDhlQMS5NhV8z3GHZdhCrZbl4gz you@example.com
```

---

# Create a project

- Create a project in your user namespace
  - Choose to import from 'Any Repo by URL' and use
    https://gitlab.com/gitlab-org/training-examples.git
- Create a '`development`' or '`workspace`' directory in your home directory.
- Clone the '`training-examples`' project

---

# Commands

```
mkdir ~/development
cd ~/development

-or-

mkdir ~/workspace
cd ~/workspace

git clone git@gitlab.example.com:<username>/training-examples.git
cd training-examples
```

---

# Git concepts

**Untracked files**

New files that Git has not been told to track previously.

**Working area**

Files that have been modified but are not committed.

**Staging area**

Modified files that have been marked to go in the next commit.

---

# Committing

1. Edit '`edit_this_file.rb`' in '`training-examples`'
1. See it listed as a changed file (working area)
1. View the differences
1. Stage the file
1. Commit
1. Push the commit to the remote
1. View the git log

---

# Commands

```
# Edit `edit_this_file.rb`
git status
git diff
git add <file>
git commit -m 'My change'
git push origin master
git log
```

---

# Feature branching

- Efficient parallel workflow for teams
- Develop each feature in a branch
- Keeps changes isolated
- Consider a 1-to-1 link to issues
- Push branches to the server frequently
  - Hint: This is a cheap backup for your work-in-progress code

---

# Feature branching

1. Create a new feature branch called 'squash_some_bugs'
1. Edit '`bugs.rb`' and remove all the bugs.
1. Commit
1. Push

---

# Commands

```
git checkout -b squash_some_bugs
# Edit `bugs.rb`
git status
git add bugs.rb
git commit -m 'Fix some buggy code'
git push origin squash_some_bugs
```

---

# Merge requests

- When you want feedback create a merge request
- Target is the ‘default’ branch (usually master)
- Assign or mention the person you would like to review
- Add 'WIP' to the title if it's a work in progress
- When accepting, always delete the branch
- Anyone can comment, not just the assignee
- Push corrections to the same branch

---

# Merge requests

**Create your first merge request**

1. Use the blue button in the activity feed
1. View the diff (changes) and leave a comment
1. Push a new commit to the same branch
1. Review the changes again and notice the update

---

# Feedback and Collaboration

- Merge requests are a time for feedback and collaboration
- Giving feedback is hard
- Be as kind as possible
- Receiving feedback is hard
- Be as receptive as possible
- Feedback is about the best code, not the person. You are not your code

---

# Feedback and Collaboration

Review the Thoughtbot code-review guide for suggestions to follow when reviewing merge requests:
[https://github.com/thoughtbot/guides/tree/master/code-review](https://github.com/thoughtbot/guides/tree/master/code-review)

See GitLab merge requests for examples:
[https://gitlab.com/gitlab-org/gitlab-ce/merge_requests](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests)

---

# Explore GitLab projects

![fit](logo.png)

- Dashboard
- User Preferences
- ReadMe, Changelog, License shortcuts
- Issues
- Milestones and Labels
- Manage project members
- Project settings

---

# Tags

- Useful for marking deployments and releases
- Annotated tags are an unchangeable part of Git history
- Soft/lightweight tags can be set and removed at will
- Many projects combine an annotated release tag with a stable branch
- Consider setting deployment/release tags automatically

---

# Tags

- Create a lightweight tag
- Create an annotated tag
- Push the tags to the remote repository

**Additional resources**

[http://git-scm.com/book/en/Git-Basics-Tagging](http://git-scm.com/book/en/Git-Basics-Tagging)

---

# Commands

```
git checkout master

# Lightweight tag
git tag my_lightweight_tag

# Annotated tag
git tag -a v1.0 -m ‘Version 1.0’
git tag

git push origin --tags
```

---

# Merge conflicts

- Happen often
- Learning to fix conflicts is hard
- Practice makes perfect
- Force push after fixing conflicts. Be careful!

---

# Merge conflicts

1. Checkout a new branch and edit `conflicts.rb`. Add 'Line4' and 'Line5'.
1. Commit and push
1. Checkout master and edit `conflicts.rb`. Add 'Line6' and 'Line7' below 'Line3'.
1. Commit and push to master
1. Create a merge request

---

# Merge conflicts

After creating a merge request you should notice that conflicts exist. Resolve
the conflicts locally by rebasing.

```
git rebase master

# Fix conflicts by editing the files.

git add conflicts.rb
git commit -m 'Fix conflicts'
git rebase --continue
git push origin <branch> -f
```

---

# Rebase with squash

You may end up with a commit log that looks like this:

```
Fix issue #13
Test
Fix
Fix again
Test
Test again
Does this work?
```

Squash these in to meaningful commits using an interactive rebase.

---

# Rebase with squash

Squash the commits on the same branch we used for the merge conflicts step.

```
git rebase -i master
```

In the editor, leave the first commit as 'pick' and set others to 'fixup'.

---

# Questions?

![fit](logo.png)

Thank you for your hard work!

**Additional Resources**

GitLab Documentation [http://docs.gitlab.com](http://docs.gitlab.com/)
GUI Clients [http://git-scm.com/downloads/guis](http://git-scm.com/downloads/guis)
Pro git book [http://git-scm.com/book](http://git-scm.com/book)
Platzi Course [https://courses.platzi.com/courses/git-gitlab/](https://courses.platzi.com/courses/git-gitlab/)
Code School tutorial [http://try.github.io/](http://try.github.io/)
Contact Us at `subscribers@gitlab.com`
