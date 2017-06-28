# How to create a merge request

Merge requests are useful to integrate separate changes that you've made to a
project, on different branches. This is a brief guide on how to create a merge
request. For more information, check the
[merge requests documentation](../user/project/merge_requests.md).

---

1. Before you start, you should have already [created a branch](create-branch.md)
   and [pushed your changes](basic-git-commands.md) to GitLab.

1. You can then go to the project where you'd like to merge your changes and
   click on the **Merge requests** tab.

    ![Merge requests](img/project_navbar.png)

1. Click on **New merge request** on the right side of the screen.

    ![New Merge Request](img/merge_request_new.png)

1. Select a source branch and click on the **Compare branches and continue** button.

    ![Select a branch](img/merge_request_select_branch.png)

1. At a minimum, add a title and a description to your merge request. Optionally,
   select a user to review your merge request and to accept or close it. You may
   also select a milestone and labels.

    ![New merge request page](img/merge_request_page.png)

1. When ready, click on the **Submit merge request** button. Your merge request
   will be ready to be approved and published.
