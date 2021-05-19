---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Shared files

Historically, GitLab supported storing files that could be accessed from multiple application
servers in `shared/`, using a shared storage solution like NFS. Although this is still an option for
some GitLab installations, it must not be the only file storage option for a given feature. This is
because [cloud-native GitLab installations do not support it](architecture.md#adapting-existing-and-introducing-new-components).

Our [uploads documentation](uploads.md) describes how to handle file storage in
such a way that it supports both options: direct disk access and object storage.
