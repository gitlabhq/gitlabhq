---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure a collection of file templates available for all projects on GitLab Self-Managed."
title: Instance template repository
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

In hosted systems, enterprises often have a need to share their own templates
across teams. This feature allows an administrator to pick a project to be the
instance-wide collection of file templates. These templates are then exposed to
all users through the [Web Editor](../../user/project/repository/web_editor.md)
while the project remains secure.

## Configuration

To select a project to serve as the custom template repository:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Templates**.
1. Expand **Templates**
1. From the dropdown list, select the project to use as the template repository.
1. Select **Save changes**.
1. Add custom templates to the selected repository.

After you add templates, you can use them for the entire instance.
They are available in the [Web Editor](../../user/project/repository/web_editor.md)
and through the [API settings](../../api/settings.md).

These templates cannot be used as a value of the
[`include:template`](../../ci/yaml/_index.md#includetemplate) key in `.gitlab-ci.yml`.

## Supported file types and locations

Templates must be added to a specific subdirectory in the repository,
corresponding to the kind of template. The following types of custom templates
are supported:

| Type                    | Directory            | Extension     |
| :---------------:       | :-----------:        | :-----------: |
| `Dockerfile`            | `Dockerfile`         | `.dockerfile` |
| `.gitignore`            | `gitignore`          | `.gitignore`  |
| `.gitlab-ci.yml`        | `gitlab-ci`          | `.yml`        |
| `LICENSE`               | `LICENSE`            | `.txt`        |

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
```

Your custom templates are displayed on the dropdown list when a new file is added through the GitLab UI:

![The GitLab UI for creating a new file, with a dropdown list displaying the Dockerfile templates to choose from.](img/file_template_user_dropdown_v11_4.png)

If this feature is disabled or no templates are present,
no **Custom** section displays in the selection dropdown list.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
