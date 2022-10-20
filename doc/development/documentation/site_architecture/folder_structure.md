---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Folder structure for documentation

The documentation is separated by top-level audience folders [`user`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/user),
[`administration`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/administration),
and [`development`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/development)
(contributing) folders.

Beyond that, we primarily follow the structure of the GitLab user interface or
API.

Our goal is to have a clear hierarchical structure with meaningful URLs like
`docs.gitlab.com/user/project/merge_requests/`. With this pattern, you can
immediately tell that you are navigating to user-related documentation about
Project features; specifically about Merge Requests. Our site's paths match
those of our repository, so the clear structure also makes documentation easier
to update.

Put files for a specific product area into the related folder:

| Directory             | Contents |
|:----------------------|:------------------|
| `doc/user/`           | Documentation for users. Anything that can be done in the GitLab user interface goes here, including usage of the `/admin` interface. |
| `doc/administration/` | Documentation that requires the user to have access to the server where GitLab is installed. Administrator settings in the GitLab user interface are under `doc/user/admin_area/`. |
| `doc/api/`            | Documentation for the API. |
| `doc/development/`    | Documentation related to the development of GitLab, whether contributing code or documentation. Related process and style guides should go here. |
| `doc/legal/`          | Legal documents about contributing to GitLab. |
| `doc/install/`        | Instructions for installing GitLab. |
| `doc/update/`         | Instructions for updating GitLab. |
| `doc/topics/`         | Indexes per topic (`doc/topics/topic_name/index.md`): all resources for that topic. |

## Work with directories and files

When working with directories and files:

1. When you create a new directory, always start with an `index.md` file.
   Don't use another filename and do not create `README.md` files.
1. Do not use special characters and spaces, or capital letters in file
   names, directory names, branch names, and anything that generates a path.
1. When creating or renaming a file or directory and it has more than one word
   in its name, use underscores (`_`) instead of spaces or dashes. For example,
   proper naming would be `import_project/import_from_github.md`. This applies
   to both image files and Markdown files.
1. For image files, do not exceed 100KB.
1. Do not upload video files to the product repositories.
   [Link or embed videos](../styleguide/index.md#videos) instead.
1. There are four main directories: `user`, `administration`, `api`, and
   `development`.
1. The `doc/user/` directory has five main subdirectories: `project/`, `group/`,
   `profile/`, `dashboard/` and `admin_area/`.
   - `doc/user/project/` should contain all project related documentation.
   - `doc/user/group/` should contain all group related documentation.
   - `doc/user/profile/` should contain all profile related documentation.
     Every page you would navigate under `/profile` should have its own document,
     for example, `account.md`, `applications.md`, or `emails.md`.
   - `doc/user/dashboard/` should contain all dashboard related documentation.
   - `doc/user/admin_area/` should contain all administrator-related
     documentation describing what can be achieved by accessing the GitLab
     administrator interface (not to be confused with `doc/administration` where
     server access is required).
     - Every category under `/admin/application_settings/` should have its
      own document located at `doc/user/admin_area/settings/`. For example,
      the **Visibility and Access Controls** category should have a document
      located at `doc/user/admin_area/settings/visibility_and_access_controls.md`.
1. The `doc/topics/` directory holds topic-related technical content. Create
   `doc/topics/topic_name/subtopic_name/index.md` when subtopics become necessary.
   General user and administrator documentation should be placed accordingly.
1. The `/university/` directory is *deprecated* and the majority of its documentation
   has been moved.

If you're unsure where to place a document or a content addition, this shouldn't
stop you from authoring and contributing. Use your best judgment, and then ask
the reviewer of your MR to confirm your decision. You can also ask a technical writer at
any stage in the process. The technical writing team reviews all
documentation changes, regardless, and can move content if there is a better
place for it.

## Avoid duplication

Do not include the same information in multiple places.
[Link to a single source of truth instead.](../styleguide/index.md#link-instead-of-repeating-text)

For example, if you have code in a repository other than the [primary repositories](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/architecture.md),
and documentation in the same repository, you can keep the documentation in that repository.

Then you can either:

- Publish it to <https://docs.gitlab.com>.
- Link to it from <https://docs.gitlab.com> by adding an entry in the global navigation.
  View [an example](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/fedb6378a3c92274ba3b6031df0d34455594e4cc/content/_data/navigation.yaml#L2944).

## References across documents

- Give each folder an `index.md` page that introduces the topic, and both introduces
  and links to the child pages, including to the index pages of
  any next-level sub-paths.
- To ensure discoverability, ensure each new or renamed doc is linked from its
  higher-level index page and other related pages.
- When making reference to other GitLab products and features, link to their
  respective documentation, at least on first mention.
- When making reference to third-party products or technologies, link out to
  their external sites, documentation, and resources.
