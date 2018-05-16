# Allow maintainer pushes for merge requests across forks

> [Introduced][ce-17395] in GitLab 10.6.

This feature is available for merge requests across forked projects that are
publicly accessible. It makes it easier for maintainers of projects to
collaborate on merge requests across forks.

When enabled for a merge request, members with merge access to the target
branch of the project will be granted write permissions to the source branch
of the merge request.

The feature can only be enabled by users who already have push access to the
source project, and only lasts while the merge request is open.

Enable this functionality while creating a merge request:

![Enable maintainer edits](./img/allow_maintainer_push.png)
