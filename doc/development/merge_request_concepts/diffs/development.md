---
stage: Create
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Developer documentation for the backend design and flow of merge request diffs."
title: Merge request diffs development guide
---

This document explains the backend design and flow of merge request diffs.
It should help contributors:

- Understand the code design.
- Identify areas for improvement through contribution.

It's intentional that it doesn't contain too many implementation details, as they
can change often. The code better explains these details. The components
mentioned here are the major parts of the application for how merge request diffs
are generated, stored, and returned to users.

NOTE:
This page is a living document. Update it accordingly when the parts
of the codebase touched in this document are changed or removed, or when new components
are added.

## Data model

Four main ActiveRecord models represent what we collectively refer to
as _diffs._ These database-backed records replicate data contained in the
project's Git repository, and are in part a cache against excessive access requests
to [Gitaly](../../gitaly.md). Additionally, they provide a logical place for:

- Calculated and retrieved metadata about the pieces of the diff.
- General class- and instance- based logic.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
erDiagram
  accTitle: Data model of diffs
  accDescr: Data model of the four ActiveRecord models used in diffs
  MergeRequest ||--|{ MergeRequestDiff: ""
  MergeRequestDiff |{--|{ MergeRequestDiffCommit: ""
  MergeRequestDiff |{--|| MergeRequestDiffDetail: ""
  MergeRequestDiff |{--|{ MergeRequestDiffFile: ""
  MergeRequestDiffCommit |{--|| MergeRequestDiffCommitUser: ""
```

### `MergeRequestDiff`

`MergeRequestDiff` is defined in `app/models/merge_request_diff.rb`. This
class holds metadata and context related to the diff resulting from a set of
commits. It defines methods that are the primary means for interacting with diff
contents, individual commits, and the files containing changes.

```ruby
#<MergeRequestDiff:0x00007fd1ed63b4d0
 id: 28,
 state: "collected",
 merge_request_id: 28,
 created_at: Tue, 06 Sep 2022 18:56:02.509469000 UTC +00:00,
 updated_at: Tue, 06 Sep 2022 18:56:02.754201000 UTC +00:00,
 base_commit_sha: "ae73cb07c9eeaf35924a10f713b364d32b2dd34f",
 real_size: "9",
 head_commit_sha: "bb5206fee213d983da88c47f9cf4cc6caf9c66dc",
 start_commit_sha: "0b4bc9a49b562e85de7cc9e834518ea6828729b9",
 commits_count: 6,
 external_diff: "diff-28",
 external_diff_store: 1,
 stored_externally: nil,
 files_count: 9,
 patch_id_sha: "d504412d5b6e6739647e752aff8e468dde093f2f",
 sorted: true,
 diff_type: "regular",
 verification_checksum: nil>
```

Diff content is usually accessed through this class. Logic is often applied
to diff, file, and commit content before it is returned to a user.

#### `MergeRequestDiff#commits_count`

When `MergeRequestDiff` is saved, associated `MergeRequestDiffCommit` records are
counted and cached into the `commits_count` column. This number displays on the
merge request page as the counter for the **Commits** tab.

If `MergeRequestDiffCommit` records are deleted, the counter doesn't update.

### `MergeRequestDiffCommit`

`MergeRequestDiffCommit` is defined in `app/models/merge_request_diff_commit.rb`.
This class corresponds to a single commit contained in its corresponding `MergeRequestDiff`,
and holds header information about the commit.

```ruby
#<MergeRequestDiffCommit:0x00007fd1dfc6c4c0
  authored_date: Wed, 06 Aug 2022 06:35:52.000000000 UTC +00:00,
  committed_date: Wed, 06 Aug 2022 06:35:52.000000000 UTC +00:00,
  merge_request_diff_id: 28,
  relative_order: 0,
  sha: "bb5206fee213d983da88c47f9cf4cc6caf9c66dc",
  message: "Feature conflcit added\n\nSigned-off-by: Sample User <sample.user@example.com>\n",
  trailers: {},
  commit_author_id: 19,
  committer_id: 19>
```

Every `MergeRequestDiffCommit` has a corresponding `MergeRequest::DiffCommitUser`
record it `:belongs_to`, in ActiveRecord parlance. These records are `:commit_author`
and `:committer`, and could be distinct individuals.

### `MergeRequest::DiffCommitUser`

`MergeRequest::DiffCommitUser` is defined in `app/models/merge_request/diff_commit_user.rb`.
It captures the `name` and `email` of a given commit, but contains no connection
itself to any `User` records.

```ruby
#<MergeRequest::DiffCommitUser:0x00007fd1dff7c930
  id: 19,
  name: "Sample User",
  email: "sample.user@example.com">
```

### `MergeRequestDiffFile`

`MergeRequestDiffFile` is defined in `app/models/merge_request_diff_file.rb`.
This record of this class represents the diff of a single file contained in the
`MergeRequestDiff`. It holds both meta and specific information about the file's
relationship to the change, such as:

- Whether it is added or renamed.
- Its ordering in the diff.
- The raw diff output itself.

#### External diff storage

By default, diff data of a `MergeRequestDiffFile` is stored in `diff` column in
the `merge_request_diff_files` table. On some installations, the table can grow
too large, so they're configured to store diffs on external storage to save space.
To configure it, see [Merge request diffs storage](../../../administration/merge_request_diffs.md).

When configured to use external storage:

- The `diff` column in the database is left `NULL`.
- The associated `MergeRequestDiff` record sets the `stored_externally` attribute
  to `true` on creation of `MergeRequestDiff`.

A cron job named `ScheduleMigrateExternalDiffsWorker` is also scheduled at
minute 15 of every hour. This migrates `diff` that are still stored in the
database to external storage.

### `MergeRequestDiffDetail`

`MergeRequestDiffDetail` is defined in `app/models/merge_request_diff_detail.rb`.
This class provides verification information for Geo replication, but otherwise
is not used for user-facing diffs.

```ruby
#<MergeRequestDiffFile:0x00007fd1ef7c9048
  merge_request_diff_id: 28,
  relative_order: 0,
  new_file: true,
  renamed_file: false,
  deleted_file: false,
  too_large: false,
  a_mode: "0",
  b_mode: "100644",
  new_path: "files/ruby/feature.rb",
  old_path: "files/ruby/feature.rb",
  diff:
   "@@ -0,0 +1,4 @@\n+# This file was changed in feature branch\n+# We put different code here to make merge conflict\n+class Conflict\n+end\n",
  binary: false,
  external_diff_offset: nil,
  external_diff_size: nil>
```

## Flow

These flowcharts should help explain the flow from the controllers down to the
models for different features. This page is not intended to document the entirety
of options for access and working with diffs, focusing solely on the most common.

### Generation of `MergeRequestDiff*` records

As explained above, we use database tables to cache information from Gitaly when displaying
diffs on merge requests. When enabled, we also use object storage when storing diffs.

We have 2 types of merge request diffs: base diff and `HEAD` diff. Each type
is generated differently.

#### Base diff

On every push to a merge request branch, we create a new merge request diff version.

This flowchart shows a basic explanation of how each component is used in this case.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart TD
    accTitle: Flowchart of generating a new diff version
    accDescr: High-level flowchart of components used when creating a new diff version, based on a Git push to a branch
    A[PostReceive worker] --> B[MergeRequests::RefreshService]
    B --> C[Reload diff of merge requests]
    C --> D[Create merge request diff]
    D --> K[(Database)]
    D --> E[Ensure commit SHAs]
    E --> L[Gitaly]
    E --> F[Set patch-id]
    F --> L[Gitaly]
    F --> G[Save commits]
    G --> L[Gitaly]
    G --> K[(Database)]
    G --> H[Save diffs]
    H --> L[Gitaly]
    H --> K[(Database)]
    H --> M[(Object Storage)]
    H --> I[Keep around commits]
    I --> L[Gitaly]
    I --> J[Clear highlight and stats cache]
    J --> N[(Redis)]
```

This sequence diagram shows a more detailed explanation of this flow.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Data flow of building a new diff
    accDescr: Detailed model of the data flow through the components that build a new diff version
    PostReceive-->>+MergeRequests_RefreshService: execute()
    Note over MergeRequests_RefreshService: Reload diff of merge requests
    MergeRequests_RefreshService-->>+MergeRequest: reload_diff()
    Note over MergeRequests_ReloadDiffsService: Create merge request diff
    MergeRequest-->>+MergeRequests_ReloadDiffsService: execute()
    MergeRequests_ReloadDiffsService-->>+MergeRequest: create_merge_request_diff()
    MergeRequest-->>+MergeRequestDiff: create()
    Note over MergeRequestDiff: Ensure commit SHAs
    MergeRequestDiff-->>+MergeRequest: source_branch_sha()
    MergeRequest-->>+Repository: commit()
    Repository-->>+Gitaly: FindCommit RPC
    Gitaly-->>-Repository: Gitlab::Git::Commit
    Repository-->>+Commit: new()
    Commit-->>-Repository: Commit
    Repository-->>-MergeRequest: Commit
    MergeRequest-->>-MergeRequestDiff: Commit SHA
    Note over MergeRequestDiff: Set patch-id
    MergeRequestDiff-->>+Repository: get_patch_id()
    Repository-->>+Gitaly: GetPatchID RPC
    Gitaly-->>-Repository: Patch ID
    Repository-->>-MergeRequestDiff: Patch ID
    Note over MergeRequestDiff: Save commits
    MergeRequestDiff-->>+Gitaly: ListCommits RPC
    Gitaly-->>-MergeRequestDiff: Commits
    MergeRequestDiff-->>+MergeRequestDiffCommit: create_bulk()
    Note over MergeRequestDiff: Save diffs
    MergeRequestDiff-->>+Gitaly: ListCommits RPC
    Gitaly-->>-MergeRequestDiff: Commits
    opt When external diffs is enabled
      MergeRequestDiff-->>+ObjectStorage: upload diffs
    end
    MergeRequestDiff-->>+MergeRequestDiffFile: legacy_bulk_insert()
    Note over MergeRequestDiff: Keep around commits
    MergeRequestDiff-->>+Repository: keep_around()
    Repository-->>+Gitaly: WriteRef RPC
    Note over MergeRequests_ReloadDiffsService: Clear highlight and stats cache
    MergeRequests_ReloadDiffsService->>+Gitlab_Diff_HighlightCache: clear()
    MergeRequests_ReloadDiffsService->>+Gitlab_Diff_StatsCache: clear()
    Gitlab_Diff_HighlightCache-->>+Redis: cache
    Gitlab_Diff_StatsCache-->>+Redis: cache
```

#### `HEAD` diff

Whenever mergeability of a merge request is checked and the merge request `merge_status`
is either `:unchecked`, `:cannot_be_merged_recheck`, `:checking`, or `:cannot_be_merged_rechecking`,
we attempt to merge the changes from source branch to target branch and write to a ref.
If it's successful (meaning, no conflict), we generate a diff based on the
generated commit and show it as the `HEAD` diff.

The flow differs from the base diff generation as it has a different entry point.

This flowchart shows a basic explanation of how each component is used when generating
a `HEAD` diff.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart TD
    accTitle: Generating a HEAD diff (high-level view)
    accDescr: High-level flowchart of components used when generating a HEAD diff
    A[MergeRequestMergeabilityCheckWorker] --> B[MergeRequests::MergeabilityCheckService]
    B --> C[Merge changes to ref]
    C --> L[Gitaly]
    C --> D[Recreate merge request HEAD diff]
    D --> K[(Database)]
    D --> E[Ensure commit SHAs]
    E --> L[Gitaly]
    E --> F[Set patch-id]
    F --> L[Gitaly]
    F --> G[Save commits]
    G --> L[Gitaly]
    G --> K[(Database)]
    G --> H[Save diffs]
    H --> L[Gitaly]
    H --> K[(Database)]
    H --> M[(Object Storage)]
    H --> I[Keep around commits]
    I --> L[Gitaly]
```

This sequence diagram shows a more detailed explanation of this flow.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Generating a HEAD diff (detail view)
    accDescr: Detailed sequence diagram of generating a new HEAD diff
    MergeRequestMergeabilityCheckWorker-->>+MergeRequests_MergeabilityCheckService: execute()
    Note over MergeRequests_MergeabilityCheckService: Merge changes to ref
    MergeRequests_MergeabilityCheckService-->>+MergeRequests_MergeToRefService: execute()
    MergeRequests_MergeToRefService-->>+Repository: merge_to_ref()
    Repository-->>+Gitaly: UserMergeBranch RPC
    Gitaly-->>-Repository: Commit SHA
    MergeRequests_MergeToRefService-->>+Repository: commit()
    Repository-->>+Gitaly: FindCommit RPC
    Gitaly-->>-Repository: Gitlab::Git::Commit
    Repository-->>+Commit: new()
    Commit-->>-Repository: Commit
    Repository-->>-MergeRequests_MergeToRefService: Commit
    Note over MergeRequests_MergeabilityCheckService: Recreate merge request HEAD diff
    MergeRequests_MergeabilityCheckService-->>+MergeRequests_ReloadMergeHeadDiffService: execute()
    MergeRequests_ReloadMergeHeadDiffService-->>+MergeRequest: create_merge_request_diff()
    MergeRequest-->>+MergeRequestDiff: create()
    Note over MergeRequestDiff: Ensure commit SHAs
    MergeRequestDiff-->>+MergeRequest: merge_ref_head()
    MergeRequest-->>+Repository: commit()
    Repository-->>+Gitaly: FindCommit RPC
    Gitaly-->>-Repository: Gitlab::Git::Commit
    Repository-->>+Commit: new()
    Commit-->>-Repository: Commit
    Repository-->>-MergeRequest: Commit
    MergeRequest-->>-MergeRequestDiff: Commit SHA
    Note over MergeRequestDiff: Set patch-id
    MergeRequestDiff-->>+Repository: get_patch_id()
    Repository-->>+Gitaly: GetPatchID RPC
    Gitaly-->>-Repository: Patch ID
    Repository-->>-MergeRequestDiff: Patch ID
    Note over MergeRequestDiff: Save commits
    MergeRequestDiff-->>+Gitaly: ListCommits RPC
    Gitaly-->>-MergeRequestDiff: Commits
    MergeRequestDiff-->>+MergeRequestDiffCommit: create_bulk()
    Note over MergeRequestDiff: Save diffs
    MergeRequestDiff-->>+Gitaly: ListCommits RPC
    Gitaly-->>-MergeRequestDiff: Commits
    opt When external diffs is enabled
      MergeRequestDiff-->>+ObjectStorage: upload diffs
    end
    MergeRequestDiff-->>+MergeRequestDiffFile: legacy_bulk_insert()
    Note over MergeRequestDiff: Keep around commits
    MergeRequestDiff-->>+Repository: keep_around()
    Repository-->>+Gitaly: WriteRef RPC
```

### `diffs_batch.json`

The most common avenue for viewing diffs is the **Changes**
tab at the top of merge request pages in the GitLab UI. When selected, the
diffs themselves are loaded via a paginated request to `/-/merge_requests/:id/diffs_batch.json`,
which is served by [`Projects::MergeRequests::DiffsController#diffs_batch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/merge_requests/diffs_controller.rb).

This flowchart shows a basic explanation of how each component is used in a
`diffs_batch.json` request.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart TD
    accTitle: Viewing a diff
    accDescr: High-level flowchart a diffs_batch request, which renders diffs for browser display
    A[Frontend] --> B[diffs_batch.json]
    B --> C[Preload diffs and ivars]
    C -->D[Gitaly]
    C -->E[(Database)]
    C --> F[Getting diff file collection]
    C --> F[Getting diff file collection]
    F --> G[Calculate unfoldable diff lines]
    G --> E
    G --> H{ETag header is not stale}
    H --> |Yes| I[Return 304]
    H --> |No| J[Serialize diffs]
    J --> D
    J --> E
    J --> K[(Redis)]
    J --> L[Return 200 with JSON]
```

Different cases exist when viewing diffs, though, and the flow for each case differs.

#### Viewing HEAD, latest or specific diff version

The HEAD diff is viewed by default, if it is available. If not, it falls back to
latest diff version. It's also possible to view a specific diff version. These cases
have the same flow.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Viewing the most recent diff
    accDescr: Sequence diagram showing how a particular diff is chosen for display, first with the HEAD diff, then the latest diff, followed by a specific version if it's requested
    Frontend-->>+.#diffs_batch: API call
    Note over .#diffs_batch: Preload diffs and ivars
    .#diffs_batch-->>+.#define_diff_vars: before_action
    .#define_diff_vars-->>+MergeRequest: merge_request_head_diff() or merge_request_diff()
    MergeRequest-->>+MergeRequestDiff: find()
    MergeRequestDiff-->>-MergeRequest: MergeRequestDiff
    MergeRequest-->>-.#define_diff_vars: MergeRequestDiff
    .#define_diff_vars-->>-.#diffs_batch: @compare
    Note over .#diffs_batch: Getting diff file collection
    .#diffs_batch-->>+MergeRequestDiff: diffs_in_batch()
    MergeRequestDiff-->>+Gitlab_Diff_FileCollection_MergeRequestDiffBatch: new()
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>-MergeRequestDiff: diff file collection
    MergeRequestDiff-->>-.#diffs_batch: diff file collection
    Note over .#diffs_batch: Calculate unfoldable diff lines
    .#diffs_batch-->>+MergeRequest: note_positions_for_paths
    MergeRequest-->>+Gitlab_Diff_PositionCollection: new() then unfoldable()
    Gitlab_Diff_PositionCollection-->>-MergeRequest: position collection
    MergeRequest-->>-.#diffs_batch: unfoldable_positions
    break when ETag header is present and is not stale
        .#diffs_batch-->>+Frontend: return 304 HTTP
    end
    .#diffs_batch->>+Gitlab_Diff_FileCollection_MergeRequestDiffBatch: write_cache()
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch->>+Gitlab_Diff_HighlightCache: write_if_empty()
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch->>+Gitlab_Diff_StatsCache: write_if_empty()
    Gitlab_Diff_HighlightCache-->>+Redis: cache
    Gitlab_Diff_StatsCache-->>+Redis: cache
    Note over .#diffs_batch: Serialize diffs and render JSON
    .#diffs_batch-->>+PaginatedDiffSerializer: represent()
    PaginatedDiffSerializer-->>+Gitlab_Diff_FileCollection_MergeRequestDiffBatch: diff_files()
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>+MergeRequestDiff: raw_diffs()
    MergeRequestDiff-->>+MergeRequestDiffFile: Get all associated records
    MergeRequestDiffFile-->>-MergeRequestDiff: Gitlab::Git::DiffCollection
    MergeRequestDiff-->>-Gitlab_Diff_FileCollection_MergeRequestDiffBatch: diff files
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>+Gitlab_Diff_StatsCache: find_by_path()
    Gitlab_Diff_StatsCache-->>+Redis: Read data from cache
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>+Gitlab_Diff_HighlightCache: decorate()
    Gitlab_Diff_HighlightCache-->>+Redis: Read data from cache
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>-PaginatedDiffSerializer: diff files
    PaginatedDiffSerializer-->>-.#diffs_batch: JSON
    .#diffs_batch-->>+Frontend: return 200 HTTP with JSON
```

However, if **Show whitespace changes** is not selected when viewing diffs:

- Whitespace changes are ignored.
- The flow changes, and now involves Gitaly.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Viewing diffs without whitespace changes
    accDescr: Sequence diagram showing how a particular diff is chosen for display, if whitespace changes are not requested - first with the HEAD diff, then the latest diff, followed by a specific version if it's requested
    Frontend-->>+.#diffs_batch: API call
    Note over .#diffs_batch: Preload diffs and ivars
    .#diffs_batch-->>+.#define_diff_vars: before_action
    .#define_diff_vars-->>+MergeRequest: merge_request_head_diff() or merge_request_diff()
    MergeRequest-->>+MergeRequestDiff: find()
    MergeRequestDiff-->>-MergeRequest: MergeRequestDiff
    MergeRequest-->>-.#define_diff_vars: MergeRequestDiff
    .#define_diff_vars-->>-.#diffs_batch: @compare
    Note over .#diffs_batch: Getting diff file collection
    .#diffs_batch-->>+MergeRequestDiff: diffs_in_batch()
    MergeRequestDiff-->>+Gitlab_Diff_FileCollection_Compare: new()
    Gitlab_Diff_FileCollection_Compare-->>-MergeRequestDiff: diff file collection
    MergeRequestDiff-->>-.#diffs_batch: diff file collection
    Note over .#diffs_batch: Calculate unfoldable diff lines
    .#diffs_batch-->>+MergeRequest: note_positions_for_paths
    MergeRequest-->>+Gitlab_Diff_PositionCollection: new() then unfoldable()
    Gitlab_Diff_PositionCollection-->>-MergeRequest: position collection
    MergeRequest-->>-.#diffs_batch: unfoldable_positions
    break when ETag header is present and is not stale
        .#diffs_batch-->>+Frontend: return 304 HTTP
    end
    opt Cache higlights and stats when viewing HEAD, latest or specific version
        .#diffs_batch->>+Gitlab_Diff_FileCollection_MergeRequestDiffBatch: write_cache()
        Gitlab_Diff_FileCollection_MergeRequestDiffBatch->>+Gitlab_Diff_HighlightCache: write_if_empty()
        Gitlab_Diff_FileCollection_MergeRequestDiffBatch->>+Gitlab_Diff_StatsCache: write_if_empty()
        Gitlab_Diff_HighlightCache-->>+Redis: cache
        Gitlab_Diff_StatsCache-->>+Redis: cache
    end
    Note over .#diffs_batch: Serialize diffs and render JSON
    .#diffs_batch-->>+PaginatedDiffSerializer: represent()
    PaginatedDiffSerializer-->>+Gitlab_Diff_FileCollection_MergeRequestDiffBatch: diff_files()
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>+MergeRequestDiff: raw_diffs()
    MergeRequestDiff-->>+Repository: diff()
    Repository-->>+Gitaly: CommitDiff RPC
    Gitaly-->>-Repository: GitalyClient::DiffStitcher
    Repository-->>-MergeRequestDiff: Gitlab::Git::DiffCollection
    MergeRequestDiff-->>-Gitlab_Diff_FileCollection_MergeRequestDiffBatch: diff files
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>+Gitlab_Diff_StatsCache: find_by_path()
    Gitlab_Diff_StatsCache-->>+Redis: Read data from cache
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>+Gitlab_Diff_HighlightCache: decorate()
    Gitlab_Diff_HighlightCache-->>+Redis: Read data from cache
    Gitlab_Diff_FileCollection_MergeRequestDiffBatch-->>-PaginatedDiffSerializer: diff files
    PaginatedDiffSerializer-->>-.#diffs_batch: JSON
    .#diffs_batch-->>+Frontend: return 200 HTTP with JSON
```

#### Compare between merge request diff versions

You can also compare different diff versions when viewing diffs. The flow is different
from the default flow, as it makes requests to Gitaly to generate a comparison between two
diff versions. It also doesn't use Redis for highlight and stats caches.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Comparing diffs
    accDescr: Sequence diagram of how diffs are compared against each other
    Frontend-->>+.#diffs_batch: API call
    Note over .#diffs_batch: Preload diffs and ivars
    .#diffs_batch-->>+.#define_diff_vars: before_action
    .#define_diff_vars-->>+MergeRequestDiff: compare_with(start_sha)
    MergeRequestDiff-->>+Compare: new()
    Compare-->>-MergeRequestDiff: Compare
    MergeRequestDiff-->>-.#define_diff_vars: Compare
    .#define_diff_vars-->>-.#diffs_batch: @compare
    Note over .#diffs_batch: Getting diff file collection
    .#define_diff_vars-->>+Compare: diffs_in_batch()
    Compare-->>+Gitlab_Diff_FileCollection_Compare: new()
    Gitlab_Diff_FileCollection_Compare-->>-Compare: diff file collection
    Compare-->>-.#define_diff_vars: diff file collection
    Note over .#diffs_batch: Calculate unfoldable diff lines
    .#diffs_batch-->>+MergeRequest: note_positions_for_paths
    MergeRequest-->>+Gitlab_Diff_PositionCollection: new() then unfoldable()
    Gitlab_Diff_PositionCollection-->>-MergeRequest: position collection
    MergeRequest-->>-.#diffs_batch: unfoldable_positions
    break when ETag header is present and is not stale
        .#diffs_batch-->>+Frontend: return 304 HTTP
    end
    Note over .#diffs_batch: Serialize diffs and render JSON
    .#diffs_batch-->>+PaginatedDiffSerializer: represent()
    PaginatedDiffSerializer-->>+Gitlab_Diff_FileCollection_Compare: diff_files()
    Gitlab_Diff_FileCollection_Compare-->>+Compare: raw_diffs()
    Compare-->>+Repository: diff()
    Repository-->>+Gitaly: CommitDiff RPC
    Gitaly-->>-Repository: GitalyClient::DiffStitcher
    Repository-->>-Compare: Gitlab::Git::DiffCollection
    Compare-->>-Gitlab_Diff_FileCollection_Compare: diff files
    Gitlab_Diff_FileCollection_Compare-->>-PaginatedDiffSerializer: diff files
    PaginatedDiffSerializer-->>-.#diffs_batch: JSON
    .#diffs_batch-->>+Frontend: return 200 HTTP with JSON
```

#### Viewing commit diff

Another feature to view merge request diffs is to view diffs of a specific commit. It
differs from the default flow, and requires Gitaly to get the diff of the specific commit. It
also doesn't use Redis for the highlight and stats caches.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Viewing commit diff
    accDescr: Sequence diagram showing how viewing the diff of a specific commit is different from the default diff view flow
    Frontend-->>+.#diffs_batch: API call
    Note over .#diffs_batch: Preload diffs and ivars
    .#diffs_batch-->>+.#define_diff_vars: before_action
    .#define_diff_vars-->>+Repository: commit()
    Repository-->>+Gitaly: FindCommit RPC
    Gitaly-->>-Repository: Gitlab::Git::Commit
    Repository-->>+Commit: new()
    Commit-->>-Repository: Commit
    Repository-->>-.#define_diff_vars: Commit
    .#define_diff_vars-->>-.#diffs_batch: @compare
    Note over .#diffs_batch: Getting diff file collection
    .#define_diff_vars-->>+Commit: diffs_in_batch()
    Commit-->>+Gitlab_Diff_FileCollection_Commit: new()
    Gitlab_Diff_FileCollection_Commit-->>-Commit: diff file collection
    Commit-->>-.#define_diff_vars: diff file collection
    Note over .#diffs_batch: Calculate unfoldable diff lines
    .#diffs_batch-->>+MergeRequest: note_positions_for_paths
    MergeRequest-->>+Gitlab_Diff_PositionCollection: new() then unfoldable()
    Gitlab_Diff_PositionCollection-->>-MergeRequest: position collection
    MergeRequest-->>-.#diffs_batch: unfoldable_positions
    break when ETag header is present and is not stale
        .#diffs_batch-->>+Frontend: return 304 HTTP
    end
    Note over .#diffs_batch: Serialize diffs and render JSON
    .#diffs_batch-->>+PaginatedDiffSerializer: represent()
    PaginatedDiffSerializer-->>+Gitlab_Diff_FileCollection_Commit: diff_files()
    Gitlab_Diff_FileCollection_Commit-->>+Commit: raw_diffs()
    Commit-->>+Gitaly: CommitDiff RPC
    Gitaly-->>-Commit: GitalyClient::DiffStitcher
    Commit-->>-Gitlab_Diff_FileCollection_Commit: Gitlab::Git::DiffCollection
    Gitlab_Diff_FileCollection_Commit-->>-PaginatedDiffSerializer: diff files
    PaginatedDiffSerializer-->>-.#diffs_batch: JSON
    .#diffs_batch-->>+Frontend: return 200 HTTP with JSON
```

### `diffs.json`

It's also possible to view diffs while creating a merge request by scrolling
down to the bottom of the new merge request page and clicking **Changes** tab.
It doesn't use the `diffs_batch.json` endpoint as the merge request record isn't
created at that point yet. It uses the `diffs.json` instead.

This flowchart shows a basic explanation of how each component is used in a
`diffs.json` request.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart TD
    accTitle: Diff request flow (high level)
    accDescr: High-level flowchart of the components used in a diffs request
    A[Frontend] --> B[diffs.json]
    B --> C[Build merge request]
    C --> D[Get diffs]
    D --> E[Render view with diffs]
    E --> G[Gitaly]
    E --> F[Respond with JSON with the rendered view]
```

This sequence diagram shows a more detailed explanation of this flow.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Diff request flow (low level)
    accDescr: Sequence diagram with a deeper view of the components used in a diffs request
    Frontend-->>+.#diffs: API call
    Note over .#diffs: Build merge request
    .#diffs-->>+MergeRequests_BuildService: execute
    MergeRequests_BuildService-->>+Compare: new()
    Compare-->>-MergeRequests_BuildService: Compare
    MergeRequests_BuildService-->>+Compare: commits()
    Compare-->>+Gitaly: ListCommits RPC
    Gitaly-->-Compare: Commits
    Compare-->>-MergeRequests_BuildService: Commits
    MergeRequests_BuildService-->>-.#diffs: MergeRequest
    Note over .#diffs: Get diffs
    .#diffs-->>+MergeRequest: diffs()
    MergeRequest-->>+Compare: diffs()
    Compare-->>+Gitlab_Diff_FileCollection_Compare: new()
    Gitlab_Diff_FileCollection_Compare-->>-Compare: diff file collection
    Compare-->>-MergeRequest: diff file collection
    MergeRequest-->>-.#diffs: @diffs =
    Note over .#diffs: Render view with diffs
    .#diffs-->>+HAML: view_to_html_string('projects/merge_requests/creations/_diffs', diffs: @diffs)
    HAML-->>+Gitlab_Diff_FileCollection_Compare: diff_files()
    Gitlab_Diff_FileCollection_Compare-->>+Compare: raw_diffs()
    Compare-->>+Repository: diff()
    Repository-->>+Gitaly: CommitDiff RPC
    Gitaly-->>-Repository: GitalyClient::DiffStitcher
    Repository-->>-Compare: Gitlab::Git::DiffCollection
    Compare-->>-Gitlab_Diff_FileCollection_Compare: diff files
    Gitlab_Diff_FileCollection_Compare-->>-HAML: diff files
    HAML-->>-.#diffs: rendered view
    .#diffs-->>-Frontend: Respond with JSON with rendered view
```
