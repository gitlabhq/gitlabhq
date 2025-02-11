---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Design management
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

With Design Management you can upload design assets (including wireframes and mockups)
to GitLab issues and keep them stored in a single place. Product designers, product managers, and
engineers can collaborate on designs with a single source of truth.

You can share mockups of designs with your team, or visual regressions can be
viewed and addressed.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video overview, see [Design Management](https://www.youtube.com/watch?v=CCMtCqdK_aM).
<!-- Video published on 2019-07-11 -->

## Prerequisites

- [Git Large File Storage (LFS)](../../../topics/git/lfs/_index.md) must be enabled:
  - On GitLab.com, LFS is already enabled.
  - On self-managed instances, a GitLab administrator must
    [enable LFS globally](../../../administration/lfs/_index.md).
  - On both GitLab.com and self-managed instances, LFS must be
    [enabled for the project itself](../settings/_index.md#configure-project-features-and-permissions).
    If enabled globally, LFS is enabled by default for all projects. If you have
    disabled it for your project, you must enable it again.

  Designs are stored as LFS objects.
  Image thumbnails are stored as other uploads, and are not associated with a project but rather
  with a specific design model.

  A GitLab administrator can verify the relative path of a hashed-stored project by going to **Admin area > Projects**
  and then selecting the project in question. The **Relative path** field contains `@hashed` in its value.

If the requirements are not met, you are notified in the **Designs** section.

## Supported file types

You can upload files of the following types as designs:

- BMP
- GIF
- ICO
- JPEG
- JPG
- PNG
- TIFF
- WEBP

Support for PDF files is tracked in [issue 32811](https://gitlab.com/gitlab-org/gitlab/-/issues/32811).

## View a design

The **Designs** section is in the issue description.

Prerequisites:

- You must have at least the Guest role for the project.

To view a design:

1. Go to an issue.
1. In the **Designs** section, select the design image you want to view.

The design you selected opens. You can then [zoom in](#zoom-in-on-a-design) on it or
[create a comment](#add-a-comment-to-a-design).

![Designs section](img/design_management_v14_10.png)

When viewing a design, you can move to other designs. To do so, either:

- In the upper-right corner, select **Go to previous design** (**{chevron-lg-left}**) or **Go to next design** (**{chevron-lg-right}**).
- Press <kbd>Left</kbd> or <kbd>Right</kbd> on your keyboard.

To return to the issue view, either:

- In the upper-left corner, select the close icon (**{close}**).
- Press <kbd>Esc</kbd> on your keyboard.

When a design is added, a green icon (**{plus-square}**) is displayed on the image
thumbnail. When a design has been [changed](#add-a-new-version-of-a-design) in the current version,
a blue icon (**{file-modified-solid}**) is displayed.

### Zoom in on a design

You can explore a design in more detail by zooming in and out of the image:

- To control the amount of zoom, select plus (`+`) and minus (`-`)
  at the bottom of the image.
- To reset the zoom level, select the redo icon (**{redo}**).

To move around the image while zoomed in, drag the image.

## Add a design to an issue

> - Ability to edit the description [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388449) in GitLab 16.1.
> - Minimum role to add a design to an issue [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147053) from Developer to Reporter in GitLab 16.11.
> - Minimum role to add a design to an issue [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for the project.
- The names of the uploaded files must be no longer than 255 characters.

To add a design to an issue:

1. Go to an issue.
1. Either:
   - Select **Upload designs** and then select images from your file browser. You can select up to
     10 files at once.
   <!-- vale gitlab_base.SubstitutionWarning = NO -->
   - Select **click to upload** and then select images from your file browser. You can select up to
     10 files at once.
   <!-- vale gitlab_base.SubstitutionWarning = YES -->

   - Drag a file from your file browser and drop it in the drop zone in the **Designs** section.

     ![Drag and drop design uploads](img/design_drag_and_drop_uploads_v13_2.png)

   - Take a screenshot or copy a local image file into your clipboard, hover your cursor over the
     drop zone, and press <kbd>Control</kbd> or <kbd>Cmd</kbd> + <kbd>V</kbd>.

     When pasting images like this, keep the following in mind:

     - You can paste only one image at a time. When you paste multiple copied files, only the first
       one is uploaded.
     - If you are pasting a screenshot, the image is added as a PNG file with a generated name of:
       `design_<timestamp>.png`.
     - It's not supported in Internet Explorer.

## Add a new version of a design

> - Minimum role to add a new version of a design [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147053) from Developer to Reporter in GitLab 16.11.
> - Minimum role to add a new version of a design [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

As discussion on a design continues, you might want to upload a new version of a design.

Prerequisites:

- You must have at least the Planner role for the project.

To do so, [add a design](#add-a-design-to-an-issue) with the same filename.

To browse all the design versions, use the dropdown list at the top of the **Designs** section.
It's shown as either **Showing latest version** or **Showing version #N**.

### Skipped designs

When you upload an image with the same filename as an existing uploaded design _and_ that is the
same, it's skipped. This means that no new version of the design is created.
When designs are skipped, a warning message is displayed.

## Archive a design

> - Minimum role to archive a design [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147053) from Developer to Reporter in GitLab 16.11.
> - Minimum role to archive a design [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

You can archive individual designs or select a few of them to archive at once.

Archived designs are not permanently lost.
You can browse [previous versions](#add-a-new-version-of-a-design).

When you archive a design, its URL changes.
If the design isn't available in the latest version, you can link to it only with the version in the
URL.

Prerequisites:

- You must have at least the Planner role for the project.
- You can archive only the latest version of a design.

To archive a single design:

1. Select the design to view it enlarged.
1. In the upper-right corner, select **Archive design** (**{archive}**).
1. Select **Archive designs**.

To archive multiple designs at once:

1. Select the checkboxes on the designs you want to archive.
1. Select **Archive selected**.

## Design management data persistence

- Design Management data is not deleted when:
  - [A project is destroyed](https://gitlab.com/gitlab-org/gitlab/-/issues/13429).
  - [An issue is deleted](https://gitlab.com/gitlab-org/gitlab/-/issues/13427).

### Replicate design management data

Design Management data [can be replicated](../../../administration/geo/replication/datatypes.md#replicated-data-types)
and in GitLab 16.1 and later it can be [verified by Geo as well](https://gitlab.com/gitlab-org/gitlab/-/issues/355660).

## Markdown and rich text editors for descriptions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388449) in GitLab 16.1 [with a flag](../../../administration/feature_flags.md) named `content_editor_on_issues`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/375172) in GitLab 16.2.
> - Feature flag `content_editor_on_issues` removed in GitLab 16.5.

You can use the Markdown and rich text editor in design descriptions.
It's the same editor you use for comments across GitLab.

## Reorder designs

You can change the order of designs by dragging them to a new position.

## Add a comment to a design

You can start [discussions](../../discussions/_index.md) on uploaded designs. To do so:

1. Go to an issue.
1. Select the design.
<!-- vale gitlab_base.SubstitutionWarning = NO -->
<!-- Disable Vale so it doesn't catch "click" -->
1. Click or tap the image. A pin is created in that spot, identifying the discussion's location.
<!-- vale gitlab_base.SubstitutionWarning = YES -->
1. Enter your message.
1. Select **Comment**.

You can adjust a pin's position by dragging it around the image.
Use this when your design's layout has changed, or to move a pin so you can add a new one in
its place.

New discussion threads get different pin numbers, which you can use to refer to them.

New discussions are output to the issue activity,
so that everyone involved can participate in the discussion.

## Delete a comment from a design

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385100) in GitLab 15.9.
> - Minimum role to delete comment from a design [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

Prerequisites:

- You must have at least the Planner role for the project.

To delete a comment from a design:

1. On the comment you want to delete, select **More actions** **{ellipsis_v}** **> Delete comment**.
1. On the confirmation dialog, select **Delete comment**.

## Resolve a discussion thread on a design

When you're done discussing part of a design, you can resolve the discussion thread.

To mark a thread as resolved or unresolved, either:

- In the upper-right corner of the first comment of the discussion, select **Resolve thread** or **Unresolve thread** (**{check-circle}**).
- Add a new comment to the thread and select or clear the **Resolve thread** checkbox.

Resolving a discussion thread also marks any pending [to-do items](../../todos.md) related to notes
inside the thread as done. Only to-do items for the user triggering the action are affected.

Your resolved comment pins disappear from the design to free up space for new discussions.
To revisit a resolved discussion, expand **Resolved Comments** below the visible threads.

## Add a to-do item for a design

To add a [to-do item](../../todos.md) for a design, select **Add a to-do item** on the design sidebar.

## Refer to a design in Markdown

To refer to a design in a [Markdown](../../markdown.md) text box in GitLab, for example, in
a comment or description, paste its URL. It's then displayed as a short reference.

For example, if you refer to a design somewhere with:

```markdown
See https://gitlab.com/gitlab-org/gitlab/-/issues/13195/designs/Group_view.png.
```

It's rendered as:

> See [#13195[Group_view.png]](https://gitlab.com/gitlab-org/gitlab/-/issues/13195/designs/Group_view.png).

## Design activity records

User activity events on designs (creation, deletion, and updates) are tracked by GitLab and
displayed on the [user profile](../../profile/_index.md#access-your-user-profile),
[group](../../group/manage.md#view-group-activity),
and [project](../working_with_projects.md#view-project-activity) activity pages.

## GitLab-Figma plugin

You can use the GitLab-Figma plugin to upload your designs from Figma directly to your issues
in GitLab.

To use the plugin in Figma, install it from the [Figma Directory](https://www.figma.com/community/plugin/860845891704482356/gitlab)
and connect to GitLab through a personal access token.

For more information, see the [plugin documentation](https://gitlab.com/gitlab-org/gitlab-figma-plugin/-/wikis/home).

## Troubleshooting

When working with Design Management, you might encounter the following issues.

### Could not find design

You might get an error that states `Could not find design`.

This issue occurs when a design has been [archived](#archive-a-design),
so it's not available in the latest version, and the link you've followed doesn't specify a version.

When you archive a design, its URL changes.
If the design isn't available in the latest version, it can be linked to only with the version in the URL.

For example, `https://gitlab.example.com/mygroup/myproject/-/issues/123456/designs/menu.png?version=503554`.
You can no longer access `menu.png` with `https://gitlab.example.com/mygroup/myproject/-/issues/123456/designs/menu.png`.

The workaround is to select one of the previous versions from the dropdown list at the top of the
**Designs** section.
It's shown as either **Showing latest version** or **Showing version #N**.

Issue [392540](https://gitlab.com/gitlab-org/gitlab/-/issues/392540) tracks improving this behavior.
