---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# Protected tags **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10356) in GitLab 9.1.

Protected tags:

- Allow control over who has permission to create tags.
- Prevent accidental update or deletion once created.

Each rule allows you to match either:

- An individual tag name.
- Wildcards to control multiple tags at once.

This feature evolved out of [protected branches](protected_branches.md)

## Who can modify a protected tag

By default:

- To create tags, you must have the [Maintainer role](../permissions.md).
- No one can update or delete tags.

## Configuring protected tags

To protect a tag, you need to have at least the [Maintainer role](../permissions.md).

1. Go to the project's **Settings > Repository**.

1. From the **Tag** dropdown menu, select the tag you want to protect or type and click **Create wildcard**. In the screenshot below, we chose to protect all tags matching `v*`:

   ![Protected tags page](img/protected_tags_page_v12_3.png)

1. From the **Allowed to create** dropdown, select users with permission to create
   matching tags, and click **Protect**:

   ![Allowed to create tags dropdown](img/protected_tags_permissions_dropdown_v12_3.png)

1. After done, the protected tag displays in the **Protected tags** list:

   ![Protected tags list](img/protected_tags_list_v12_3.png)

## Wildcard protected tags

You can specify a wildcard protected tag, which protects all tags
matching the wildcard. For example:

| Wildcard Protected Tag | Matching Tags                 |
|------------------------|-------------------------------|
| `v*`                   | `v1.0.0`, `version-9.1`       |
| `*-deploy`             | `march-deploy`, `1.0-deploy`  |
| `*gitlab*`             | `gitlab`, `gitlab/v1`         |
| `*`                    | `v1.0.1rc2`, `accidental-tag` |

Two different wildcards can potentially match the same tag. For example,
`*-stable` and `production-*` would both match a `production-stable` tag.
In that case, if _any_ of these protected tags have a setting like
**Allowed to create**, then `production-stable` also inherit this setting.

If you click on a protected tag's name, GitLab displays a list of
all matching tags:

![Protected tag matches](img/protected_tag_matches.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
