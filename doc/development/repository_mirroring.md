---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Repository mirroring
---

## Deep Dive

<!-- vale gitlab_base.Spelling = NO -->

In December 2018, Tiago Botelho hosted a Deep Dive (GitLab team members only: `https://gitlab.com/gitlab-org/create-stage/-/issues/1`)
on the GitLab [Pull Repository Mirroring functionality](../user/project/repository/mirror/pull.md)
to share his domain specific knowledge with anyone who may work in this part of the
codebase in the future. You can find the <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [recording on YouTube](https://www.youtube.com/watch?v=sSZq0fpdY-Y),
and the slides in [PDF](https://gitlab.com/gitlab-org/create-stage/uploads/8693404888a941fd851f8a8ecdec9675/Gitlab_Create_-_Pull_Mirroring_Deep_Dive.pdf).
Specific details may have changed since then, but it should still serve as a good introduction.

<!-- vale gitlab_base.Spelling = YES -->

## Explanation of mirroring process

GitLab performs these steps when an
[API call](../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)
triggers a pull mirror. Scheduled mirror updates are similar, but do not start with the API call:

1. The request originates from an API call, and triggers the `start_pull_mirroring_service` in
   [`project_mirror.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/project_mirror.rb).
1. The pull mirroring service
   ([`start_pull_mirroring_service.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/start_pull_mirroring_service.rb)) starts. It updates the project state, and forces the job to start immediately.
1. The project import state is updated, and then triggers an `update_all_mirrors_worker` in
   [`project_import_state.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/ee/project_import_state.rb#L170).
1. The update all mirrors worker
   ([`update_all_mirrors_worker.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/update_all_mirrors_worker.rb))
   attempts to avoid stampedes by calling the `project_import_schedule` worker.
1. The project import schedule worker
   ([`project_import_schedule_worker.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/project_import_schedule_worker.rb#L21)) updates the state of the project, and
   starts a Ruby `state_machine` to manage the import transition process.
1. While updating the project state,
   [this call in `project.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/ee/project.rb#L426)
   starts the `repository_update_mirror` worker.
1. The Sidekiq background mirror workers
   ([`repository_update_mirror_worker.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/repository_update_mirror_worker.rb)) track the state of the mirroring task, and
   provide good error state information. Processes can hang here, because this step manages the Git steps.
1. The update mirror service
   ([`update_mirror_service.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/projects/update_mirror_service.rb))
   performs the Git operations.

The import and mirror update processes are complete after the update mirror service step. However, depending on the changes included, more tasks (such as pipelines for commits) can be triggered.
