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
[Large File Storage (LFS)](../../../workflow/lfs/manage_large_binaries_with_git_lfs.md)
to be enabled:

- For GitLab.com, LFS is already enabled.
- For self-managed instances, a GitLab administrator must have
  [enabled LFS globally](../../../workflow/lfs/lfs_administration.md).
- For both GitLab.com and self-managed instances: LFS must be enabled for the project itself.
  If enabled globally, LFS will be enabled by default to all projects. To enable LFS on the
  project level, navigate to your project's **Settings > General**, expand **Visibility, project features, permissions**
  and enable **Git Large File Storage**.

## Limitations

- Files uploaded must have a file extension of either `png`, `jpg`, `jpeg`, `gif`, `bmp`, `tiff` or `ico`.
  The [`svg` extension is not yet supported](https://gitlab.com/gitlab-org/gitlab-ee/issues/12771).
- Design uploads are limited to 10 files at a time.
- [Designs cannot yet be deleted](https://gitlab.com/gitlab-org/gitlab-ee/issues/11089).
- Design Management is
  [not yet supported in the project export](https://gitlab.com/gitlab-org/gitlab-ee/issues/11090).
- Design Management data
  [isn't deleted when a project is destroyed](https://gitlab.com/gitlab-org/gitlab-ee/issues/13429) yet.
- Design Management data [won't be moved](https://gitlab.com/gitlab-org/gitlab-ee/issues/13426)
  when an issue is moved, nor [deleted](https://gitlab.com/gitlab-org/gitlab-ee/issues/13427)
  when an issue is deleted.
- Design Management
  [isn't supported by Geo](https://gitlab.com/groups/gitlab-org/-/epics/1633) yet.

## The Design Management page

Navigate to the **Design Management** page from any issue by clicking the **Designs** tab:

![Designs tab](img/design_management_v12_2.png)

## Adding designs

To upload design images, click the **Upload Designs** button and select images to upload.

Designs with the same filename as an existing uploaded design will create a new version
of the design, and will replace the previous version.

## Viewing designs

Images on the Design Management page can be enlarged by clicking on them.

## Adding annotations to designs

When a design image is displayed, you can add annotations to it by clicking on
the image. A badge is added to the image and a form is displayed to start a new
discussion. For example:

![Starting a new discussion on design](img/adding_note_to_design_1.png)

When submitted, the form saves a badge linked to the discussion on the image. Different discussions have different badge numbers. For example:

![Discussions on design annotations](img/adding_note_to_design_2.png)
