# Working with the GitHub importer

In GitLab 10.2 a new version of the GitHub importer was introduced. This new
importer performs its work in parallel using Sidekiq, greatly reducing the time
necessary to import GitHub projects into a GitLab instance.

The GitHub importer offers two different types of importers: a sequential
importer and a parallel importer. The Rake task `import:github` uses the
sequential importer, while everything else uses the parallel importer. The
difference between these two importers is quite simple: the sequential importer
does all work in a single thread, making it more useful for debugging purposes
or Rake tasks. The parallel importer on the other hand uses Sidekiq.

## Requirements

* GitLab CE 10.2.0 or newer.
* Sidekiq workers that process the `github_importer` and
  `github_importer_advance_stage` queues (this is enabled by default).
* Octokit (used for interacting with the GitHub API)

## Code structure

The importer's codebase is broken up into the following directories:

* `lib/gitlab/github_import`: this directory contains most of the code such as
  the classes used for importing resources.
* `app/workers/gitlab/github_import`: this directory contains the Sidekiq
  workers.
* `app/workers/concerns/gitlab/github_import`: this directory contains a few
  modules reused by the various Sidekiq workers.

## Architecture overview

When a GitHub project is imported we schedule and execute a job for the
`RepositoryImportworker` worker as all other importers. However, unlike other
importers we don't immediately perform the work necessary. Instead work is
divided into separate stages, with each stage consisting out of a set of Sidekiq
jobs that are executed. Between every stage a job is scheduled that periodically
checks if all work of the current stage is completed, advancing the import
process to the next stage when this is the case. The worker handling this is
called `Gitlab::GithubImport::AdvanceStageWorker`.

## Stages

### 1. RepositoryImportWorker

This worker will kick off the import process by simply scheduling a job for the
next worker.

### 2. Stage::ImportRepositoryWorker

This worker will import the repository and wiki, scheduling the next stage when
done.

### 3. Stage::ImportBaseDataWorker

This worker will import base data such as labels, milestones, and releases. This
work is done in a single thread since it can be performed fast enough that we
don't need to perform this work in parallel.

### 4. Stage::ImportPullRequestsWorker

This worker will import all pull requests. For every pull request a job for the
`Gitlab::GithubImport::ImportPullRequestWorker` worker is scheduled.

### 5. Stage::ImportIssuesAndDiffNotesWorker

This worker will import all issues and pull request comments. For every issue we
schedule a job for the `Gitlab::GithubImport::ImportIssueWorker` worker. For
pull request comments we instead schedule jobs for the
`Gitlab::GithubImport::DiffNoteImporter` worker.

This worker processes both issues and diff notes in parallel so we don't need to
schedule a separate stage and wait for the previous one to complete.

Issues are imported separately from pull requests because only the "issues" API
includes labels for both issue and pull requests. Importing issues and setting
label links in the same worker removes the need for performing a separate crawl
through the API data, reducing the number of API calls necessary to import a
project.

### 6. Stage::ImportNotesWorker

This worker imports regular comments for both issues and pull requests. For
every comment we schedule a job for the
`Gitlab::GithubImport::ImportNoteWorker` worker.

Regular comments have to be imported at the end since the GitHub API used
returns comments for both issues and pull requests. This means we have to wait
for all issues and pull requests to be imported before we can import regular
comments.

### 7. Stage::FinishImportWorker

This worker will wrap up the import process by performing some housekeeping
(such as flushing any caches) and by marking the import as completed.

## Advancing stages

Advancing stages is done in one of two ways:

1. Scheduling the worker for the next stage directly.
2. Scheduling a job for `Gitlab::GithubImport::AdvanceStageWorker` which will
   advance the stage when all work of the current stage has been completed.

The first approach should only be used by workers that perform all their work in
a single thread, while `AdvanceStageWorker` should be used for everything else.

The way `AdvanceStageWorker` works is fairly simple. When scheduling a job it
will be given a project ID, a list of Redis keys, and the name of the next
stage. The Redis keys (produced by `Gitlab::JobWaiter`) are used to check if the
currently running stage has been completed or not. If the stage has not yet been
completed `AdvanceStageWorker` will reschedule itself. Once a stage finishes
`AdvanceStageworker` will refresh the import JID (more on this below) and
schedule the worker of the next stage.

To reduce the number of `AdvanceStageWorker` jobs scheduled this worker will
briefly wait for jobs to complete before deciding what the next action should
be. For small projects this may slow down the import process a bit, but it will
also reduce pressure on the system as a whole.

## Refreshing import JIDs

GitLab includes a worker called `StuckImportJobsWorker` that will periodically
run and mark project imports as failed if they have been running for more than
15 hours. For GitHub projects this poses a bit of a problem: importing large
projects could take several hours depending on how often we hit the GitHub rate
limit (more on this below), but we don't want `StuckImportJobsWorker` to mark
our import as failed because of this.

To prevent this from happening we periodically refresh the expiration time of
the import process. This works by storing the JID of the import job in the
database, then refreshing this JID's TTL at various stages throughout the import
process. This is done by calling `Project#refresh_import_jid_expiration`. By
refreshing this TTL we can ensure our import does not get marked as failed so
long we're still performing work.

## GitHub rate limit

GitHub has a rate limit of 5 000 API calls per hour. The number of requests
necessary to import a project is largely dominated by the number of unique users
involved in a project (e.g. issue authors). Other data such as issue pages
and comments typically only requires a few dozen requests to import.  This is
because we need the Email address of users in order to map them to GitLab users.

We handle this by doing the following:

1. Once we hit the rate limit all jobs will automatically reschedule themselves
   in such a way that they are not executed until the rate limit has been reset.
2. We cache the mapping of GitHub users to GitLab users in Redis.

More information on user caching can be found below.

## Caching user lookups

When mapping GitHub users to GitLab users we need to (in the worst case)
perform:

1. One API call to get the user's Email address.
2. Two database queries to see if a corresponding GitLab user exists. One query
   will try to find the user based on the GitHub user ID, while the second query
   is used to find the user using their GitHub Email address.

Because this process is quite expensive we cache the result of these lookups in
Redis. For every user looked up we store three keys:

1. A Redis key mapping GitHub usernames to their Email addresses.
2. A Redis key mapping a GitHub Email addresses to a GitLab user ID.
3. A Redis key mapping a GitHub user ID to GitLab user ID.

There are two types of lookups we cache:

1. A positive lookup, meaning we found a GitLab user ID.
2. A negative lookup, meaning we didn't find a GitLab user ID. Caching this
   prevents us from performing the same work for users that we know don't exist
   in our GitLab database.

The expiration time of these keys is 24 hours. When retrieving the cache of a
positive lookups we refresh the TTL automatically. The TTL of false lookups is
never refreshed.

Because of this caching layer it's possible newly registered GitLab accounts
won't be linked to their corresponding GitHub accounts. This however will sort
itself out once the cached keys expire.

The user cache lookup is shared across projects. This means that the more
projects get imported the fewer GitHub API calls will be needed.

The code for this resides in:

* `lib/gitlab/github_import/user_finder.rb`
* `lib/gitlab/github_import/caching.rb`

## Mapping labels and milestones

To reduce pressure on the database we do not query it when setting labels and
milestones on issues and merge requests. Instead we cache this data when we
import labels and milestones, then we reuse this cache when assigning them to
issues/merge requests. Similar to the user lookups these cache keys are expired
automatically after 24 hours of not being used.

Unlike the user lookup caches these label and milestone caches are scoped to the
project that is being imported.

The code for this resides in:

* `lib/gitlab/github_import/label_finder.rb`
* `lib/gitlab/github_import/milestone_finder.rb`
* `lib/gitlab/github_import/caching.rb`
