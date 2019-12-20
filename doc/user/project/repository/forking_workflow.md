---
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/forking_workflow.html'
---

# Project forking workflow

Forking a project to your own namespace is useful if you have no write
access to the project you want to contribute to. If you do have write
access or can request it, we recommend working together in the same
repository since it is simpler. See our [GitLab Flow](../../../topics/gitlab_flow.md)
document more information about using branches to work together.

## Creating a fork

Forking a project is in most cases a two-step process.

1. Click on the fork button located located in between the star and clone buttons on the project's home page.

   ![Fork button](img/forking_workflow_fork_button.png)

1. Once you do that, you'll be presented with a screen where you can choose
   the namespace to fork to. Only namespaces (groups and your own
   namespace) where you have write access to, will be shown. Click on the
   namespace to create your fork there.

   ![Choose namespace](img/forking_workflow_choose_namespace.png)

   **Note:**
   If the namespace you chose to fork the project to has another project with
   the same path name, you will be presented with a warning that the forking
   could not be completed. Try to resolve the error before repeating the forking
   process.

   ![Path taken error](img/forking_workflow_path_taken_error.png)

After the forking is done, you can start working on the newly created
repository. There, you will have full [Owner](../../permissions.md)
access, so you can set it up as you please.

CAUTION: **CAUTION:**
From GitLab 12.6 onwards, if the [visibility of an upstream project is reduced](../../../public_access/public_access.md#reducing-visibility)
in any way, the fork relationship with all its forks will be removed.

## Merging upstream

Once you are ready to send your code back to the main project, you need
to create a merge request. Choose your forked project's main branch as
the source and the original project's main branch as the destination and
create the [merge request](../merge_requests/index.md).

![Selecting branches](img/forking_workflow_branch_select.png)

You can then assign the merge request to someone to have them review
your changes. Upon pressing the 'Submit Merge Request' button, your
changes will be added to the repository and branch you're merging into.

![New merge request](img/forking_workflow_merge_request.png)

[gitlab flow]: https://about.gitlab.com/blog/2014/09/29/gitlab-flow/ "GitLab Flow blog post"
