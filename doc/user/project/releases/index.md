---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Releases **(FREE)**

In GitLab, a release enables you to create a snapshot of your project for your users, including
installation packages and release notes. You can create a GitLab release on any branch. Creating a
release also creates a [Git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) to mark the
release point in the source code.

WARNING:
Deleting a Git tag associated with a release also deletes the release.

A release can include:

- A snapshot of the source code of your repository.
- [Generic packages](../../packages/generic_packages/index.md) created from job artifacts.
- Other metadata associated with a released version of your code.
- Release notes.

When you [create a release](#create-a-release):

- GitLab automatically archives source code and associates it with the release.
- GitLab automatically creates a JSON file that lists everything in the release,
  so you can compare and audit releases. This file is called [release evidence](release_evidence.md).

When you create a release, or after, you can:

- Add release notes.
- Add a message for the Git tag associated with the release.
- [Associate milestones with it](#associate-milestones-with-a-release).
- Attach [release assets](release_fields.md#release-assets), like runbooks or packages.

## View releases

To view a list of releases:

- On the left sidebar, select **Deployments > Releases**, or

- On the project's overview page, if at least one release exists, select the number of releases.

  ![Number of Releases](img/releases_count_v13_2.png "Incremental counter of Releases")

  - On public projects, this number is visible to all users.
  - On private projects, this number is visible to users with Reporter
    [permissions](../../permissions.md#project-members-permissions) or higher.

### Sort releases

To sort releases by **Released date** or **Created date**, select from the sort order dropdown list. To
switch between ascending or descending order, select **Sort order**.

![Sort releases dropdown list options](img/releases_sort_v13_6.png)

## Create a release

You can create a release:

- [Using a job in your CI/CD pipeline](#creating-a-release-by-using-a-cicd-job).
- [In the Releases page](#create-a-release-in-the-releases-page).
- Using the [Releases API](../../../api/releases/index.md#create-a-release).

You should create a release as one of the last steps in your CI/CD pipeline.

### Create a release in the Releases page

Prerequisites:

- You must have at least the Developer role for a project. For more information, read
[Release permissions](#release-permissions).

To create a release in the Releases page:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Deployments > Releases** and select **New release**.
1. From the [**Tag name**](release_fields.md#tag-name) dropdown list, either:
   - Select an existing Git tag. Selecting an existing tag that is already associated with a release
     results in a validation error.
   - Enter a new Git tag name.
     1. From the **Create tag** popover, select a branch or commit SHA to use when
        creating the new tag.
     1. Optional. In the **Set tag message** text box, enter a message to create an
        [annotated tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging#_annotated_tags).
     1. Select **Save**.
1. Optional. Enter additional information about the release, including:
   - [Title](release_fields.md#title).
   - [Milestones](#associate-milestones-with-a-release).
   - [Release notes](release_fields.md#release-notes-description).
   - Whether or not to include the [Tag message](../repository/tags/index.md).
   - [Asset links](release_fields.md#links).
1. Select **Create release**.

### Creating a release by using a CI/CD job

You can create a release directly as part of the GitLab CI/CD pipeline by using the
[`release` keyword](../../../ci/yaml/index.md#release) in the job definition.

The release is created only if the job processes without error. If the API returns an error during
release creation, the release job fails.

Methods for creating a release using a CI/CD job include:

- [Create a release when a Git tag is created](release_cicd_examples.md#create-a-release-when-a-git-tag-is-created).
- [Create a release when a commit is merged to the default branch](release_cicd_examples.md#create-a-release-when-a-commit-is-merged-to-the-default-branch).
- [Create release metadata in a custom script](release_cicd_examples.md#create-release-metadata-in-a-custom-script).

### Use a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority,
which is used to verify the peer when the `release-cli` creates a release through the API using HTTPS with custom certificates.
The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the
[text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)
or the `path/to/file` containing the certificate authority.
For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
release:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  script:
    - echo "Create release"
  release:
    name: 'My awesome release'
    tag_name: '$CI_COMMIT_TAG'
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a
[custom variable in the UI](../../../ci/variables/index.md#for-a-project),
either as a `file`, which requires the path to the certificate, or as a variable,
which requires the text representation of the certificate.

### Create multiple releases in a single pipeline

A pipeline can have multiple `release` jobs, for example:

```yaml
ios-release:
  script:
    - echo "iOS release job"
  release:
    tag_name: v1.0.0-ios
    description: 'iOS release v1.0.0'

android-release:
  script:
    - echo "Android release job"
  release:
    tag_name: v1.0.0-android
    description: 'Android release v1.0.0'
```

### Release assets as Generic packages

You can use [Generic packages](../../packages/generic_packages/index.md) to host your release assets.
For a complete example, see the [Release assets as Generic packages](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs/examples/release-assets-as-generic-package/)
project.

## Upcoming releases

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38105) in GitLab 12.1.

You can create a release ahead of time by using the [Releases API](../../../api/releases/index.md#upcoming-releases).
When you set a future `released_at` date, an **Upcoming Release** badge is displayed next to the
release tag. When the `released_at` date and time has passed, the badge is automatically removed.

![An upcoming release](img/upcoming_release_v12_7.png)

## Historical releases

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/199429) in GitLab 15.2.

You can create a release in the past using either the
[Releases API](../../../api/releases/index.md#historical-releases) or the UI. When you set
a past `released_at` date, an **Historical release** badge is displayed next to
the release tag. Due to being released in the past, [release evidence](release_evidence.md)
is not available.

## Edit a release

To edit the details of a release after it's created, you can use the
[Update a release API](../../../api/releases/index.md#update-a-release) or the UI.

Prerequisites:

- You must have at least the Developer role.

In the UI:

1. On the left sidebar, select **Deployments > Releases**.
1. In the upper-right corner of the release you want to modify, select **Edit this release** (the pencil icon).
1. On the **Edit Release** page, change the release's details.
1. Select **Save changes**.

## Delete a release

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213862) in GitLab 15.2

When you delete a release, its assets are also deleted. However, the associated
Git tag is not deleted.

Prerequisites:

- You must have at least the Developer role. Read more about [Release permissions](#release-permissions).

To delete a release, use either the
[Delete a release API](../../../api/releases/index.md#delete-a-release) or the UI.

In the UI:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Deployments > Releases**.
1. In the upper-right corner of the release you want to delete, select **Edit this release**
   (**{pencil}**).
1. On the **Edit Release** page, select **Delete**.
1. Select **Delete release**.

## Associate milestones with a release

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29020) in GitLab 12.5.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/39467) to edit milestones in the UI in GitLab 13.0.

You can associate a release with one or more [project milestones](../milestones/index.md#project-milestones-and-group-milestones).

[GitLab Premium](https://about.gitlab.com/pricing/) customers can specify [group milestones](../milestones/index.md#project-milestones-and-group-milestones) to associate with a release.

You can do this in the user interface, or by including a `milestones` array in your request to
the [Releases API](../../../api/releases/index.md#create-a-release).

In the user interface, to associate milestones to a release:

1. On the left sidebar, select **Deployments > Releases**.
1. In the upper-right corner of the release you want to modify, select **Edit this release** (the pencil icon).
1. From the **Milestones** list, select each milestone you want to associate. You can select multiple milestones.
1. Select **Save changes**.

On the **Deployments > Releases** page, the **Milestone** is listed in the top
section, along with statistics about the issues in the milestones.

![A Release with one associated milestone](img/release_with_milestone_v12_9.png)

Releases are also visible on the **Issues > Milestones** page, and when you select a milestone
on this page.

Here is an example of milestones with no releases, one release, and two releases, respectively.

![Milestones with and without Release associations](img/milestone_list_with_releases_v12_5.png)

NOTE:
A subgroup's project releases cannot be associated with a parent group's milestone. To learn
more, read issue #328054,
[Releases cannot be associated with a supergroup milestone](https://gitlab.com/gitlab-org/gitlab/-/issues/328054).

## Get notified when a release is created

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26001) in GitLab 12.4.

You can be notified by email when a new release is created for your project.

To subscribe to notifications for releases:

1. On the left sidebar, select **Project information**.
1. Select **Notification setting** (the bell icon).
1. In the list, select **Custom**.
1. Select the **New release** checkbox.
1. Close the dialog box to save.

## Prevent unintentional releases by setting a deploy freeze

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29382) in GitLab 13.0.
> - The ability to delete freeze periods through the UI was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/212451) in GitLab 14.3.

Prevent unintended production releases during a period of time you specify by
setting a [*deploy freeze* period](../../../ci/environments/deployment_safety.md).
Deploy freezes help reduce uncertainty and risk when automating deployments.

A maintainer can set a deploy freeze window in the user interface or by using the [Freeze Periods API](../../../api/freeze_periods.md) to set a `freeze_start` and a `freeze_end`, which
are defined as [crontab](https://crontab.guru/) entries.

If the job that's executing is in a freeze period, GitLab CI/CD creates an environment
variable named `$CI_DEPLOY_FREEZE`.

To prevent the deployment job from executing, create a `rules` entry in your
`.gitlab-ci.yml`, for example:

```yaml
deploy_to_production:
  stage: deploy
  script: deploy_to_prod.sh
  rules:
    - if: $CI_DEPLOY_FREEZE == null
  environment: production
```

To set a deploy freeze window in the UI, complete these steps:

1. Sign in to GitLab as a user with the Maintainer role.
1. On the left sidebar, select **Project information**.
1. In the left navigation menu, go to **Settings > CI/CD**.
1. Scroll to **Deploy freezes**.
1. Select **Expand** to see the deploy freeze table.
1. Select **Add deploy freeze** to open the deploy freeze modal.
1. Enter the start time, end time, and time zone of the desired deploy freeze period.
1. Select **Add deploy freeze** in the modal.
1. After the deploy freeze is saved, you can edit it by selecting the edit button (**{pencil}**) and remove it by selecting the delete button (**{remove}**).
   ![Deploy freeze modal for setting a deploy freeze period](img/deploy_freeze_v14_3.png)

If a project contains multiple freeze periods, all periods apply. If they overlap, the freeze covers the
complete overlapping period.

For more information, see [Deployment safety](../../../ci/environments/deployment_safety.md).

## Release permissions

> Fixes to the permission model for create, update and delete actions [were introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327505) in GitLab 14.1.

### View a release and download assets

> Changes to the Guest role [were introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335209) in GitLab 14.5.

- Users with at least the Reporter role
  have read and download access to the project releases.
- Users with the Guest role
  have read and download access to the project releases.
  This includes associated Git-tag-names, release description, author information of the releases.
  However, other repository-related information, such as [source code](release_fields.md#source-code) and
  [release evidence](release_evidence.md) are redacted.

### Publish releases without giving access to source code

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216485) in GitLab 15.6.

Releases can be made accessible to non-project members while keeping repository-related information such as
[source code](release_fields.md#source-code) and [release evidence](release_evidence.md) private. Use this for
projects that use releases as a way to give access to new versions of software but do not want the source code to
be public.

To make releases available publicly, set the following [project settings](../settings/index.md#project-feature-settings):

- Repository is enabled and set to **Only Project Members**
- Releases is enabled and set to **Everyone With Access**

### Create, update, and delete a release and its assets

- Users with at least the Developer role
  have write access to the project releases and assets.
- If a release is associated with a [protected tag](../protected_tags.md),
  the user must be [allowed to create the protected tag](../protected_tags.md#configuring-protected-tags) too.

As an example of release permission control, you can allow only
users with at least the Maintainer role
to create, update, and delete releases by protecting the tag with a wildcard (`*`),
and set **Maintainer** in the **Allowed to create** column.

## Release Metrics **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259703) in GitLab Premium 13.9.

Group-level release metrics are available by navigating to **Group > Analytics > CI/CD**.
These metrics include:

- Total number of releases in the group
- Percentage of projects in the group that have at least one release

## Working example project

The Guided Exploration project [Utterly Automated Software and Artifact Versioning with GitVersion](https://gitlab.com/guided-explorations/devops-patterns/utterly-automated-versioning) demonstrates:

- Using GitLab releases.
- Using the GitLab `release-cli`.
- Creating a generic package.
- Linking the package to the release.
- Using a tool called [GitVersion](https://gitversion.net/) to automatically determine and increment versions for complex repositories.

You can copy the example project to your own group or instance for testing. More details on what other GitLab CI patterns are demonstrated are available at the project page.

## Troubleshooting

### Getting `403 Forbidden` or `Something went wrong while creating a new release` errors when creating, updating or deleting releases and their assets

If the release is associated with a [protected tag](../protected_tags.md),
the UI/API request might result in an authorization failure.
Make sure that the user or a service/bot account is allowed to
[create the protected tag](../protected_tags.md#configuring-protected-tags) too.

See [the release permissions](#release-permissions) for more information.

### Note about storage

Note that the feature is built on top of Git tags, so virtually no extra data is needed besides to create the release itself. Additional assets and the release evidence that is automatically generated consume storage.
