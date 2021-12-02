---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Commit message templates **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20263) in GitLab 14.5.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/345275) squash commit templates in GitLab 14.6.

GitLab uses commit templates to create default messages for specific types of
commits. These templates encourage commit messages to follow a particular format,
or contain specific information. Users can override these templates when merging
a merge request.

Commit templates use syntax similar to the syntax for
[review suggestions](reviews/suggestions.md#configure-the-commit-message-for-applied-suggestions).

## Configure commit templates

Change the commit templates for your project if the default templates don't
contain the information you need.

Prerequisite:

- You must have at least the Maintainer role for a project.

To do this:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General** and expand **Merge requests**.
1. Depending on the type of template you want to create, scroll to either
   [**Merge commit message template**](#default-template-for-merge-commits) or
   [**Squash commit message template**](#default-template-for-squash-commits).
1. For your desired commit type, enter your default message. You can use both static
   text and [variables](#supported-variables-in-commit-templates). Each template
   is limited to a maximum of 500 characters, though after replacing the templates
   with data, the final message may be longer.
1. Select **Save changes**.

## Default template for merge commits

The default template for merge commit messages is:

```plaintext
Merge branch '%{source_branch}' into '%{target_branch}'

%{title}

%{issues}

See merge request %{reference}
```

## Default template for squash commits

If you have configured your project to [squash commits on merge](squash_and_merge.md),
GitLab creates a squash commit message with this template:

```plaintext
%{title}
```

## Supported variables in commit templates

Commit message templates support these variables:

| Variable | Description | Output example |
|----------|-------------|----------------|
| `%{source_branch}` | The name of the branch being merged. | `my-feature-branch` |
| `%{target_branch}` | The name of the branch that the changes are applied to. | `main` |
| `%{title}`         | Title of the merge request. | `Fix tests and translations` |
| `%{issues}`        | String with phrase `Closes <issue numbers>`. Contains all issues mentioned in the merge request description that match [issue closing patterns](../issues/managing_issues.md#closing-issues-automatically). Empty if no issues are mentioned. | `Closes #465, #190 and #400` |
| `%{description}`   | Description of the merge request. | `Merge request description.<br>Can be multiline.` |
| `%{reference}`     | Reference to the merge request. | `group-name/project-name!72359` |

Empty variables that are the only word in a line are removed, along with all newline characters preceding it.

## Related topics

- [Squash and merge](squash_and_merge.md).
