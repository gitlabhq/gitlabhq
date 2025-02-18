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

The only thing you need to implement is an `each_change` method. The method
should yield changes in the form of a `::Gitlab::Housekeeper::Change` object,
where each change object represents a merge request that will be created.
The object describes the files that should be commited and other metadata
should be added to the merge request. Before yielding the `Change` the keep
should also edit the files locally.

### Setting up the `change` object

You can set multiple properties on a `change` object so that it reflects on the created merge request. Some of these are
mandatory, while others are optional.


| Property                          | Type    | Required | Description                                                                                                     | Example usage                                                                                       |
| ------------------------------- | ------- | -------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `description`          | String  | Yes      | Sets the description of the MR                                                                                  | `change.description = 'Description for my awesome MR'`                                            |
| `title`                | String  | Yes      | Sets the title of the MR                                                                                        | `change.title  = 'My awesome MR'`                                                                 |
| `identifiers`          | Array   | Yes      | Decides the name of the source branch name of the  MR                                                    | `change.identifiers = [[self.class.name](http://self.class.name).demodulize, changed_files.last]` |
| `changed_files`        | Array   | Yes      | Array containing the path to files that are changed and needs to be committed                                  | `change.changed_files = [file_1_path, file_2_path]`                                              |
| `labels`               | Array   | No       | Default is `[]`. Array of labels that needs to be assigned to the MR upon creation                           | `change.labels = ['database', 'maintenance::scalability']`                                       |
| `assignees`            | Array   | No       | Default is `[]`. Array of usernames to which the MR should be assigned upon creation                           | `change.assignees = ['gitlab-bot', 'gitlab-qa']`                                                  |
| `reviewers`            | Array   | No       | Default is `[]`. Array of usernames to which the MR should be assigned for review upon creation                | `change.reviewers = ['gitlab-bot', 'gitlab-qa']`                                                  |
| `changelog_type`       | String  | No       | Default is `other`. Used to set a changelog type in the commit message                                       | `change.changelog_type = 'fixed'`                                                                 |
| `changelog_ee`         | Boolean | No       | Default is `false`. Setting to `true` adds the `EE:true` trailer in the commit message                       | `change.changelog_ee = true`                                                                 |
| `push_options.ci_skip` | Boolean | No       | Default is `false`. Setting to `true` creates an MR without kicking off a new pipeline | `change.push_options.ci_skip = true ` |

### Example

Here is an example of a very simple keep that creates 3 new files called
`new_file1.txt`, `new_file2.txt` and `new_file3.txt`:

```ruby
# keeps/pretty_useless_keep.rb

module Keeps
  class PrettyUselessKeep < ::Gitlab::Housekeeper::Keep
    def each_change
      (1..3).each do |i|
        file_name = "new_file#{i}.txt"

        `touch #{file_name}`

        change = ::Gitlab::Housekeeper::Change.new

        change.identifiers = [self.class.name.demodulize, "new_file#{i}"]

        change.title = "Make new file #{file_name}"

        change.description = <<~MARKDOWN
        ## New files

        This MR makes a new file #{file_name}
        MARKDOWN

        change.labels = %w(type::feature)

        change.changed_files = [file_name]

        # to push changes without triggering a pipeline.
        change.push_options.ci_skip = true

        yield(change)
      end
    end
  end
end
```

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
