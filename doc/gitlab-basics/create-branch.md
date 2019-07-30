---
type: howto
---

# How to create a branch

A branch is an independent line of development in a [project](../user/project/index.md).

When you create a new branch (in your [terminal](basic-git-commands.md) or with
[the web interface](../user/project/repository/web_editor.md#create-a-new-branch)),
you are creating a snapshot of a certain branch, usually the main `master` branch,
at it's current state. From there, you can start to make your own changes without
affecting the main codebase. The history of your changes will be tracked in your branch.

When your changes are ready, you then merge them into the rest of the codebase with a
[merge request](add-merge-request.md).
