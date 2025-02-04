---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Rails upgrade guidelines
---

We strive to run GitLab using the latest Rails releases to benefit from performance, security updates, and new features.

## Rails upgrade approach

1. [Prepare an MR for GitLab](#prepare-an-mr-for-gitlab).
1. [Create patch releases and backports for security patches](#create-patch-releases-and-backports-for-security-patches).

### Prepare an MR for GitLab

1. Check the [Upgrading Ruby on Rails](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) guide and prepare the application for the upcoming changes.
1. Update the `rails` gem version in `Gemfile`.
1. Run `bundle update --conservative rails`.
1. For major and minor version updates, run `bin/rails app:update` and check if any of the suggested changes should be applied.
1. Update the `activesupport` version in `qa/Gemfile`.
1. Run `bundle update --conservative activesupport` in the `qa` folder.
1. Update the `activerecord_version` version in `vendor/gems/attr_encrypted/attr_encrypted.gemspec`.
1. Run `bundle update --conservative activerecord` in the `vendor/gems/attr_encrypted` folder.
1. Run `find gems -name Gemfile -exec bundle update --gemfile {}  activesupport --patch --conservative \;` and replace `--patch` in the command with `--minor` or `--major` as needed.
1. Resolve any Bundler conflicts.
1. Ensure that `@rails/ujs` and `@rails/actioncable` npm packages match the new rails version in [`package.json`](https://gitlab.com/gitlab-org/gitlab/blob/master/package.json).
1. Run `yarn patch-package @rails/ujs` after updating this to ensure our local patch file version matches.
1. Create an MR with the `pipeline:run-all-rspec` label and see if pipeline breaks.
1. To resolve and debug spec failures use `git bisect` against the rails repository. See the [debugging section](#git-bisect-against-rails) below.
1. Include links to the Gem diffs between the two versions in the merge request description. For example, this is the gem diff for
   [`activesupport` 6.1.3.2 to 6.1.4.1](https://my.diffend.io/gems/activerecord/6.1.3.2/6.1.4.1).

### Prepare an MR for Gitaly

No longer necessary as Gitaly no longer has Ruby code.

### Create patch releases and backports for security patches

If the Rails upgrade was over a patch release and it contains important security fixes,
make sure to release it in a
GitLab patch release to self-managed customers. Consult with our [release managers](https://about.gitlab.com/community/release-managers/)
for how to proceed.

### Deprecation Logger

We also log Ruby and Rails deprecation warnings into a dedicated log file, `log/deprecation_json.log`. It provides
clues when there is code that is not adequately covered by tests and hence would slip past `DeprecationToolkitEnv`.

For GitLab SaaS, GitLab team members can inspect these log events in Kibana (`https://log.gprd.gitlab.net/goto/f7cebf1ff05038d901ba2c45925c7e01`).

## Git bisect against Rails

Usually, if you know which Rails change caused the spec to fail, it adds additional context and
helps to find the fix for the failure.
To efficiently and quickly find which Rails change caused the spec failure you can use the
[`git bisect`](https://git-scm.com/docs/git-bisect) command against the Rails repository:

1. Clone the `rails` project in a folder of your choice. For example, it might be the GDK root dir:

   ```shell
   cd <GDK_FOLDER>
   git clone https://github.com/rails/rails.git
   ```

1. Replace the `gem 'rails'` line in GitLab `Gemfile` with:

   ```ruby
   gem 'rails', ENV['RAILS_VERSION'], path: ENV['RAILS_FOLDER']
   ```

1. Set the `RAILS_FOLDER` environment variable with the folder you cloned Rails into:

   ```shell
   export RAILS_FOLDER="<GDK_FOLDER>/rails"
   ```

1. Change the directory to `RAILS_FOLDER` and set the range for the `git bisect` command:

   ```shell
   cd $RAILS_FOLDER
   git bisect start <NEW_VERSION_TAG> <OLD_VERSION_TAG>
   ```

   Where `<NEW_VERSION_TAG>` is the tag where the spec is red and `<OLD_VERSION_TAG>` is the one with the green spec.
   For example, `git bisect start v6.1.4.1 v6.1.3.2` if we're upgrading from version 6.1.3.2 to 6.1.4.1.
   Replace `<NEW_VERSION_TAG>` with the tag where the spec is red and `<OLD_VERSION_TAG>` with the one with the green spec. For example, `git bisect start v6.1.4.1 v6.1.3.2` if we're upgrading from version 6.1.3.2 to 6.1.4.1.
   In the output, you can see how many steps approximately it takes to find the commit.
1. Start the `git bisect` process and pass spec's filenames to `scripts/rails-update-bisect` as arguments. It can be faster to pick only one example instead of an entire spec file.

   ```shell
   git bisect run <GDK_FOLDER>/gitlab/scripts/rails-update-bisect spec/models/ability_spec.rb
   # OR
   git bisect run <GDK_FOLDER>/gitlab/scripts/rails-update-bisect spec/models/ability_spec.rb:7
   ```

1. When the process is completed, `git bisect` prints the commit hash, which you can use to find the corresponding MR in the [`rails/rails`](https://github.com/rails/rails) repository.
1. Execute `git bisect reset` to exit the `bisect` mode.
1. Revert the changes to `Gemfile`:

   ```shell
   git checkout -- Gemfile
   ```

### Follow-up reading material

- [Upgrading Ruby on Rails guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Rails releases page](https://github.com/rails/rails/releases)
