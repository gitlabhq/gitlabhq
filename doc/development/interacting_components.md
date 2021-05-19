---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Developing against interacting components or features

It's not uncommon that a single code change can reflect and interact with multiple parts of GitLab
codebase. Furthermore, an existing feature might have an underlying integration or behavior that
might go unnoticed even by reviewers and maintainers.

The goal of this section is to briefly list interacting pieces to think about
when making _backend_ changes that might involve multiple features or [components](architecture.md#components).

## Uploads

GitLab supports uploads to [object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/). That means every feature and
change that affects uploads should also be tested against [object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/),
which is _not_ enabled by default in [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit).

When working on a related feature, make sure to enable and test it
against [MinIO](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/object_storage.md).

See also [File Storage in GitLab](file_storage.md).

## Merge requests

### Forks

GitLab supports a great amount of features for [merge requests](../user/project/merge_requests/index.md). One
of them is the ability to create merge requests from and to [forks](../user/project/working_with_projects.md#fork-a-project),
which should also be highly considered and tested upon development phase.
