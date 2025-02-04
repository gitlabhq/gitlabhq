---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Bitbucket Server importer developer documentation
---

## Prerequisites

To test imports, you need a Bitbucket Server instance running locally. For information on running a local instance, see
[these instructions](https://gitlab.com/gitlab-org/foundations/import-and-integrate/team/-/blob/main/integrations/bitbucket_server.md).

## Code structure

The importer's codebase is broken up into the following directories:

- `lib/gitlab/bitbucket_server_import`: this directory contains most of the code such as
  the classes used for importing resources.
- `app/workers/gitlab/bitbucket_server_import`: this directory contains the Sidekiq
  workers.

## How imports advance

When a Bitbucket Server project is imported, work is divided into separate stages, with
each stage consisting of a set of Sidekiq jobs that are executed.

Between every stage, a job called `Gitlab::BitbucketServerImport::AdvanceStageWorker`
is scheduled that periodically checks if all work of the current stage is completed. If
all the work is complete, the job advances the import process to the next stage.

## Stages

### 1. Stage::ImportRepositoryWorker

This worker imports the repository and schedules the next stage when
done.

### 2. Stage::ImportPullRequestsWorker

This worker imports all pull requests. For every pull request, a job for the
`Gitlab::BitbucketImport::ImportPullRequestWorker` worker is scheduled.

Bitbucket Server keeps tracks of references for open pull requests in
`refs/heads/pull-requests`, but closed and merged requests get moved
into hidden internal refs under `stash-refs/pull-requests`.

As a result, they are not fetched by default. To prevent merge requests from not having
commits and therefore having empty diffs, we fetch affected source and target
commits from the server before importing the pull request.
We save the fetched commits as refs so that Git doesn't remove them, which can happen
if they are unused.
Source commits are saved as `#{commit}:refs/merge-requests/#{pull_request.iid}/head`
and target commits are saved as `#{commit}:refs/keep-around/#{commit}`.

When creating a pull request, we need to match Bitbucket users with GitLab users for
the author and reviewers. Whenever a matching user is found, the GitLab user ID is cached
for 24 hours so that it doesn't have to be searched for again.

### 3. Stage::ImportNotesWorker

This worker imports notes (comments) for all merge requests.

For every merge request, a job for the `Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker`
worker is scheduled which imports all standalone comments, inline comments, merge events, and
approved events for the merge request.

### 4. Stage::ImportLfsObjectsWorker

Imports LFS objects from the source project by scheduling a
`Gitlab::BitbucketServerImport::ImportLfsObjectsWorker` job for every LFS object.

### 5. Stage::FinishImportWorker

This worker completes the import process by performing some housekeeping
such as marking the import as completed.

## Pull request mentions

Pull request descriptions and notes can contain @mentions to users. If a user with the
same email does not exist on GitLab, this can lead to incorrect users being tagged.

To get around this, we build a cache containing all users who have access to the Bitbucket
project and then convert mentions in pull request descriptions and notes.

## Backoff and retry

In order to handle rate limiting, requests are wrapped with `BitbucketServer::RetryWithDelay`.
This wrapper checks if the response is rate limited and retries once after the delay specified in the response headers.
