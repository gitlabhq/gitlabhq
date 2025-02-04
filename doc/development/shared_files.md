---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Shared files
---

Historically, GitLab supported storing files that could be accessed from multiple application
servers in `shared/`, using a shared storage solution like NFS. Although this is still an option for
some GitLab installations, it must not be the only file storage option for a given feature. This is
because [cloud-native GitLab installations do not support it](architecture.md#adapting-existing-and-introducing-new-components).

Our [uploads documentation](uploads/_index.md) describes how to handle file storage in
such a way that it supports both options: direct disk access and object storage.
