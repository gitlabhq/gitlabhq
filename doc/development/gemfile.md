---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Gemfile development guidelines

When adding a new entry to `Gemfile`, or upgrading an existing dependency pay
attention to the following rules.

## Bundler checksum verification

In [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98508), gem
checksums are checked before installation. This verification is still
experimental so it is only active for CI.

If the downloaded gem's checksum does not match the checksum record in
`Gemfile.checksum`, you will see an error saying that Bundler cannot continue
installing a gem because there is a potential security issue.

You will see this error as well if you updated, or added a new gem without
updating `Gemfile.checksum`. To fix this error,
[update the Gemfile.checksum](#updating-the-checksum-file).

You can opt-in to this verification locally by setting the
`BUNDLER_CHECKSUM_VERIFICATION_OPT_IN` environment variable:

```shell
export BUNDLER_CHECKSUM_VERIFICATION_OPT_IN=1
bundle install
```

Setting it to `false` can also disable it:

```shell
export BUNDLER_CHECKSUM_VERIFICATION_OPT_IN=false
bundle install
```

### Updating the checksum file

This needs to be done for any new, or updated gems.

1. When updating `Gemfile.lock`, make sure to also update `Gemfile.checksum` with:

   ```shell
   bundle exec bundler-checksum init
   ```

1. Check and commit the changes for `Gemfile.checksum`.

## No gems fetched from Git repositories

We do not allow gems that are fetched from Git repositories. All gems have
to be available in the RubyGems index. We want to minimize external build
dependencies and build times. It's enforced by the RuboCop rule
[`Cop/GemFetcher`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-styles/-/blob/master/lib/rubocop/cop/gem_fetcher.rb).

## Review the new dependency for quality

We should not add 3rd-party dependencies to GitLab that would not pass our own quality standards.
This means that new dependencies should, at a minimum, meet the following criteria:

- They have an active developer community. At the minimum a maintainer should still be active
  to merge change requests in case of emergencies.
- There are no issues open that we know may impact the availability or performance of GitLab.
- The project is tested using some form of test automation. The test suite must be passing
  using the Ruby version currently used by GitLab.
- CI builds for all supported platforms must succeed using the new dependency. For more information, see
  how to [build a package for testing](build_test_package.md#building-a-package-for-testing).
- If the project uses a C extension, consider requesting an additional review from a C or MRI
  domain expert. C extensions can greatly impact GitLab stability and performance.

## Gems that require a domain expert approval

Changes to the following gems require a domain expert review and approval by a backend team member of the group.

For gems not listed in this table, it's still recommended but not required that you find a domain expert to review changes.

| Gem | Requires approval by |
| ------ | ------ |
| `doorkeeper` | [Manage:Authentication and Authorization](https://about.gitlab.com/handbook/product/categories/#authentication-and-authorization-group) |
| `doorkeeper-openid_connect` | [Manage:Authentication and Authorization](https://about.gitlab.com/handbook/product/categories/#authentication-and-authorization-group)  |

## Request an Appsec review

When adding a new gem to our `Gemfile` or even changing versions in
`Gemfile.lock` it is strongly recommended that you
[request a Security review](https://about.gitlab.com/handbook/security/#how-to-request-a-security-review).
New gems add an extra security risk for GitLab, and it is important to
evaluate this risk before we ship this to production. Technically, just adding
a new gem and pushing to a branch in our main `gitlab` project is a security
risk as it will run in CI using your GitLab.com credentials. As such you should
evaluate early on if you think this gem seems legitimate before you even
install it.

Reviewers should also be aware of our related
[recommendations for reviewing community contributions](code_review.md#community-contributions)
and take care before running a pipeline for community contributions that
contains changes to `Gemfile` or `Gemfile.lock`.

## License compliance

Refer to [licensing guidelines](licensing.md) for ensuring license compliance.

## GitLab-created gems

Sometimes we create libraries within our codebase that we want to
extract, either because we want to use them in other applications
ourselves, or because we think it would benefit the wider community.
Extracting code to a gem also means that we can be sure that the gem
does not contain any hidden dependencies on our application code.

In general, we want to think carefully before doing this as there are
also disadvantages:

### Potential disadvantages

1. Gems - even those maintained by GitLab - do not necessarily go
   through the same [code review process](code_review.md) as the main
   Rails application.
1. Extracting the code into a separate project means that we need a
   minimum of two merge requests to change functionality: one in the gem
   to make the functional change, and one in the Rails app to bump the
   version.
1. Our needs for our own usage of the gem may not align with the wider
   community's needs. In general, if we are not using the latest version
   of our own gem, that might be a warning sign.

### Create and publish a Ruby gem

In the case where we do want to extract some library code we've written
to a gem, go through these steps:

1. Determine a suitable name for the gem. If it's a GitLab-owned gem, prefix
   the gem name with `gitlab-`. For example, `gitlab-sidekiq-fetcher`.
1. Create the gem or fork as necessary.
1. Ensure the `gitlab_rubygems` group is an owner of the new gem by running:

   ```shell
   gem owner <gem-name> --add gitlab_rubygems
   ```

1. [Publish the gem to rubygems.org](https://guides.rubygems.org/publishing/#publishing-to-rubygemsorg)
1. Visit `https://rubygems.org/gems/<gem-name>` and verify that the gem published
   successfully and `gitlab_rubygems` is also an owner.
1. Start with the code in the Rails application. Here it's fine to have
   the code in `lib/` and loaded automatically. We can skip this step if
   the step below makes more sense initially.
1. Before extracting to its own project, move the gem to `vendor/gems` and
   load it in the `Gemfile` using the `path` option. This gives us a gem
   that can be published to RubyGems.org, with its own test suite and
   isolated set of dependencies, that is still in our main code tree and
   goes through the standard code review process.
   - For an example, see the [merge request !57805](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57805).
1. Once the gem is stable - we have been using it in production for a
   while with few, if any, changes - extract to its own project under
   the [`gitlab-org/ruby/gems` namespace](https://gitlab.com/gitlab-org/ruby/gems/).

   - To create this project:
       1. Follow the [instructions for new projects](https://about.gitlab.com/handbook/engineering/gitlab-repositories/#creating-a-new-project).
       1. Follow the instructions for setting up a [CI/CD configuration](https://about.gitlab.com/handbook/engineering/gitlab-repositories/#cicd-configuration).
       1. Follow the instructions for [publishing a project](https://about.gitlab.com/handbook/engineering/gitlab-repositories/#publishing-a-project).
   - See [issue #325463](https://gitlab.com/gitlab-org/gitlab/-/issues/325463)
     for an example.
   - In some cases we may want to move a gem to its own namespace. Some
     examples might be that it will naturally have more than one project
     (say, something that has plugins as separate libraries), or that we
     expect non-GitLab-team-members to be maintainers on this project as
     well as GitLab team members.

     The latter situation (maintainers from outside GitLab) could also
     apply if someone who currently works at GitLab wants to maintain
     the gem beyond their time working at GitLab.

When publishing a gem to RubyGems.org, also note the section on
[gem owners](https://about.gitlab.com/handbook/developer-onboarding/#ruby-gems)
in the handbook.

## Upgrade Rails

When upgrading the Rails gem and its dependencies, you also should update the following:

- The [`Gemfile` in the `qa` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/Gemfile).
- The [`Gemfile` in Gitaly Ruby](https://gitlab.com/gitlab-org/gitaly/-/blob/master/ruby/Gemfile),
  to ensure that we ship only one version of these gems.

You should also update npm packages that follow the current version of Rails:

- `@rails/ujs`
  - Run `yarn patch-package @rails/ujs` after updating this to ensure our local patch file version matches.
- `@rails/actioncable`

## Upgrading dependencies because of vulnerabilities

When upgrading dependencies because of a vulnerability, we
should pin the minimal version of the gem in which the vulnerability
was fixed in our Gemfile to avoid accidentally downgrading.

For example, consider that the gem `license_finder` has `thor` as its
dependency. `thor` was found vulnerable until its version `1.1.1`,
which includes the vulnerability fix.

In the Gemfile, make sure to pin `thor` to `1.1.1`. The direct
dependency `license_finder` should already have the version specified.

```ruby
gem 'license_finder', '~> 6.0'
# Dependency of license_finder with fix for vulnerability
# _link to initial security issue that will become public in time_
gem 'thor', '>= 1.1.1'
```

Here we're using the operator `>=` (greater than or equal to) rather
than `~>` ([pessimistic operator](https://thoughtbot.com/blog/rubys-pessimistic-operator))
making it possible to upgrade `license_finder` or any other gem to a
version that depends on `thor 1.2`.

Similarly, if `license_finder` had a vulnerability fixed in 6.0.1, we
should add:

```ruby
gem 'license_finder', '~> 6.0', '>= 6.0.1'
```

This way, other dependencies rather than `license_finder` can
still depend on a newer version of `thor`, such as `6.0.2`, but would
not be able to depend on the vulnerable version `6.0.0`.

A downgrade like that could happen if we introduced a new dependency
that also relied on `thor` but had its version pinned to a vulnerable
one. These changes are easy to miss in the `Gemfile.lock`. Pinning the
version would result in a conflict that would need to be solved.

To avoid upgrading indirect dependencies, we can use
[`bundle update --conservative`](https://bundler.io/man/bundle-update.1.html#OPTIONS).

When submitting a merge request including a dependency update,
include a link to the Gem diff between the 2 versions in the merge request
description. You can find this link on `rubygems.org`, select
**Review Changes** to generate a comparison
between the versions on `diffend.io`. For example, this is the gem
diff for [`thor` 1.0.0 vs 1.0.1](https://my.diffend.io/gems/thor/1.0.0/1.0.1). Use the
links directly generated from RubyGems, since the links from GitLab or other code-hosting
platforms might not reflect the code that's actually published.
