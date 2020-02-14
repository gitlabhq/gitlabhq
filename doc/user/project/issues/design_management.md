# Design Management **(PREMIUM)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/660) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.2.

CAUTION: **Warning:**
This an **alpha** feature and is subject to change at any time without
prior notice.

## Overview

Design Management allows you to upload design assets (wireframes, mockups, etc.)
to GitLab issues and keep them stored in one single place, accessed by the Design
Management's page within an issue, giving product designers, product managers, and engineers a
way to collaborate on designs over one single source of truth.

You can easily share mock-ups of designs with your team, or visual regressions can be easily
viewed and addressed.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see the video [Design Management (GitLab 12.2)](https://www.youtube.com/watch?v=CCMtCqdK_aM).

## Requirements

Design Management requires
[Large File Storage (LFS)](../../../administration/lfs/manage_large_binaries_with_git_lfs.md)
to be enabled:

- For GitLab.com, LFS is already enabled.
- For self-managed instances, a GitLab administrator must have
  [enabled LFS globally](../../../administration/lfs/lfs_administration.md).
- For both GitLab.com and self-managed instances: LFS must be enabled for the project itself.
  If enabled globally, LFS will be enabled by default to all projects. To enable LFS on the
  project level, navigate to your project's **Settings > General**, expand **Visibility, project features, permissions**
  and enable **Git Large File Storage**.

Design Management requires that projects are using
[hashed storage](../../../administration/repository_storage_types.md#hashed-storage)
(the default storage type since v10.0).

### Feature Flags

- Reference Parsing

  Designs support short references in Markdown, but this needs to be enabled by setting
  the `:design_management_reference_filter_gfm_pipeline` feature flag.

## Limitations

- Files uploaded must have a file extension of either `png`, `jpg`, `jpeg`, `gif`, `bmp`, `tiff` or `ico`.
  The [`svg` extension is not yet supported](https://gitlab.com/gitlab-org/gitlab/issues/12771).
- Design uploads are limited to 10 files at a time.
- Design Management data
  [isn't deleted when a project is destroyed](https://gitlab.com/gitlab-org/gitlab/issues/13429) yet.
- Design Management data [won't be moved](https://gitlab.com/gitlab-org/gitlab/issues/13426)
  when an issue is moved, nor [deleted](https://gitlab.com/gitlab-org/gitlab/issues/13427)
  when an issue is deleted.
- From GitLab 12.7, Design Management data [can be replicated](../../../administration/geo/replication/datatypes.md#limitations-on-replicationverification)
  by Geo but [not verified](https://gitlab.com/gitlab-org/gitlab/issues/32467).
- Only the latest version of the designs can be deleted.
- Deleted designs cannot be recovered but you can see them on previous designs versions.

## The Design Management page

Navigate to the **Design Management** page from any issue by clicking the **Designs** tab:

![Designs tab](img/design_management_v12_3.png)

## Adding designs

To upload design images, click the **Upload Designs** button and select images to upload.

Designs with the same filename as an existing uploaded design will create a new version
of the design, and will replace the previous version.

Designs cannot be added if the issue has been moved, or its
[discussion is locked](../../discussions/#lock-discussions).

### Skipped designs

Designs with the same filename as an existing uploaded design _and_ whose content has not changed will be skipped.
This means that no new version of the design will be created. When designs are skipped, you will be made aware via a warning
message on the Issue.

## Viewing designs

Images on the Design Management page can be enlarged by clicking on them.
You can navigate through designs by clicking on the navigation buttons on the
top-right corner or with <kbd>Left</kbd>/<kbd>Right</kbd> keyboard buttons.

The number of comments on a design — if any — is listed to the right
of the design filename. Clicking on this number enlarges the design
just like clicking anywhere else on the design.
When a design is added or modified, an icon is displayed on the item
to help summarize changes between versions.

| Indicator | Example |
| --------- | ------- |
| Comments | ![Comments Icon](img/design_comments_v12_3.png) |
| Modified (in the selected version) | ![Design Modified](img/design_modified_v12_3.png) |
| Added (in the selected version) | ![Design Added](img/design_added_v12_3.png) |

### Exploring designs by zooming

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/13217) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.7.

Designs can be explored in greater detail by zooming in and out of the image. Control the amount of zoom with the `+` and `-` buttons at the bottom of the image. While zoomed, you can still [add new annotations](#adding-annotations-to-designs) to the image, and see any existing ones.

![Design zooming](img/design_zooming_v12_7.png)

## Deleting designs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/11089) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.4.

There are two ways to delete designs: manually delete them
individually, or select a few of them to delete at once,
as shown below.

To delete a single design, click it to view it enlarged,
then click the trash icon on the top right corner and confirm
the deletion by clicking the **Delete** button on the modal window:

![Confirm design deletion](img/confirm_design_deletion_v12_4.png)

To delete multiple designs at once, on the design's list view,
first select the designs you want to delete:

![Select designs](img/select_designs_v12_4.png)

Once selected, click the **Delete selected** button to confirm the deletion:

![Delete multiple designs](img/delete_multiple_designs_v12_4.png)

**Note:**
Only the latest version of the designs can be deleted.
Deleted designs are not permanently lost; they can be
viewed by browsing previous versions.

## Adding annotations to designs

When a design is uploaded, you can add annotations by clicking on
the image on the exact location you'd like to add the note to.
A badge is added to the image identifying the annotation, from
which you can start a new discussion:

![Starting a new discussion on design](img/adding_note_to_design_1.png)

From GitLab 12.8 on, when you are starting a new discussion, you can adjust the badge's position by
dragging it around the image.

Different discussions have different badge numbers:

![Discussions on design annotations](img/adding_note_to_design_2.png)

From GitLab 12.5 on, new annotations will be outputted to the issue activity,
so that everyone involved can participate in the discussion.

## References

GitLab Flavored Markdown supports references to designs. The syntax for this is:

  `#123[file.jpg]` - the issue reference, with the filename in square braces

File names may contain a variety of odd characters, so two escaping mechanisms are supported:

### Quoting

File names may be quoted with double quotation marks, eg:

  `#123["file.jpg"]`

This is useful if, for instance, your filename has square braces in its name. In this scheme, all
double quotation marks in the file name need to be escaped with backslashes, and backslashes need
to be escaped likewise:

  `#123["with with \"quote\" marks and a backslash \\.png"]`

### Base64 Encoding

In the case of file names that include HTML elements, you will need to escape these names to avoid
them being processed as HTML literals. To do this, we support base64 encoding, eg.

  The file `<a>.jpg` can be referenced as `#123[base64:PGE+LmpwZwo=]`

Obviously we would advise against using such filenames.
