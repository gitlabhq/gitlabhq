---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Instance template repository **(PREMIUM SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5986) in GitLab Premium 11.3.

In hosted systems, enterprises often have a need to share their own templates
across teams. This feature allows an administrator to pick a project to be the
instance-wide collection of file templates. These templates are then exposed to
all users [via the web editor](../../project/repository/web_editor.md#template-dropdowns)
while the project remains secure.

## Configuration

To select a project to serve as the custom template repository:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Templates**.
1. Select the project:

   ![File templates in the Admin Area](img/file_template_admin_area_v14_0.png)

1. Add custom templates to the selected repository.

After you add templates, you can use them for the entire instance.
They are available in the [Web Editor's dropdown](../../project/repository/web_editor.md#template-dropdowns)
and through the [API settings](../../../api/settings.md).

Templates must be added to a specific subdirectory in the repository,
corresponding to the kind of template. The following types of custom templates
are supported:

| Type                    | Directory            | Extension     |
| :---------------:       | :-----------:        | :-----------: |
| `Dockerfile`            | `Dockerfile`         | `.dockerfile` |
| `.gitignore`            | `gitignore`          | `.gitignore`  |
| `.gitlab-ci.yml`        | `gitlab-ci`          | `.yml`        |
| `LICENSE`               | `LICENSE`            | `.txt`        |
| `metrics-dashboard.yml` | `metrics-dashboards` | `.yml`        |

Each template must go in its respective subdirectory, have the correct
extension and not be empty. So, the hierarchy should look like this:

```plaintext
|-- README.md
|-- Dockerfile
    |-- custom_dockerfile.dockerfile
    |-- another_dockerfile.dockerfile
|-- gitignore
    |-- custom_gitignore.gitignore
    |-- another_gitignore.gitignore
|-- gitlab-ci
    |-- custom_gitlab-ci.yml
    |-- another_gitlab-ci.yml
|-- LICENSE
    |-- custom_license.txt
    |-- another_license.txt
|-- metrics-dashboards
    |-- custom_metrics-dashboard.yml
    |-- another_metrics-dashboard.yml
```

Your custom templates are displayed on the dropdown menu when a new file is added through the GitLab UI:

![Custom template dropdown menu](img/file_template_user_dropdown.png)

If this feature is disabled or no templates are present,
no **Custom** section displays in the selection dropdown.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
