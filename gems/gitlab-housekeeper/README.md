# Gitlab::Housekeeper

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

        identifiers = [self.class.name.demodulize, "new_file#{i}"]

        title = "Make new file #{file_name}"

        description = <<~MARKDOWN
        ## New files

        This MR makes a new file #{file_name}
        MARKDOWN

        changed_files = [file_name]

        yield(::Gitlab::Housekeeper::Change.new(
          identifiers, title, description, changed_files
        ))
      end
    end
  end
end
```

You can dry-run this locally with the following command:

```
bundle exec gitlab-housekeeper -r keeps/pretty_useless_keep.rb -k Keeps::PrettyUselessKeep -d -m 3
```

The `-d` just prints the contents of the merge request. Removing this will
actually create merge requests and requires setting a few environment
variables described below.

## Running

Technically you can skip steps 1-2 below if you don't want to create a fork but
it's recommended as using a bot account with no permissions in
`gitlab-org/gitlab` will ensure we can't cause much damage if the script makes
a mistake. The alternative of using your own API token with it's permissions to
`gitlab-org/gitlab` has slightly more risks.

1. Create a fork of `gitlab-org/gitlab` where your MRs will come from
1. Create a project access token for that project
1. Set `housekeeper` remote to the fork you created
   ```
   git remote add housekeeper <FORK_GIT_URL>
   ```
1. Open a Postgres.ai tunnel on localhost port 6305
1. Set the Postgres AI env vars matching the tunnel details for your tunnel
   ```
   export POSTGRES_AI_CONNECTION_STRING='host=localhost port=6305 user=dylan dbname=gitlabhq_dblab'
    export POSTGRES_AI_PASSWORD='the-password'
   ```
1. Set the GitLab client details. Will be used to create MR from housekeeper remote:
   ```
   export HOUSEKEEPER_FORK_PROJECT_ID=<FORK_PROJECT_ID> # Same project as housekeeper remote
   export HOUSEKEEPER_TARGET_PROJECT_ID=<TARGET_PROJECT_ID> # Can be 278964 (gitlab-org/gitlab) when ready to create real MRs
    export HOUSEKEEPER_GITLAB_API_TOKEN=the-api-token
   ```
1. Run it:
   ```
   bundle exec gitlab-housekeeper -d -m3 -r keeps/overdue_finalize_background_migration.rb -k Keeps::OverdueFinalizeBackgroundMigration
   ```
