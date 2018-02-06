---
comments: false
---


# Training

This training material is the markdown used to generate training slides
which can be found at [End User Slides](https://gitlab-org.gitlab.io/end-user-training-slides/#/)
through it's [RevealJS](https://gitlab.com/gitlab-org/end-user-training-slides)
project.

---

## Git Intro

---

### What is a Version Control System (VCS)

- Records changes to a file
- Maintains history of changes
- Disaster Recovery
- Types of VCS: Local, Centralized and Distributed

---

### Short Story of Git

- 1991-2002: The Linux kernel was being maintaned by sharing archived files
  and patches.
- 2002: The Linux kernel project began using a DVCS called BitKeeper
- 2005: BitKeeper revoked the free-of-charge status and Git was created

---

### What is Git

- Distributed Version Control System
- Great branching model that adapts well to most workflows
- Fast and reliable
- Keeps a complete history
- Disaster recovery friendly
- Open Source

---

### Getting Help

- Use the tools at your disposal when you get stuck.
  - Use `git help <command>` command
  - Use Google (i.e. StackOverflow, Google groups)
  - Read documentation at https://git-scm.com

---

## Git Setup
Workshop Time!

---

### Setup

- Windows: Install 'Git for Windows'
  - https://git-for-windows.github.io
- Mac: Type `git` in the Terminal application.
  - If it's not installed, it will prompt you to install it.
- Linux
  - Debian: `sudo apt-get install git-all`
  - Red Hat `sudo yum install git-all`

---

### Configure

- One-time configuration of the Git client:

```bash
git config --global user.name "Your Name"
git config --global user.email you@example.com
```    

- If you don't use the global flag you can setup a different author for
  each project
- Check settings with:

```bash
git config --global --list
```
- You might want or be required to use an SSH key.
    - Instructions: [SSH](http://doc.gitlab.com/ce/ssh/README.html)

---

### Workspace

- Choose a directory on you machine easy to access
- Create a workspace or development directory
- This is where we'll be working and adding content

---

```bash
mkdir ~/development
cd ~/development

-or-

mkdir ~/workspace
cd ~/workspace  
```

---

## Git Basics

---  

### Git Workflow

- Untracked files
    - New files that Git has not been told to track previously.
- Working area (Workspace)
    - Files that have been modified but are not committed.
- Staging area (Index)
    - Modified files that have been marked to go in the next commit.
- Upstream
    - Hosted repository on a shared server

---

### GitLab

- GitLab is an application to code, test and deploy.
- Provides repository management with access controls, code reviews,
  issue tracking, Merge Requests, and other features.
- The hosted version of GitLab is gitlab.com

---  

### New Project

- Sign in into your gitlab.com account
- Create a project
- Choose to import from 'Any Repo by URL' and use https://gitlab.com/gitlab-org/training-examples.git
- On your machine clone the `training-examples` project

---

### Git and GitLab basics

1. Edit `edit_this_file.rb` in `training-examples`
2. See it listed as a changed file (working area)
3. View the differences
4. Stage the file
5. Commit
6. Push the commit to the remote
7. View the git log

---

```shell
# Edit `edit_this_file.rb`
git status
git diff
git add <file>
git commit -m 'My change'
git push origin master
git log
```

---  

### Feature Branching

1. Create a new feature branch called `squash_some_bugs`
2. Edit `bugs.rb` and remove all the bugs.
3. Commit
4. Push

---

```shell
git checkout -b squash_some_bugs
# Edit `bugs.rb`
git status
git add bugs.rb
git commit -m 'Fix some buggy code'
git push origin squash_some_bugs
```

---

## Merge Request

---

### Merge requests

- When you want feedback create a merge request
- Target is the ‘default’ branch (usually master)
- Assign or mention the person you would like to review
- Add `WIP` to the title if it's a work in progress
- When accepting, always delete the branch
- Anyone can comment, not just the assignee
- Push corrections to the same branch


---

### Merge request example

- Create your first merge request
  - Use the blue button in the activity feed
  - View the diff (changes) and leave a comment
  - Push a new commit to the same branch
  - Review the changes again and notice the update

---

### Feedback and Collaboration

- Merge requests are a time for feedback and collaboration
- Giving feedback is hard
- Be as kind as possible
- Receiving feedback is hard
- Be as receptive as possible
- Feedback is about the best code, not the person. You are not your code
- Feedback and Collaboration

---

### Feedback and Collaboration

- Review the Thoughtbot code-review guide for suggestions to follow when reviewing merge requests:[Thoughtbot](https://github.com/thoughtbot/guides/tree/master/code-review)
- See GitLab merge requests for examples: [Merge Requests](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests)

---

## Merge Conflicts

---

### Merge Conflicts
* Happen often
* Learning to fix conflicts is hard
* Practice makes perfect
* Force push after fixing conflicts. Be careful!

---

### Example Plan
1. Checkout a new branch and edit conflicts.rb. Add 'Line4' and 'Line5'.
2. Commit and push
3. Checkout master and edit conflicts.rb. Add 'Line6' and 'Line7' below 'Line3'.
4. Commit and push to master
5. Create a merge request and watch it fail
6. Rebase our new branch with master
7. Fix conflicts on the conflicts.rb file.
8. Stage the file and continue rebasing
9. Force push the changes
10. Finally continue with the Merge Request

---

### Example 1/2

    git checkout -b conflicts_branch

    # vi conflicts.rb
    # Add 'Line4' and 'Line5'

    git commit -am "add line4 and line5"
    git push origin conflicts_branch

    git checkout master

    # vi conflicts.rb
    # Add 'Line6' and 'Line7'
    git commit -am "add line6 and line7"
    git push origin master

---

### Example 2/2

Create a merge request on the GitLab web UI. You'll see a conflict warning.

    git checkout conflicts_branch
    git fetch
    git rebase master

    # Fix conflicts by editing the files.

    git add conflicts.rb
    # No need to commit this file

    git rebase --continue

    # Remember that we have rewritten our commit history so we
    # need to force push so that our remote branch is restructured
    git push origin conflicts_branch -f

---

### Notes

* When to use `git merge` and when to use `git rebase`
* Rebase when updating your branch with master
* Merge when bringing changes from feature to master
* Reference: https://www.atlassian.com/git/tutorials/merging-vs-rebasing/

---

## Revert and Unstage

---

### Unstage

To remove files from stage use reset HEAD. Where HEAD is the last commit of the current branch:

    git reset HEAD <file>

This will unstage the file but maintain the modifications. To revert the file back to the state it was in before the changes we can use:

    git checkout -- <file>

To remove a file from disk and repo use 'git rm' and to rm a dir use the '-r' flag:

    git rm '*.txt'
    git rm -r <dirname>

If we want to remove a file from the repository but keep it on disk, say we forgot to add it to our .gitignore file then use `--cache`:

    git rm <filename> --cache

---

### Undo Commits

Undo last commit putting everything back into the staging area:

    git reset --soft HEAD^

Add files and change message with:

    git commit --amend -m "New Message"

Undo last and remove changes

    git reset --hard HEAD^

Same as last one but for two commits back:

    git reset --hard HEAD^^

Don't reset after pushing

---

### Reset Workflow

1. Edit file again 'edit_this_file.rb'
2. Check status
3. Add and commit with wrong message
4. Check log
5. Amend commit
6. Check log
7. Soft reset
8. Check log
9. Pull for updates
10. Push changes

----

    # Change file edit_this_file.rb
    git status
    git commit -am "kjkfjkg"
    git log
    git commit --amend -m "New comment added"
    git log
    git reset --soft HEAD^
    git log
    git pull origin master
    git push origin master

---

### Note

git revert vs git reset  
Reset removes the commit while revert removes the changes but leaves the commit  
Revert is safer considering we can revert a revert  


    # Changed file
    git commit -am "bug introduced"
    git revert HEAD
    # New commit created reverting changes
    # Now we want to re apply the reverted commit
    git log # take hash from the revert commit
    git revert <rev commit hash>
    # reverted commit is back (new commit created again)

---

## Questions

---

## Instructor Notes

---

### Version Control
 - Local VCS was used with a filesystem or a simple db.
 - Centralized VCS such as Subversion includes collaboration but
   still is prone to data loss as the main server is the single point of
   failure.
 - Distributed VCS enables the team to have a complete copy of the project
   and work with little dependency to the main server. In case of a main
   server failing the project can be recovered by any of the latest copies
   from the team
