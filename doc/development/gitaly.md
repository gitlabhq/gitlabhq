---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Gitaly developers guide

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is a high-level Git RPC service used by GitLab Rails,
Workhorse and GitLab Shell.

## Deep Dive

In May 2019, <!-- vale gitlab.Spelling = NO --> Bob Van Landuyt <!-- vale gitlab.Spelling = YES -->
hosted a Deep Dive (GitLab team members only: `https://gitlab.com/gitlab-org/create-stage/issues/1`)
on the [Gitaly project](https://gitlab.com/gitlab-org/gitaly). It included how to contribute to it as a
Ruby developer, and shared domain-specific knowledge with anyone who may work in this part of the
codebase in the future.

You can find the <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [recording on YouTube](https://www.youtube.com/watch?v=BmlEWFS8ORo), and the slides
on [Google Slides](https://docs.google.com/presentation/d/1VgRbiYih9ODhcPnL8dS0W98EwFYpJ7GXMPpX-1TM6YE/edit)
and in [PDF](https://gitlab.com/gitlab-org/create-stage/uploads/a4fdb1026278bda5c1c5bb574379cf80/Create_Deep_Dive__Gitaly_for_Create_Ruby_Devs.pdf).

Everything covered in this deep dive was accurate as of GitLab 11.11, and while specific details may
have changed, it should still serve as a good introduction.

## Beginner's guide

Start by reading the Gitaly repository's
[Beginner's guide to Gitaly contributions](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/beginners_guide.md).
It describes how to set up Gitaly, the various components of Gitaly and what
they do, and how to run its test suites.

## Developing new Git features

To read or write Git data, a request has to be made to Gitaly. This means that
if you're developing a new feature where you need data that's not yet available
in `lib/gitlab/git` changes have to be made to Gitaly.

There should be no new code that touches Git repositories via disk access (for example,
Rugged, `git`, `rm -rf`) anywhere in the `gitlab` repository. Anything that
needs direct access to the Git repository *must* be implemented in Gitaly, and
exposed via an RPC.

It's often easier to develop a new feature in Gitaly if you make the changes to
GitLab that intends to use the new feature in a separate merge request, to be merged
immediately after the Gitaly one. This allows you to test your changes before
they are merged.

- See [below](#running-tests-with-a-locally-modified-version-of-gitaly) for instructions on running GitLab tests with a modified version of Gitaly.
- In GDK run `gdk install` and restart `gdk run` (or `gdk run app`) to use a locally modified Gitaly version for development

### `gitaly-ruby`

It is possible to implement and test RPC's in Gitaly using Ruby code,
in
[`gitaly-ruby`](https://gitlab.com/gitlab-org/gitaly/tree/master/ruby).
This should make it easier to contribute for developers who are less
comfortable writing Go code.

There is documentation for this approach in [the Gitaly
repository](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/ruby_endpoint.md).

## Gitaly-Related Test Failures

If your test-suite is failing with Gitaly issues, as a first step, try running:

```shell
rm -rf tmp/tests/gitaly
```

During RSpec tests, the Gitaly instance writes logs to `gitlab/log/gitaly-test.log`.

## Legacy Rugged code

While Gitaly can handle all Git access, many of GitLab customers still
run Gitaly atop NFS. The legacy Rugged implementation for Git calls may
be faster than the Gitaly RPC due to N+1 Gitaly calls and other
reasons. See [the
issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/57317) for more
details.

Until GitLab has eliminated most of these inefficiencies or the use of
NFS is discontinued for Git data, Rugged implementations of some of the
most commonly-used RPCs can be enabled via feature flags:

- `rugged_find_commit`
- `rugged_get_tree_entries`
- `rugged_tree_entry`
- `rugged_commit_is_ancestor`
- `rugged_commit_tree_entry`
- `rugged_list_commits_by_oid`

A convenience Rake task can be used to enable or disable these flags
all together. To enable:

```shell
bundle exec rake gitlab:features:enable_rugged
```

To disable:

```shell
bundle exec rake gitlab:features:disable_rugged
```

Most of this code exists in the `lib/gitlab/git/rugged_impl` directory.

NOTE:
You should *not* need to add or modify code related to
Rugged unless explicitly discussed with the
[Gitaly Team](https://gitlab.com/groups/gl-gitaly/group_members). This code does
NOT work on GitLab.com or other GitLab instances that do not use NFS.

## `TooManyInvocationsError` errors

During development and testing, you may experience `Gitlab::GitalyClient::TooManyInvocationsError` failures.
The `GitalyClient` attempts to block against potential n+1 issues by raising this error
when Gitaly is called more than 30 times in a single Rails request or Sidekiq execution.

As a temporary measure, export `GITALY_DISABLE_REQUEST_LIMITS=1` to suppress the error. This disables the n+1 detection
in your development environment.

Please raise an issue in the GitLab CE or EE repositories to report the issue. Include the labels ~Gitaly
~performance ~"technical debt". Please ensure that the issue contains the full stack trace and error message of the
`TooManyInvocationsError`. Also include any known failing tests if possible.

Isolate the source of the n+1 problem. This is normally a loop that results in Gitaly being called for each
element in an array. If you are unable to isolate the problem, please contact a member
of the [Gitaly Team](https://gitlab.com/groups/gl-gitaly/group_members) for assistance.

After the source has been found, wrap it in an `allow_n_plus_1_calls` block, as follows:

```ruby
# n+1: link to n+1 issue
Gitlab::GitalyClient.allow_n_plus_1_calls do
  # original code
  commits.each { |commit| ... }
end
```

After the code is wrapped in this block, this code path is excluded from n+1 detection.

## Request counts

Commits and other Git data, is now fetched through Gitaly. These fetches can,
much like with a database, be batched. This improves performance for the client
and for Gitaly itself and therefore for the users too. To keep performance stable
and guard performance regressions, Gitaly calls can be counted and the call count
can be tested against. This requires the `:request_store` flag to be set.

```ruby
describe 'Gitaly Request count tests' do
  context 'when the request store is activated', :request_store do
    it 'correctly counts the gitaly requests made' do
      expect { subject }.to change { Gitlab::GitalyClient.get_request_count }.by(10)
    end
  end
end
```

## Running tests with a locally modified version of Gitaly

Normally, GitLab CE/EE tests use a local clone of Gitaly in
`tmp/tests/gitaly` pinned at the version specified in
`GITALY_SERVER_VERSION`. The `GITALY_SERVER_VERSION` file supports also
branches and SHA to use a custom commit in [the repository](https://gitlab.com/gitlab-org/gitaly).

NOTE:
With the introduction of auto-deploy for Gitaly, the format of
`GITALY_SERVER_VERSION` was aligned with Omnibus syntax.
It no longer supports `=revision`, it evaluates the file content as a Git
reference (branch or SHA). Only if it matches a semantic version does it prepend a `v`.

If you want to run tests locally against a modified version of Gitaly you
can replace `tmp/tests/gitaly` with a symlink. This is much faster
because it avoids a Gitaly re-install each time you run `rspec`.

Make sure this directory contains the files `config.toml` and `praefect.config.toml`.
You can copy them from `config.toml.example` and `config.praefect.toml.example` respectively.
After copying, make sure to edit them so everything points to the correct paths.

```shell
rm -rf tmp/tests/gitaly
ln -s /path/to/gitaly tmp/tests/gitaly
```

Make sure you run `make` in your local Gitaly directory before running
tests. Otherwise, Gitaly fails to boot.

If you make changes to your local Gitaly in between test runs you need
to manually run `make` again.

Note that CI tests do not use your locally modified version of
Gitaly. To use a custom Gitaly version in CI you need to update
GITALY_SERVER_VERSION as described at the beginning of this section.

To use a different Gitaly repository, such as if your changes are present
on a fork, you can specify a `GITALY_REPO_URL` environment variable when
running tests:

```shell
GITALY_REPO_URL=https://gitlab.com/nick.thomas/gitaly bundle exec rspec spec/lib/gitlab/git/repository_spec.rb
```

If your fork of Gitaly is private, you can generate a [Deploy Token](../user/project/deploy_tokens/index.md)
and specify it in the URL:

```shell
GITALY_REPO_URL=https://gitlab+deploy-token-1000:token-here@gitlab.com/nick.thomas/gitaly bundle exec rspec spec/lib/gitlab/git/repository_spec.rb
```

To use a custom Gitaly repository in CI/CD, for instance if you want your
GitLab fork to always use your own Gitaly fork, set `GITALY_REPO_URL`
as a [CI/CD variable](../ci/variables/index.md).

### Use a locally modified version of Gitaly RPC client

If you are making changes to the RPC client, such as adding a new endpoint or adding a new
parameter to an existing endpoint, follow the guide for
[Gitaly protobuf specifications](https://gitlab.com/gitlab-org/gitaly/blob/master/proto/README.md). After pushing
the branch with the changes (`new-feature-branch`, for example):

1. Change the `gitaly` line in the Rails' `Gemfile` to:

   ```ruby
   gem 'gitaly', git: 'https://gitlab.com/gitlab-org/gitaly.git', branch: 'new-feature-branch'
   ```

1. Run `bundle install` to use the modified RPC client.

Re-run `bundle install` in the `gitlab` project each time the Gitaly branch
changes to embed a new SHA in the `Gemfile.lock` file.

---

[Return to Development documentation](index.md)

## Wrapping RPCs in Feature Flags

Here are the steps to gate a new feature in Gitaly behind a feature flag.

### Gitaly

1. Create a package scoped flag name:

   ```golang
   var findAllTagsFeatureFlag = "go-find-all-tags"
   ```

1. Create a switch in the code using the `featureflag` package:

   ```golang
   if featureflag.IsEnabled(ctx, findAllTagsFeatureFlag) {
     // go implementation
   } else {
     // ruby implementation
   }
   ```

1. Create Prometheus metrics:

   ```golang
   var findAllTagsRequests = prometheus.NewCounterVec(
     prometheus.CounterOpts{
       Name: "gitaly_find_all_tags_requests_total",
       Help: "Counter of go vs ruby implementation of FindAllTags",
     },
     []string{"implementation"},
   )

   func init() {
     prometheus.Register(findAllTagsRequests)
   }

   if featureflag.IsEnabled(ctx, findAllTagsFeatureFlag) {
     findAllTagsRequests.WithLabelValues("go").Inc()
     // go implementation
   } else {
     findAllTagsRequests.WithLabelValues("ruby").Inc()
     // ruby implementation
   }
   ```

1. Set headers in tests:

   ```golang
   import (
     "google.golang.org/grpc/metadata"

     "gitlab.com/gitlab-org/gitaly/internal/featureflag"
   )

   //...

   md := metadata.New(map[string]string{featureflag.HeaderKey(findAllTagsFeatureFlag): "true"})
   ctx = metadata.NewOutgoingContext(context.Background(), md)

   c, err = client.FindAllTags(ctx, rpcRequest)
   require.NoError(t, err)
   ```

### GitLab Rails

Test in a Rails console by setting the feature flag:

```ruby
Feature.enable('gitaly_go_find_all_tags')
```

Pay attention to the name of the flag and the one used in the Rails console. There is a difference
between them (dashes replaced by underscores and name prefix is changed). Make sure to prefix all
flags with `gitaly_`.

NOTE:
If not set in GitLab, feature flags are read as false from the console and Gitaly uses their
default value. The default value depends on the GitLab version.

### Testing with GDK

To be sure that the flag is set correctly and it goes into Gitaly, you can check
the integration by using GDK:

1. The state of the flag must be observable. To check it, you need to enable it
   by fetching the Prometheus metrics:
   1. Navigate to GDK's root directory.
   1. Make sure you have the proper branch checked out for Gitaly.
   1. Recompile it with `make gitaly-setup` and restart the service with `gdk restart gitaly`.
   1. Make sure your setup is running: `gdk status | grep praefect`.
   1. Check what configuration file is used: `cat ./services/praefect/run | grep praefect` value of the `-config` flag
   1. Uncomment `prometheus_listen_addr` in the configuration file and run `gdk restart gitaly`.

1. Make sure that the flag is not enabled yet:
   1. Perform whatever action is required to trigger your changes, such as project creation,
      submitting commit, or observing history.
   1. Check that the list of current metrics has the new counter for the feature flag:

      ```shell
      curl --silent "http://localhost:9236/metrics" | grep go_find_all_tags
      ```

1. After you observe the metrics for the new feature flag and it increments, you
   can enable the new feature:
   1. Navigate to GDK's root directory.
   1. Start a Rails console:

      ```shell
      bundle install && bundle exec rails console
      ```

   1. Check the list of feature flags:

      ```ruby
      Feature::Gitaly.server_feature_flags
      ```

      It should be disabled `"gitaly-feature-go-find-all-tags"=>"false"`.
   1. Enable it:

      ```ruby
      Feature.enable('gitaly_go_find_all_tags')
      ```

   1. Exit the Rails console and perform whatever action is required to trigger
      your changes, such as project creation, submitting commit, or observing history.
   1. Verify the feature is on by observing the metrics for it:

      ```shell
      curl --silent "http://localhost:9236/metrics" | grep go_find_all_tags
      ```
