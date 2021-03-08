---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/workflow.html'
---

# Feature branch workflow **(FREE)**

1. Clone project:

   ```shell
   git clone git@example.com:project-name.git
   ```

1. Create branch with your feature:

   ```shell
   git checkout -b $feature_name
   ```

1. Write code. Commit changes:

   ```shell
   git commit -am "My feature is ready"
   ```

1. Push your branch to GitLab:

   ```shell
   git push origin $feature_name
   ```

1. Review your code on commits page.

1. Create a merge request.

1. Your team lead reviews the code and merges it to the main branch.
