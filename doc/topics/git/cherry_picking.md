---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Cherry pick **(FREE)**

Given an existing commit on one branch, apply the change to another branch.

This can be useful for backporting bug fixes to previous release branches. Make
the commit on the default branch, and then cherry pick it into the release branch.

## Sample workflow

1. Check out a new `stable` branch from the default branch:

   ```shell
   git checkout master
   git checkout -b stable
   ```

1. Change back to the default branch:

   ```shell
   git checkout master
   ```

1. Make any required changes, then commit the changes:

   ```shell
   git add changed_file.rb
   git commit -m 'Fix bugs in changed_file.rb'
   ```

1. Review the commit log and copy the SHA of the latest commit:

   ```shell
   git log
   ```

1. Check out the `stable` branch:

   ```shell
   git checkout stable
   ```

1. Cherry pick the commit by using the SHA copied previously:

   ```shell
   git cherry-pick <commit SHA>
   ```
