---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Feature branch workflow

To merge changes from a local branch to a feature branch, follow this workflow.

1. Clone the project if you haven't already:

   ```shell
   git clone git@example.com:project-name.git
   ```

1. Change directories so you are in the project directory.
1. Create a branch for your feature:

   ```shell
   git checkout -b feature_name
   ```

1. Write code for the feature.
1. Add the code to the staging area and add a commit message for your changes:

   ```shell
   git commit -am "My feature is ready"
   ```

1. Push your branch to GitLab:

   ```shell
   git push origin feature_name
   ```

1. Review your code: On the left sidebar, go to **Code > Commits**.
1. [Create a merge request](../user/project/merge_requests/creating_merge_requests.md).
1. Your team lead reviews the code and merges it to the main branch.
