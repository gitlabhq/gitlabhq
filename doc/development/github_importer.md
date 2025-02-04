---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitHub importer developer documentation
---

The GitHub importer is a parallel importer that uses Sidekiq.

## Prerequisites

- Sidekiq workers that process the `github_importer` and `github_importer_advance_stage` queues (enabled by default).
- Octokit (used for interacting with the GitHub API).

## Code structure

The importer's codebase is broken up into the following directories:

- `lib/gitlab/github_import`: this directory contains most of the code such as
  the classes used for importing resources.
- `app/workers/gitlab/github_import`: this directory contains the Sidekiq
  workers.
- `app/workers/concerns/gitlab/github_import`: this directory contains a few
  modules reused by the various Sidekiq workers.

## Architecture overview

When a GitHub project is imported, work is divided into separate stages, with
each stage consisting of a set of Sidekiq jobs that are executed. Between
every stage a job is scheduled that periodically checks if all work of the
current stage is completed, advancing the import process to the next stage when
this is the case. The worker handling this is called
`Gitlab::GithubImport::AdvanceStageWorker`.

- An import is initiated via an API request to
  [`POST /import/github`](https://gitlab.com/gitlab-org/gitlab/-/blob/18878b90991e2d478f3c79a68013b156d83b5db8/lib/api/import_github.rb#L42)
- The API endpoint calls [`Import::GitHubService`](https://gitlab.com/gitlab-org/gitlab/-/blob/18878b90991e2d478f3c79a68013b156d83b5db8/lib/api/import_github.rb#L43).
- Which calls
  [`Gitlab::LegacyGithubImport::ProjectCreator`](https://gitlab.com/gitlab-org/gitlab/-/blob/18878b90991e2d478f3c79a68013b156d83b5db8/app/services/import/github_service.rb#L31-38)
- Which calls
  [`Projects::CreateService`](https://gitlab.com/gitlab-org/gitlab/-/blob/18878b90991e2d478f3c79a68013b156d83b5db8/lib/gitlab/legacy_github_import/project_creator.rb#L30)
- Which calls
  [`@project.import_state.schedule`](https://gitlab.com/gitlab-org/gitlab/-/blob/18878b90991e2d478f3c79a68013b156d83b5db8/app/services/projects/create_service.rb#L325)
- Which calls
  [`project.add_import_job`](https://gitlab.com/gitlab-org/gitlab/-/blob/1d154fa0b9121566aebf3afe3d28808d025cc5af/app/models/project_import_state.rb#L43)
- Which calls
  [`RepositoryImportWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/1d154fa0b9121566aebf3afe3d28808d025cc5af/app/models/project.rb#L1105)

## Stages

### 1. RepositoryImportWorker

This worker calls
[`Projects::ImportService.new.execute`](https://gitlab.com/gitlab-org/gitlab/-/blob/651e6a0139396ed6fa9ce73e27587ca88f9f4d96/app/workers/repository_import_worker.rb#L23-24),
which calls
[`importer.execute`](https://gitlab.com/gitlab-org/gitlab/-/blob/fcccaaac8d62191ad233cebeffc67111145b1ad7/app/services/projects/import_service.rb#L143).

In this context, `importer` is an instance of
[`Gitlab::ImportSources.importer(project.import_type)`](https://gitlab.com/gitlab-org/gitlab/-/blob/fcccaaac8d62191ad233cebeffc67111145b1ad7/app/services/projects/import_service.rb#L149),
which for `github` import types maps to
[`ParallelImporter`](https://gitlab.com/gitlab-org/gitlab/-/blob/651e6a0139396ed6fa9ce73e27587ca88f9f4d96/lib/gitlab/import_sources.rb#L13).

`ParallelImporter` schedules a job for the next worker.

### 2. Stage::ImportRepositoryWorker

This worker imports the repository and wiki, scheduling the next stage when
done.

### 3. Stage::ImportBaseDataWorker

This worker imports base data such as labels, milestones, and releases. This
work is done in a single thread because it can be performed fast enough that we
don't need to perform this work in parallel.

### 4. Stage::ImportPullRequestsWorker

This worker imports all pull requests. For every pull request a job for the
`Gitlab::GithubImport::ImportPullRequestWorker` worker is scheduled.

### 5. Stage::ImportCollaboratorsWorker

This worker imports only direct repository collaborators who are not outside collaborators.
For every collaborator, we schedule a job for the `Gitlab::GithubImport::ImportCollaboratorWorker` worker.

NOTE:
This stage is optional (controlled by `Gitlab::GithubImport::Settings`) and is selected by default.

### 6. Stage::ImportIssuesAndDiffNotesWorker

This worker imports all issues and pull request comments. For every issue, we
schedule a job for the `Gitlab::GithubImport::ImportIssueWorker` worker. For
pull request comments, we instead schedule jobs for the
`Gitlab::GithubImport::DiffNoteImporter` worker.

This worker processes both issues and diff notes in parallel so we don't need to
schedule a separate stage and wait for the previous one to complete.

Issues are imported separately from pull requests because only the "issues" API
includes labels for both issue and pull requests. Importing issues and setting
label links in the same worker removes the need for performing a separate crawl
through the API data, reducing the number of API calls necessary to import a
project.

### 7. Stage::ImportIssueEventsWorker

This worker imports all issues and pull request events. For every event, we
schedule a job for the `Gitlab::GithubImport::ImportIssueEventWorker` worker.

We can import both issues and pull request events by single stage because of a specific aspect of the GitHub API. It looks like that under the hood, issues and pull requests
GitHub are stored in a single table. Therefore, they have globally-unique IDs and so:

- Every pull request is an issue.
- Issues aren't pull requests.

Therefore, both issues and pull requests have a common API for most related things.

To facilitate the import of `pull request review requests` using the timeline events endpoint,
events must be processed sequentially. Given that import workers do not execute in a guaranteed order,
the `pull request review requests` events are initially placed in a Redis ordered list. Subsequently, they are consumed
in sequence by the `Gitlab::GithubImport::ReplayEventsWorker`.

### 8. Stage::ImportAttachmentsWorker

This worker imports note attachments that are linked inside Markdown.
For each entity with Markdown text in the project, we schedule a job of:

- `Gitlab::GithubImport::Importer::Attachments::ReleasesImporter` for every release.
- `Gitlab::GithubImport::Importer::Attachments::NotesImporter` for every note.
- `Gitlab::GithubImport::Importer::Attachments::IssuesImporter` for every issue.
- `Gitlab::GithubImport::Importer::Attachments::MergeRequestsImporter` for every merge request.

Each job:

1. Iterates over all attachment links inside of a specific record.
1. Downloads the attachment.
1. Replaces the old link with a newly-generated link to GitLab.

NOTE:
It's an optional stage that could consume significant extra import time (controlled by `Gitlab::GithubImport::Settings`).

### 9. Stage::ImportProtectedBranchesWorker

This worker imports protected branch rules.
For every rule that exists on GitHub, we schedule a job of
`Gitlab::GithubImport::ImportProtectedBranchWorker`.

Each job compares the branch protection rules from GitHub and GitLab and applies
the strictest of the rules to the branches in GitLab.

### 10. Stage::FinishImportWorker

This worker completes the import process by performing some housekeeping
(such as flushing any caches) and by marking the import as completed.

## Advancing stages

Advancing stages is done in one of two ways:

- Scheduling the worker for the next stage directly.
- Scheduling a job for `Gitlab::GithubImport::AdvanceStageWorker` which will
  advance the stage when all work of the current stage has been completed.

The first approach should only be used by workers that perform all their work in
a single thread, while `AdvanceStageWorker` should be used for everything else.

An example of the first approach is how `ImportBaseDataWorker` invokes `PullRequestWorker` [directly](https://gitlab.com/gitlab-org/gitlab/-/blob/e047d64057e24d9183bd0e18e22f1c1eee8a4e92/app/workers/gitlab/github_import/stage/import_base_data_worker.rb#L29-29).

An example of the second approach is how `PullRequestsWorker` invokes the `AdvanceStageWorker` when its own work has been [completed](https://gitlab.com/gitlab-org/gitlab/-/blob/e047d64057e24d9183bd0e18e22f1c1eee8a4e92/app/workers/gitlab/github_import/stage/import_pull_requests_worker.rb#L29).

When you schedule a job, `AdvanceStageWorker`
is given a project ID, a list of Redis keys, and the name of the next
stage. The Redis keys (produced by `Gitlab::JobWaiter`) are used to check if the
running stage has been completed or not. If the stage has not yet been
completed `AdvanceStageWorker` reschedules itself. After a stage finishes,
or if more jobs have been finished after the last invocation.
`AdvanceStageworker` refreshes the import JID (more on this below) and
schedule the worker of the next stage.

To reduce the number of `AdvanceStageWorker` jobs scheduled this worker
briefly waits for jobs to complete before deciding what the next action should
be. For small projects, this may slow down the import process a bit, but it
also reduces pressure on the system as a whole.

## Refreshing import job IDs

GitLab includes a worker called `Gitlab::Import::StuckProjectImportJobsWorker`
that periodically runs and marks project imports as failed if they have not been
refreshed for more than 24 hours. For GitHub projects, this poses a bit of a
problem: importing large projects could take several days depending on how
often we hit the GitHub rate limit (more on this below), but we don't want
`Gitlab::Import::StuckProjectImportJobsWorker` to mark our import as failed because of this.

To prevent this from happening we periodically refresh the expiration time of
the import. This works by storing the JID of the import job in the
database, then refreshing this JID TTL at various stages throughout the import
process. This is done either by calling `ProjectImportState#refresh_jid_expiration`,
or by using the RefreshImportJidWorker and passing in the current worker's jid.
By refreshing this TTL we can ensure our import does not get marked as failed so
long as we're still performing work.

## GitHub rate limit

GitHub has a rate limit of 5,000 API calls per hour. The number of requests
necessary to import a project is largely dominated by the number of unique users
involved in a project (for example, issue authors), because we need the email address of users to map
them to GitLab users. Other data such as issue pages and comments typically only requires a few dozen requests to import.

We handle the rate limit by doing the following:

1. After we hit the rate limit, we automatically reschedule jobs in such a way that they are not executed until the rate
   limit has been reset.
1. We cache the mapping of GitHub users to GitLab users in Redis.

More information on user caching can be found below.

## Caching user lookups

When mapping GitHub users to GitLab users we need to (in the worst case)
perform:

1. One API call to get the user's Email address.
1. Two database queries to see if a corresponding GitLab user exists. One query
   tries to find the user based on the GitHub user ID, while the second query
   is used to find the user using their GitHub Email address.

To avoid mismatching users, the search by GitHub user ID is not done when importing from GitHub
Enterprise.

Because this process is quite expensive we cache the result of these lookups in
Redis. For every user looked up we store five keys:

- A Redis key mapping GitHub usernames to their Email addresses.
- A Redis key mapping a GitHub Email addresses to a GitLab user ID.
- A Redis key mapping a GitHub user ID to GitLab user ID.
- A Redis key mapping a GitHub username to an ETAG header.
- A Redis key indicating whether an email lookup has been done for a project.

We cache two types of lookups:

- A positive lookup, meaning we found a GitLab user ID.
- A negative lookup, meaning we didn't find a GitLab user ID. Caching this
  prevents us from performing the same work for users that we know don't exist
  in our GitLab database.

The expiration time of these keys is 24 hours. When retrieving the cache of a
positive lookup, we refresh the TTL automatically. The TTL of false lookups is
never refreshed.

If a lookup for email returns an empty or negative lookup, a [Conditional Request](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api?apiVersion=2022-11-28#use-conditional-requests-if-appropriate) is made with a cached ETAG in the header once for every project.
Conditional Requests do not count towards the GitHub API rate limit.

Because of this caching layer, it's possible newly registered GitLab accounts
aren't linked to their corresponding GitHub accounts. This, however, is resolved
after the cached keys expire or if a new project is imported.

The user cache lookup is shared across projects. This means that the greater the number of
projects that are imported, fewer GitHub API calls are needed.

The code for this resides in:

- `lib/gitlab/github_import/user_finder.rb`
- `lib/gitlab/github_import/caching.rb`

## Increasing Sidekiq interrupts

When a Sidekiq process shut downs, it waits for a period of time for running
jobs to finish before it then interrupts them. An interrupt terminates
the job and requeues it again. Our
[vendored `sidekiq-reliable-fetcher` gem](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/gems/sidekiq-reliable-fetch/README.md)
puts a limit of `3` interrupts before a job is no longer requeued and is
permanently terminated. Jobs that have been interrupted log a
`json.interrupted_count` in Kibana.

This limit offers protection from jobs that can never be completed in
the time between Sidekiq restarts.

For large imports, our GitHub [stage](#stages) workers (namespaced in
`Stage::`) take many hours to finish. By default, the import is at risk
of failing because of `sidekiq-reliable-fetcher` permanently stopping these
workers before they can complete.

Stage workers that pick up from where they left off when restarted can
increase the interrupt limit of `sidekiq-reliable-fetcher` to `20` by
calling `.resumes_work_when_interrupted!`:

```ruby
module Gitlab
  module GithubImport
    module Stage
      class MyWorker
        resumes_work_when_interrupted!

        # ...
      end
    end
  end
end
```

Stage workers that do not fully resume their work when restarted should
not call this method. For example, a worker that skips already imported
objects, but starts its loop from the beginning each time.

Examples of stage workers that do resume work fully are ones that
execute services that:

- [Continue paging](https://gitlab.com/gitlab-org/gitlab/-/blob/487521cc/lib/gitlab/github_import/parallel_scheduling.rb#L114-117)
  an endpoint from where it left off.
- [Continue their loop](https://gitlab.com/gitlab-org/gitlab/-/blob/487521cc26c1e2bdba4fc67c14478d2b2a5f2bfa/lib/gitlab/github_import/importer/attachments/issues_importer.rb#L27)
  from where it left off.

## `sidekiq_options dead: false`

Typically when a worker's retries are exhausted they go to the Sidekiq dead set
and can be retried by an instance admin.

`GithubImport::Queue` sets the Sidekiq worker option `dead: false` to prevent
this from happening to GitHub importer workers.

The reason is:

- The dead set has a max limit and if object importer workers (ones that include
  `ObjectImporter`) fail en masse they can spam the dead set and push other workers out.
- Stage workers (ones that include `StageMethods`)
  [fail the import](https://gitlab.com/gitlab-org/gitlab/-/blob/dd7cde8d6a28254b9c7aff27f9bf6b7be1ac7532/app/workers/concerns/gitlab/github_import/stage_methods.rb#L23)
  when their retries are exhausted, so a retry would be guaranteed to
  [be a no-op](https://gitlab.com/gitlab-org/gitlab/-/blob/dd7cde8d6a28254b9c7aff27f9bf6b7be1ac7532/app/workers/concerns/gitlab/github_import/stage_methods.rb#L55-63).

## Mapping labels and milestones

To reduce pressure on the database we do not query it when setting labels and
milestones on issues and merge requests. Instead, we cache this data when we
import labels and milestones, then we reuse this cache when assigning them to
issues/merge requests. Similar to the user lookups these cache keys are expired
automatically after 24 hours of not being used.

Unlike the user lookup caches, these label and milestone caches are scoped to the
project that is being imported.

The code for this resides in:

- `lib/gitlab/github_import/label_finder.rb`
- `lib/gitlab/github_import/milestone_finder.rb`
- `lib/gitlab/cache/import/caching.rb`

## Logs

The import progress can be checked in the `logs/importer.log` file. Each relevant import is logged
with `"import_type": "github"` and the `"project_id"`.

The last log entry reports the number of objects fetched and imported:

```json
{
  "message": "GitHub project import finished",
  "duration_s": 347.25,
  "objects_imported": {
    "fetched": {
      "diff_note": 93,
      "issue": 321,
      "note": 794,
      "pull_request": 108,
      "pull_request_merged_by": 92,
      "pull_request_review": 81
    },
    "imported": {
      "diff_note": 93,
      "issue": 321,
      "note": 794,
      "pull_request": 108,
      "pull_request_merged_by": 92,
      "pull_request_review": 81
    }
  },
  "import_source": "github",
  "project_id": 47,
  "import_stage": "Gitlab::GithubImport::Stage::FinishImportWorker"
}
```

## Metrics dashboards

To assess the GitHub importer health, the [GitHub importer dashboard](https://dashboards.gitlab.net/d/importers-github-importer/importers-github-importer)
provides information about the total number of objects fetched vs. imported over time.
