# Gitlab::Housekeeper

Check out [the original
blueprint](https://docs.gitlab.com/ee/architecture/blueprints/gitlab_housekeeper/)
for the motivation behind the `gitlab-housekeeper`.

Also watch [this walkthrough video](https://youtu.be/KNJPVx8izAc) for an
overview on how to create your first Keep as well as the philosophy behind
`gitlab-housekeeper`.

This is a gem which can be run locally or in CI to do static and dynamic
analysis of the GitLab codebase and, using a list of predefined "keeps", it will
automatically create merge requests for things that developers would have
otherwise needed to remember to do themselves.

It is analogous to a mix of `rubocop -a` and GitLab Dependency Bot.

The word "keep" is used to describe a specific rule to apply to the code to
match a required change and actually edit the code. The word "keep" was chosen
as it sounds like "cop" and is very similar to implementing a rubocop rule as
well as code to autocorrect the rule.

You can see the existing keeps in
https://gitlab.com/gitlab-org/gitlab/-/tree/master/keeps .

## How the code is organized

The code is organized in a very similar way to RuboCop in that we have an
overall gem called `gitlab-housekeeper` that contains the generic logic of
looping over all `keeps` (analogous to Cops) which are rules for how to detect
changes that can be made to the code and then actually how to correct them.

Then users of this gem are expected to add a `keeps` directory in their project
with all the keeps specific to their project. This gem may at some point
include keeps that are generic enough to be used by other projects.

## How to implement a keep

To implement a keep, you need to implement two methods:

1. **`each_identified_change`** - Performs early validation checks and yields basic `Change` objects with context data
2. **`make_change!`** - Performs the actual file modifications and prepares the final `Change` object

### `each_identified_change` method

This method should:
- Perform any early return checks or validation
- Create basic `Change` objects with identifiers and context data
- Yield `Change` objects that pass initial validation
- **NOT** perform file modifications or other side effects

### `make_change!` method

This method should:
- Receive a `Change` object from `each_change`
- Access context data via `change.context`
- Perform all file modifications and side effects (file changes, database operations, API calls)
- Set final change details (title, description, changed_files, etc.)
- Return the completed `Change` object, or call `change.abort!` and return early if no changes should be made

### Setting up the `change` object

You can set multiple properties on a `change` object so that it reflects on the created merge request. Some of these are
mandatory, while others are optional.


| Property                          | Type    | Required | Description                                                                                                     | Example usage                                                                                       |
| ------------------------------- | ------- | -------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `description`          | String  | Yes      | Sets the description of the MR                                                                                  | `change.description = 'Description for my awesome MR'`                                            |
| `title`                | String  | Yes      | Sets the title of the MR                                                                                        | `change.title  = 'My awesome MR'`                                                                 |
| `identifiers`          | Array   | Yes      | Unique, stable identifiers for branch naming, filtering, and MR deduplication                           | `change.identifiers = [self.class.name.demodulize, 'feature_flag_name']` |
| `changed_files`        | Array   | Yes      | Array containing the path to files that are changed and needs to be committed                                  | `change.changed_files = [file_1_path, file_2_path]`                                              |
| `labels`               | Array   | No       | Default is `[]`. Array of labels that needs to be assigned to the MR upon creation                           | `change.labels = ['database', 'maintenance::scalability']`                                       |
| `assignees`            | Array   | No       | Default is `[]`. Array of usernames to which the MR should be assigned upon creation                           | `change.assignees = ['gitlab-bot', 'gitlab-qa']`                                                  |
| `reviewers`            | Array   | No       | Default is `[]`. Array of usernames to which the MR should be assigned for review upon creation                | `change.reviewers = ['gitlab-bot', 'gitlab-qa']`                                                  |
| `changelog_type`       | String  | No       | Default is `other`. Used to set a changelog type in the commit message                                       | `change.changelog_type = 'fixed'`                                                                 |
| `changelog_ee`         | Boolean | No       | Default is `false`. Setting to `true` adds the `EE:true` trailer in the commit message                       | `change.changelog_ee = true`                                                                 |
| `push_options.ci_skip` | Boolean | No       | Default is `false`. Setting to `true` creates an MR without kicking off a new pipeline | `change.push_options.ci_skip = true ` |

### Identifiers and Context

**Identifiers** are arrays that uniquely identify a specific change that a Keep plans to make. These are used to construct unique branch names (joined with dashes), enable filtering with `--filter-identifiers`, and prevent duplicate MRs by identifying the same logical change across runs. They must be stable (same change = same identifiers) and descriptive. Good patterns: `['RemoveFeatureFlag', flag_name]`, `['UpdateGem', gem_name, version]`. Avoid timestamps or random data. First element often matches the keep class name.

**Context** (`change.context`) is a hash used for passing data from `each_identified_change` to `make_change!`. Store discovered file paths, configuration objects, or processing parameters: `change.context = { files_to_update: found_files, settings: config }`. This avoids re-scanning or re-computing in `make_change!` where actual modifications happen.

### Example

Here is an example of a simple keep that creates 3 new files using the new two-method approach:

```ruby
# keeps/pretty_useless_keep.rb

module Keeps
  class PrettyUselessKeep < ::Gitlab::Housekeeper::Keep
    def each_identified_change
      (1..3).each do |i|
        change = ::Gitlab::Housekeeper::Change.new
        change.identifiers = [self.class.name.demodulize, "new_file#{i}"]
        change.context = { file_number: i }
        yield(change)
      end
    end

    def make_change!(change)
      i = change.context[:file_number]
      file_name = "new_file#{i}.txt"

      # Perform the actual file modification
      `touch #{file_name}`

      # Set up the final change details
      change.title = "Make new file #{file_name}"

      change.description = <<~MARKDOWN
      ## New files

      This MR makes a new file #{file_name}
      MARKDOWN

      change.labels = %w[type::feature]
      change.changed_files = [file_name]

      # to push changes without triggering a pipeline.
      change.push_options.ci_skip = true

      change
    end
  end
end
```

### Handling cases where no changes are needed

If your `make_change!` method determines that no changes are actually needed, call `change.abort!` and return early:

```ruby
def make_change!(change)
  # Check if changes are needed
  unless changes_needed?
    change.abort!
    return
  end

  # Perform changes and return completed change object
  perform_changes(change)
  change
end
```

The `change.abort!` method marks the change as aborted, and the runner will skip creating an MR for it while still committing any intermediate changes to a branch for debugging purposes.

### Best practices

1. **Keep `each_change` lightweight** - Only perform validation checks and data gathering
2. **Use context for data passing** - Store any data needed by `make_change!` in `change.context`
3. **Handle expensive operations in `make_change!`** - File modifications, database operations, API calls should only happen here
4. **Use `abort!` to cancel a change** - If no changes are needed you can call `change.abort!` and return early in `make_change!` and it will be skipped by the runner

## Testing a keep locally

You can dry-run this locally with the following command:

```
bundle exec gitlab-housekeeper -k Keeps::PrettyUselessKeep -d -m 3
```

The `-d` just prints the contents of the merge request. Removing this will
actually create merge requests and requires setting a few environment
variables described below.

Note: By default all `.rb` files in the `./keeps/` directory (not recursively)
will be loaded by the `gitlab-housekeeper` command. So it is assumed you place
the keeps in there.

## CLI Options

The `gitlab-housekeeper` command supports several options to customize its behavior:

```sh
bundle exec gitlab-housekeeper -h
```

### Available Options

| Option | Description | Example |
|--------|-------------|---------|
| `--push-when-approved` | Push code even if there is an existing MR with approvals. By default we do not force push code if the MR has any approvals. | `bundle exec gitlab-housekeeper --push-when-approved` |
| `-b, --target-branch=BRANCH` | Target branch to use. Defaults to master. | `bundle exec gitlab-housekeeper -b main` |
| `-m, --max-mrs=M` | Limit of MRs to create. Defaults to 1. | `bundle exec gitlab-housekeeper -m 5` |
| `-d, --dry-run` | Dry-run only. Print the MR titles, descriptions and diffs | `bundle exec gitlab-housekeeper -d` |
| `-k, --keeps` | Require keeps specified (comma-separated) | `bundle exec gitlab-housekeeper -k OverdueFinalizeBackgroundMigration,AnotherKeep` |
| `--filter-identifiers` | Skip any changes where none of the identifiers match these regexes. The identifiers is an array, so at least one element must match at least one regex. | `bundle exec gitlab-housekeeper --filter-identifiers "DeleteOldFeatureFlags,.*_feature_flag"` |
| `-h, --help` | Prints help information | `bundle exec gitlab-housekeeper -h` |

### Usage Examples

```bash
# Basic usage
bundle exec gitlab-housekeeper -k Keeps::PrettyUselessKeep -d -m 3
bundle exec gitlab-housekeeper -b main -m 1

# Keep selection (run only specific keeps)
bundle exec gitlab-housekeeper -k "DeleteOldFeatureFlags,RubocopFixer" -d -m 5

# Identifier filtering (fine-grained control within keeps)
bundle exec gitlab-housekeeper --filter-identifiers "my_feature_flag" -d -m 1
bundle exec gitlab-housekeeper --filter-identifiers "users" -d -m 2

# Filter by file patterns (useful for quarantine changes affecting specific files)
bundle exec gitlab-housekeeper --filter-identifiers "spec/.*_spec\.rb" -d -m 3

# Combined keep selection + identifier filtering
bundle exec gitlab-housekeeper -k "RubocopFixer" --filter-identifiers "Style/.*" -d -m 5
# Filter by table names (useful for database-related keeps)
bundle exec gitlab-housekeeper -k "InitializeBigIntConversion" --filter-identifiers "users" -d -m 2
```

## Running for real

In order to run this without `-d` (ie. not a dry-run) then you need to set a
few environment variables:

1. `HOUSEKEEPER_TARGET_PROJECT_ID`: The project id of the project you are
   creating MRs for
2. `HOUSEKEEPER_GITLAB_API_TOKEN`: An API token with at least Developer access
   for the project you are creating MRs for
3. Some keeps may require additional environment variables to be run so you may
   need to look at the specific keep code to see if anything is mentioned or
   just try running it and it should give a helpful error

Then you can run a specific keep creating a single merge request like:

```
bundle exec gitlab-housekeeper -k MyKeep -m 1
```

## Running with a fork

It may be preferable to run the housekeeper using a bot account that does not
have Developer access to the main project. In that case you would:

1. Fork the project you want to create an MR for
2. Set a git remote `housekeeper` with the git url for the project
   ```
   git remote add housekeeper <FORK_GIT_URL>
   ```
3. Set the `HOUSEKEEPER_FORK_PROJECT_ID` environment variable with the project
   id of the fork

## Once-off keeps

Sometimes we have a large group of merge requests that we need to generate to
backfill a large refactoring across the codebase. An example might be fixing a
RuboCop violation spanning hundreds of files but breaking it up into many small
MRs. One real example we've been working on is in
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139747 .

In this case the `gitlab-housekeeper` contains a lot of functionality that is
preferable to writing a whole new once off script just for this case.

In order to use the `gitlab-housekeeper` to help with this kind of work you can
create a "once-off" keep. A once-off keep is not something that needs to be
merged into master but instead you can just create a branch and put the file in
the `keeps` directory.

Some best practices to consider when using a once-off keep:

1. Always push the work in a branch and create a `Draft` MR. You don't need to
   merge it but this just increases transparency.
1. Consider adding a link back to this MR in the description of your generated
   MRs. This allows reviewers to understand where this work comes from and can
   also help if they want to contribute improvements to an ongoing group of MRs.

## Running Housekeeper automatically in CI

GitLab Housekeeper is already being run in CI pipelines in different projects.
Typically we have CI jobs which trigger a single keep with the desired
settings. It is likely possible to expand our current CI pipelines to run new
keeps periodically. Here are some places where it is being run today:

1. In our [`engineering-productivity` team scheduled pipelines](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/blob/edf362f52d81ecb8e4934c357cb567384af106a5/.gitlab-ci.yml#L68). This is the default place to add new keeps.
1. In our [`database-testing` scheduled pipelines](https://gitlab.com/gitlab-org/database-team/gitlab-com-database-testing/-/blob/ebbd9a18547376d2a6e89cf95a6ce12c8d1f133d/db-testing.yml#L402). This is the place to add keeps which need to read from a production Postgres archive.

## Troubleshooting

### Git Conflicts and Branch Issues

When developing a keep locally, you may encounter git-related errors that cause the keep to fail and exit. This commonly happens when your local branch is not up-to-date with the default comparison branch (master).

**Common Scenario**: You've added new files locally during development, and the keep fails with unhelpful error messages about git conflicts.

**Root Cause**: GitLab Housekeeper uses the `master` branch as the default comparison branch. If your local `master` branch is behind the remote `master` branch, or if you have uncommitted changes, this can cause conflicts when the tool tries to create branches and commits.

**Solution**: Ensure your local repository is clean and up-to-date:

```bash
# Stash any uncommitted changes
git stash

# Switch to master and pull latest changes
git checkout master
git pull origin master

# Rebase your feature branch (if working on one)
git checkout your-feature-branch
git rebase master

# Now run housekeeper
bundle exec gitlab-housekeeper -k YourKeep -d
```

**Alternative**: Use the `--target-branch` option to specify a different base branch:

```bash
bundle exec gitlab-housekeeper -b your-current-branch -k YourKeep -d
```

### Keep-Specific Issues

If a keep fails during execution:

1. **Check the keep's comments**: Most keeps include usage examples and required environment variables in their header comments
2. **Run with dry-run first**: Always test with `-d` flag before creating actual MRs
3. **Check file permissions**: Ensure the keep has permission to modify the files it targets
4. **Verify project state**: Some keeps expect certain files or configurations to exist

## Architecture Details

### The two-method approach

**Why this approach?** The runner needs to check various conditions after `each_identified_change` but before
actual file modifications:
- Whether a closed MR already exists for this change
- Whether the change matches filter identifiers
- Whether we've hit the maximum MR limit
- Other early-exit conditions

Performing expensive operations (file modifications, database resets, API calls) before these checks
would be wasteful and could cause issues if the change gets skipped.

This separation allows the runner to perform validation checks (like checking if an MR already exists,
filter matching, etc.) before doing expensive file modifications and side effects.

## Using Housekeeper in other projects

Right now we do not publish housekeeper to RubyGems. We have published it once
to hold the name but it's not up to date.

In order to use Housekeeper in another project you would need to add the
following to your `Gemfile` and run `bundle install`:

```
gem 'gitlab-housekeeper', git: 'https://gitlab.com/gitlab-org/gitlab.git', branch: 'master', glob: 'gems/gitlab-housekeeper/*.gemspec'
```

After that you can just run `bundle exec gitlab-housekeeper`. Housekeeper
defaults to loading all keeps in the `./keeps` directory so you would also
create that directory in your project and put your keeps there.
