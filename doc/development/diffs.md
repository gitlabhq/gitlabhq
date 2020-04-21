# Working with diffs

Currently we rely on different sources to present diffs, these include:

- Gitaly service
- Database (through `merge_request_diff_files`)
- Redis (cached highlighted diffs)

## Deep Dive

In January 2019, Oswaldo Ferreira hosted a [Deep Dive](https://gitlab.com/gitlab-org/create-stage/issues/1) on GitLab's Diffs and Commenting on Diffs functionality to share his domain specific knowledge with anyone who may work in this part of the code base in the future. You can find the [recording on YouTube](https://www.youtube.com/watch?v=K6G3gMcFyek), and the slides on [Google Slides](https://docs.google.com/presentation/d/1bGutFH2AT3bxOPZuLMGl1ANWHqFnrxwQwjiwAZkF-TU/edit) and in [PDF](https://gitlab.com/gitlab-org/create-stage/uploads/b5ad2f336e0afcfe0f99db0af0ccc71a/). Everything covered in this deep dive was accurate as of GitLab 11.7, and while specific details may have changed since then, it should still serve as a good introduction.

## Architecture overview

### Merge request diffs

When refreshing a Merge Request (pushing to a source branch, force-pushing to target branch, or if the target branch now contains any commits from the MR)
we fetch the comparison information using `Gitlab::Git::Compare`, which fetches `base` and `head` data using Gitaly and diff between them through
`Gitlab::Git::Diff.between`.
The diffs fetching process _limits_ single file diff sizes and the overall size of the whole diff through a series of constant values. Raw diff files are
then persisted on `merge_request_diff_files` table.

Even though diffs larger than 10% of the value of `ApplicationSettings#diff_max_patch_bytes` are collapsed,
we still keep them on PostgreSQL. However, diff files larger than defined _safety limits_
(see the [Diff limits section](#diff-limits)) are _not_ persisted in the database.

In order to present diffs information on the Merge Request diffs page, we:

1. Fetch all diff files from database `merge_request_diff_files`
1. Fetch the _old_ and _new_ file blobs in batch to:
   - Highlight old and new file content
   - Know which viewer it should use for each file (text, image, deleted, etc)
   - Know if the file content changed
   - Know if it was stored externally
   - Know if it had storage errors
1. If the diff file is cacheable (text-based), it's cached on Redis
   using `Gitlab::Diff::FileCollection::MergeRequestDiff`

### Note diffs

When commenting on a diff (any comparison), we persist a truncated diff version
on `NoteDiffFile` (which is associated with the actual `DiffNote`). So instead
of hitting the repository every time we need the diff of the file, we:

1. Check whether we have the `NoteDiffFile#diff` persisted and use it
1. Otherwise, if it's a current MR revision, use the persisted
   `MergeRequestDiffFile#diff`
1. In the last scenario, go the repository and fetch the diff

## Diff limits

As explained above, we limit single diff files and the size of the whole diff. There are scenarios where we collapse the diff file,
and cases where the diff file is not presented at all, and the user is guided to the Blob view. Here we'll go into details about
these limits.

### Diff collection limits

Limits that act onto all diff files collection. Files number, lines number and files size are considered.

```ruby
Gitlab::Git::DiffCollection.collection_limits[:safe_max_files] = Gitlab::Git::DiffCollection::DEFAULT_LIMITS[:max_files] = 100
```

File diffs will be collapsed (but be expandable) if 100 files have already been rendered.

```ruby
Gitlab::Git::DiffCollection.collection_limits[:safe_max_lines] = Gitlab::Git::DiffCollection::DEFAULT_LIMITS[:max_lines] = 5000
```

File diffs will be collapsed (but be expandable) if 5000 lines have already been rendered.

```ruby
Gitlab::Git::DiffCollection.collection_limits[:safe_max_bytes] = Gitlab::Git::DiffCollection.collection_limits[:safe_max_files] * 5.kilobytes = 500.kilobytes
```

File diffs will be collapsed (but be expandable) if 500 kilobytes have already been rendered.

```ruby
Gitlab::Git::DiffCollection.collection_limits[:max_files] = Commit::DIFF_HARD_LIMIT_FILES = 1000
```

No more files will be rendered at all if 1000 files have already been rendered.

```ruby
Gitlab::Git::DiffCollection.collection_limits[:max_lines] = Commit::DIFF_HARD_LIMIT_LINES = 50000
```

No more files will be rendered at all if 50,000 lines have already been rendered.

```ruby
Gitlab::Git::DiffCollection.collection_limits[:max_bytes] = Gitlab::Git::DiffCollection.collection_limits[:max_files] * 5.kilobytes = 5000.kilobytes
```

No more files will be rendered at all if 5 megabytes have already been rendered.

*Note:* All collection limit parameters are currently sent and applied on Gitaly. That is, once the limit is surpassed,
Gitaly will only return the safe amount of data to be persisted on `merge_request_diff_files`.

### Individual diff file limits

Limits that act onto each diff file of a collection. Files number, lines number and files size are considered.

#### Expandable patches (collapsed)

Diff patches are collapsed when surpassing 10% of the value set in `ApplicationSettings#diff_max_patch_bytes`.
That is, it's equivalent to 10kb if the maximum allowed value is 100kb.
The diff will still be persisted and expandable if the patch size doesn't
surpass `ApplicationSettings#diff_max_patch_bytes`.

*Note:* Although this nomenclature (Collapsing) is also used on Gitaly, this limit is only used on GitLab (hardcoded - not sent to Gitaly).
Gitaly will only return `Diff.Collapsed` (RPC) when surpassing collection limits.

#### Not expandable patches (too large)

The patch not be rendered if it's larger than `ApplicationSettings#diff_max_patch_bytes`.
Users will see a `This source diff could not be displayed because it is too large` message.

```ruby
Commit::DIFF_SAFE_LINES = Gitlab::Git::DiffCollection::DEFAULT_LIMITS[:max_lines] = 5000
```

File diff will be suppressed (technically different from collapsed, but behaves the same, and is expandable) if it has more than 5000 lines.

*Note:* This limit is currently hardcoded and only applied on GitLab.

## Viewers

Diff Viewers, which can be found on `models/diff_viewer/*` are classes used to map metadata about each type of Diff File. It has information
whether it's a binary, which partial should be used to render it or which File extensions this class accounts for.

`DiffViewer::Base` validates _blobs_ (old and new versions) content, extension and file type in order to check if it can be rendered.
