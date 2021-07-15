---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import your project from FogBugz to GitLab **(FREE)**

Using the importer, you can import your FogBugz project to GitLab.com
or to your self-managed GitLab instance.

The importer imports all of your cases and comments with the original
case numbers and timestamps. You can also map FogBugz users to GitLab
users.

To import your project from FogBugz:

1. From your GitLab dashboard, select **New project**.
1. Select the **FogBugz** button.
   ![FogBugz](img/fogbugz_import_select_fogbogz.png)
1. Enter your FogBugz URL, email address, and password.
   ![Login](img/fogbugz_import_login.png)
1. Create a mapping from FogBugz users to GitLab users.
   ![User Map](img/fogbugz_import_user_map.png)
1. Select **Import** for the projects you want to import.
   ![Import Project](img/fogbugz_import_select_project.png)
1. After the import finishes, click the link to go to the project
   dashboard. Follow the directions to push your existing repository.
   ![Finished](img/fogbugz_import_finished.png)
