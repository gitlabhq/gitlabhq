# How to create a project in GitLab

1. In your dashboard, click the green **New project** button or use the plus
   icon in the upper right corner of the navigation bar.

    ![Create a project](img/create_new_project_button.png)

1. This opens the **New project** page.

    ![Project information](img/create_new_project_info.png)

1. Provide the following information:
    - Enter the name of your project in the **Project name** field. You can't use
      special characters, but you can use spaces, hyphens, underscores or even
      emoji.
    - If you have a project in a different repository, you can [import it] by
      clicking an **Import project from** button provided this is enabled in
      your GitLab instance. Ask your administrator if not.
    - The **Project description (optional)** field enables you to enter a
      description for your project's dashboard, which will help others
      understand what your project is about. Though it's not required, it's a good
      idea to fill this in.
    - Changing the **Visibility Level** modifies the project's
      [viewing and access rights](../public_access/public_access.md) for users.

1. Click **Create project**.

## From a template

To kickstart your development GitLab projects can be started from a template.
For example, one of the templates included is Ruby on Rails. When filling out the 
form for new projects, click the 'Ruby on Rails' button. During project creation,
this will import a Ruby on Rails template with GitLab CI preconfigured.

[import it]: ../workflow/importing/README.md
