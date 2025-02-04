---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Bitbucket Cloud importer developer documentation
---

## Prerequisites

You must be authenticated with Bitbucket:

- If you use GitLab Development Kit (GDK), see [Set up Bitbucket authentication on GDK](#set-up-bitbucket-authentication-on-gdk).
- Otherwise, see [Bitbucket OmniAuth provider](../integration/bitbucket.md#use-bitbucket-as-an-oauth-20-authentication-provider) instructions.

## Code structure

The importer's codebase is broken up into the following directories:

- `lib/gitlab/bitbucket_import`: this directory contains most of the code such as
  the classes used for importing resources.
- `app/workers/gitlab/bitbucket_import`: this directory contains the Sidekiq
  workers.

## Architecture overview

When a Bitbucket Cloud project is imported, work is
divided into separate stages, with each stage consisting of a set of Sidekiq
jobs that are executed. Between every stage, a job is scheduled that periodically
checks if all work of the current stage is completed, advancing the import
process to the next stage when this is the case. The worker handling this is
called `Gitlab::BitbucketImport::AdvanceStageWorker`.

## Stages

### 1. Stage::ImportRepositoryWorker

This worker imports the repository, wiki and labels, scheduling the next stage when
done.

### 2. Stage::ImportUsersWorker

This worker imports members of the source Bitbucket Cloud workspace.

### 3. Stage::ImportPullRequestsWorker

This worker imports all pull requests. For every pull request, a job for the
`Gitlab::BitbucketImport::ImportPullRequestWorker` worker is scheduled.

### 4. Stage::ImportPullRequestsNotesWorker

This worker imports notes (comments) for all merge requests.

For every merge request, a job for the `Gitlab::BitbucketImport::ImportPullRequestNotesWorker` worker is scheduled which imports all notes for the merge request.

### 5. Stage::ImportIssuesWorker

This worker imports all issues. For every issue, a job for the
`Gitlab::BitbucketImport::ImportIssueWorker` worker is scheduled.

### 6. Stage::ImportIssuesNotesWorker

This worker imports notes (comments) for all issues.

For every issue, a job for the `Gitlab::BitbucketImport::ImportIssueNotesWorker` worker is scheduled which imports all notes for the issue.

### 7. Stage::FinishImportWorker

This worker completes the import process by performing some housekeeping
such as marking the import as completed.

## Backoff and retry

In order to handle rate limiting, requests are wrapped with `Bitbucket::ExponentialBackoff`.
This wrapper catches rate limit errors and retries after a delay up to three times.

## Set up Bitbucket authentication on GDK

To set up Bitbucket authentication on GDK:

1. Follow the documentation up to step 9 to create
   [Bitbucket OAuth credentials](../integration/bitbucket.md#use-bitbucket-as-an-oauth-20-authentication-provider).
1. Add the credentials to `config/gitlab.yml`:

   ```yaml
   # config/gitlab.yml

   development:
     <<: *base
     omniauth:
       providers:
       - { name: 'bitbucket',
           app_id: '...',
           app_secret: '...' }
   ```

1. Run `gdk restart`.
1. Sign in to your GDK, go to `<gdk-url>/-/profile/account`, and connect Bitbucket.
