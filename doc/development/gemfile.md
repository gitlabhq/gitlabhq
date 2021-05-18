---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# `Gemfile` guidelines

When adding a new entry to `Gemfile` or upgrading an existing dependency pay
attention to the following rules.

## No gems fetched from Git repositories

We do not allow gems that are fetched from Git repositories. All gems have
to be available in the RubyGems index. We want to minimize external build
dependencies and build times.

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

In the case where we do want to extract some library code we've written
to a gem, go through these steps:

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
   the `gitlab-org` namespace.
       1. When creating the project, follow the [instructions for new projects](https://about.gitlab.com/handbook/engineering/#creating-a-new-project).
       1. Follow the instructions for setting up a [CI/CD configuration](https://about.gitlab.com/handbook/engineering/#cicd-configuration).
       1. Follow the instructions for [publishing a project](https://about.gitlab.com/handbook/engineering/#publishing-a-project).
   - See [issue
     #325463](https://gitlab.com/gitlab-org/gitlab/-/issues/325463)
     for an example.
   - In some cases we may want to move a gem to its own namespace. Some
     examples might be that it will naturally have more than one project
     (say, something that has plugins as separate libraries), or that we
     expect non-GitLab-team-members to be maintainers on this project as
     well as GitLab team members.

     The latter situation (maintainers from outside GitLab) could also
     apply if someone who currently works at GitLab wants to maintain
     the gem beyond their time working at GitLab.

When publishing a gem to RubyGems.org, also note the section on [gem
owners](https://about.gitlab.com/handbook/developer-onboarding/#ruby-gems)
in the handbook.

## Upgrade Rails

When upgrading the Rails gem and its dependencies, you also should update the following:

- The [`Gemfile` in the `qa` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/Gemfile).
- The [`Gemfile` in Gitaly Ruby](https://gitlab.com/gitlab-org/gitaly/-/blob/master/ruby/Gemfile),
  to ensure that we ship only one version of these gems.

You should also update npm packages that follow the current version of Rails:

- `@rails/ujs`
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
than `~>` ([pessimistic
operator](https://thoughtbot.com/blog/rubys-pessimistic-operator))
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

To avoid upgrading indirect dependencies, we can use [`bundle update
--conservative`](https://bundler.io/man/bundle-update.1.html#OPTIONS).

When submitting a merge request including a dependency update,
include a link to the Gem diff between the 2 versions in the merge request
description. You can find this link on `rubygems.org` under
**Review Changes**. When you click it, RubyGems generates a comparison
between the versions on `diffend.io`. For example, this is the gem
diff for [`thor` 1.0.0 vs
1.0.1](https://my.diffend.io/gems/thor/1.0.0/1.0.1). Use the
links directly generated from RubyGems, since the links from GitLab or other code-hosting
platforms might not reflect the code that's actually published.
