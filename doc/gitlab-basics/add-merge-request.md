---
type: howto
---

# How to create a merge request

Merge requests are how you integrate separate changes that you've made in a
[branch](create-branch.md) to a [project](create-project.md).

This is a brief guide on how to create a merge request. For more detailed information,
check the [merge requests documentation](../user/project/merge_requests/index.md), or
you can watch our [GitLab Flow video](https://www.youtube.com/watch?v=InKNIvky2KE) for
a quick overview of working with merge requests.

1. Before you start, you should have already [created a branch](create-branch.md)
   and [pushed your changes](start-using-git.md#send-changes-to-gitlabcom) to GitLab.
1. Go to the project where you'd like to merge your changes and click on the
   **Merge requests** tab.
1. Click on **New merge request** on the right side of the screen.
1. From there, you have the option to select the source branch and the target
   branch you'd like to compare to. The default target project is the upstream
   repository, but you can choose to compare across any of its forks.

   ![Select a branch](img/merge_request_select_branch.png)

1. When ready, click on the **Compare branches and continue** button.
1. At a minimum, add a title and a description to your merge request. Optionally,
   select a user to review your merge request. You may also select a milestone and
   labels.

   ![New merge request page](img/merge_request_page.png)

1. When ready, click on the **Submit merge request** button.

Your merge request will be ready to be reviewed, approved, and merged.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
