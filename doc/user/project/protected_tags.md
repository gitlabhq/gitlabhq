# Protected Tags

> [Introduced][ce-10356] in GitLab 9.1.

Protected Tags allow control over who has permission to create tags as well as preventing accidental update or deletion once created. Each rule allows you to match either an individual tag name, or use wildcards to control multiple tags at once.

This feature evolved out of [Protected Branches](protected_branches.md)

## Overview

Protected tags will prevent anyone from updating or deleting the tag, as and will prevent creation of matching tags based on the permissions you have selected. By default, anyone without Maintainer permission will be prevented from creating tags.


## Configuring protected tags

To protect a tag, you need to have at least Maintainer permission level.

1. Navigate to the project's Settings -> Repository page

    ![Repository Settings](img/project_repository_settings.png)

1. From the **Tag** dropdown menu, select the tag you want to protect or type and click `Create wildcard`. In the screenshot below, we chose to protect all tags matching `v*`.

    ![Protected tags page](img/protected_tags_page.png)

1. From the `Allowed to create` dropdown, select who will have permission to create matching tags and then click `Protect`.

    ![Allowed to create tags dropdown](img/protected_tags_permissions_dropdown.png)

1. Once done, the protected tag will appear in the "Protected tags" list.

    ![Protected tags list](img/protected_tags_list.png)

## Wildcard protected tags

You can specify a wildcard protected tag, which will protect all tags
matching the wildcard. For example:

| Wildcard Protected Tag | Matching Tags                 |
|------------------------+-------------------------------|
| `v*`                   | `v1.0.0`, `version-9.1`       |
| `*-deploy`             | `march-deploy`, `1.0-deploy`  |
| `*gitlab*`             | `gitlab`, `gitlab/v1`         |
| `*`                    | `v1.0.1rc2`, `accidental-tag` |


Two different wildcards can potentially match the same tag. For example,
`*-stable` and `production-*` would both match a `production-stable` tag.
In that case, if _any_ of these protected tags have a setting like
"Allowed to create", then `production-stable` will also inherit this setting.

If you click on a protected tag's name, you will be presented with a list of
all matching tags:

![Protected tag matches](img/protected_tag_matches.png)


---

[ce-10356]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10356 "Protected Tags"
