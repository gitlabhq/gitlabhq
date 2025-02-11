---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Ruby upgrade guidelines
---

We strive to run GitLab using the latest Ruby MRI releases to benefit from performance and
security updates and new Ruby APIs. When upgrading Ruby across GitLab, we should do
so in a way that:

- Is least disruptive to contributors.
- Optimizes for GitLab SaaS availability.
- Maintains Ruby version parity across all parts of GitLab.

Before making changes to Ruby versions, read through this document carefully and entirely to get a high-level
understanding of what changes may be necessary. It is likely that every Ruby upgrade is a little
different than the one before it, so assess the order and necessity of the documented
steps.

## Scope of a Ruby upgrade

The first thing to consider when upgrading Ruby is scope. In general, we consider
the following areas in which Ruby updates may have to occur:

- The main GitLab Rails repository.
- Any ancillary Ruby system repositories.
- Any third-party libraries used by systems in these repositories.
- Any GitLab libraries used by systems in these repositories.

We may not always have to touch all of these. For instance, a patch-level Ruby update is
unlikely to require updates in third-party gems.

### Patch, minor, and major upgrades

When assessing scope, the Ruby version level matters. For instance, it is harder and riskier
to upgrade GitLab from Ruby 2.x to 3.x than it is to upgrade from Ruby 2.7.2 to 2.7.4, as
patch releases are typically restricted to security or bug fixes.
Be aware of this when preparing an upgrade and plan accordingly.

To help you estimate the scope of future upgrades, see the efforts required for the following upgrades:

- [Patch upgrade 2.7.2 -> 2.7.4](https://gitlab.com/gitlab-org/gitlab/-/issues/335890)
- [Minor upgrade 2.6.x -> 2.7.x](https://gitlab.com/groups/gitlab-org/-/epics/2380)
- [Major upgrade 2.x.x -> 3.x.x](https://gitlab.com/groups/gitlab-org/-/epics/5149)

## Affected audiences and targets

Before any upgrade, consider all audiences and targets, ordered by how immediately they are affected by Ruby upgrades:

1. **Developers.** We have many contributors to GitLab and related projects both inside and outside the company. Changing files such as `.ruby-version` affects everyone using tooling that interprets these files.
   The developers are affected as soon as they pull from the repository containing the merged changes.
1. **GitLab CI/CD.** We heavily lean on CI/CD for code integration and testing. CI/CD jobs do not interpret files such as `.ruby-version`.
   Instead, they use the Ruby installed in the Docker container they execute in, which is defined in `.gitlab-ci.yml`.
   The container images used in these jobs are maintained in the [`gitlab-build-images`](https://gitlab.com/gitlab-org/gitlab-build-images) repository.
   When we merge an update to an image, CI/CD jobs are affected as soon as the [image is built](https://gitlab.com/gitlab-org/gitlab-build-images/#pushing-a-rebuild-image).
1. **GitLab SaaS**. GitLab.com is deployed from customized Helm charts that use Docker images from [Cloud Native GitLab (CNG)](https://gitlab.com/gitlab-org/build/CNG).
   Just like CI/CD, `.ruby-version` is meaningless in this environment. Instead, those Docker images must be patched to upgrade Ruby.
   GitLab SaaS is affected with the next deployment.
1. **GitLab Self-Managed.** Customers installing GitLab via [Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab) use none of the above.
   Instead, their Ruby version is defined by the [Ruby software bundle](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/config/software/ruby.rb) in Omnibus.
   Self-managed customers are affected as soon as they upgrade to the release containing this change.

## Ruby upgrade approach

Timing all steps in a Ruby upgrade correctly is critical. As a general guideline, consider the following:

- For smaller upgrades where production behavior is unlikely to change, aim to keep the version gap between
  repositories and production minimal. Coordinate with stakeholders to merge all changes closely together
  (within a day or two) to avoid drift. In this scenario the likely order is to upgrade developer tooling and
  environments first, production second.
- For larger changes, the risk of going to production with a new Ruby is significant. In this case, try to get into a
  position where all known incompatibilities with the new Ruby version are already fixed, then work
  with production engineers to deploy the new Ruby to a subset of the GitLab production fleet. In this scenario
  the likely order is to update production first, developer tooling and environments second. This makes rollbacks
  easier in case of critical regressions in production.

Either way, we found that from past experience the following approach works well, with some steps likely only
necessary for minor and major upgrades. Note that some of these steps can happen in parallel or may have their
order reversed as described above.

### Create an epic

Tracking this work in an epic is useful to get a sense of progress. For larger upgrades, include a
timeline in the epic description so stakeholders know when the final switch is expected to go live.
Include the designated [performance testing template](https://gitlab.com/gitlab-org/quality/performance-testing/ruby-rollout-performance-testing)
to help ensure performance standards on the upgrade.

Break changes to individual repositories into separate issues under this epic.

### Communicate the intent to upgrade

Especially for upgrades that introduce or deprecate features,
communicate early that an upgrade is due, ideally with an associated timeline. Provide links to important or
noteworthy changes, so developers can start to familiarize themselves with
changes ahead of time.

GitLab team members should announce the intent in relevant Slack channels (`#backend` and `#development` at minimum)
and Engineering Week In Review (EWIR). Include a link to the upgrade epic in your
[communication](https://handbook.gitlab.com/handbook/engineering/engineering-comms/#keeping-yourself-informed).

### Add new Ruby to CI/CD and development environments

To build and run Ruby gems and the GitLab Rails application with a new Ruby, you must first prepare CI/CD
and developer environments to include the new Ruby version.
At this stage, you *must not make it the default Ruby yet*, but make it optional instead. This allows
for a smoother transition by supporting both old and new Ruby versions for a period of time.

There are two places that require changes:

1. **[GitLab Build Images](https://gitlab.com/gitlab-org/gitlab-build-images).** These are Docker images
   we use for runners and other Docker-based pre-production environments. The kind of change necessary
   depends on the scope.
   - For [patch level updates](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/418), it should suffice to increment the patch level of `RUBY_VERSION`.
     All projects building against the same minor release automatically download the new patch release.
   - For [major and minor updates](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/320), create a new set of Docker images that can be used side-by-side with existing images during the upgrade process. **Important:** Make sure to copy over all Ruby patch files
     in the `/patches` directory to a new folder matching the Ruby version you upgrade to, or they aren't applied.
1. **[GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).**
   Update GDK to add the new Ruby as an additional option for
   developers to choose from. This typically only requires it to be appended to `.tool-versions` so `asdf`
   users will benefit from this. Other users will have to install it manually
   ([example](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/2136).)

For larger version upgrades, consider working with [Quality Engineering](https://handbook.gitlab.com/handbook/engineering/quality/)
to identify and set up a test plan.

### Update third-party gems

For patch releases this is unlikely to be necessary, but
for minor and major releases, there could be breaking changes or Bundler dependency issues when gems
pin Ruby to a particular version. A good way to find out is to create a merge request in `gitlab-org/gitlab`
and see what breaks.

### Update GitLab gems and related systems

This is typically necessary, since gems or Ruby applications that we maintain ourselves contain the build setup such as
`.ruby-version`, `.tool-versions`, or `.gitlab-ci.yml` files. While there isn't always a technical necessity to
update these repositories for the GitLab Rails application to work with a new Ruby,
it is good practice to keep Ruby versions in lock-step across all our repositories. For minor and major
upgrades, add new CI/CD jobs to these repositories using the new Ruby.
A [build matrix definition](../ci/yaml/_index.md#parallelmatrix) can do this efficiently.

#### Decide which repositories to update

When upgrading Ruby, consider updating the repositories in the [`ruby/gems` group](https://gitlab.com/gitlab-org/ruby/gems/) as well.
For reference, here is a list of merge requests that have updated Ruby for some of these projects in the past:

- [GitLab LabKit](https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby) ([example](https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby/-/merge_requests/79))
- [GitLab Exporter](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter) ([example](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter/-/merge_requests/150))
- [GitLab Experiment](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment) ([example](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment/-/merge_requests/128))
- [Gollum Lib](https://gitlab.com/gitlab-org/ruby/gems/gollum-lib) ([example](https://gitlab.com/gitlab-org/ruby/gems/gollum-lib/-/merge_requests/21))
- [GitLab Sidekiq fetcher](https://gitlab.com/gitlab-org/ruby/gems/sidekiq-reliable-fetch) ([example](https://gitlab.com/gitlab-org/ruby/gems/sidekiq-reliable-fetch/-/merge_requests/33))
- [Prometheus Ruby Mmap Client](https://gitlab.com/gitlab-org/ruby/gems/prometheus-client-mmap) ([example](https://gitlab.com/gitlab-org/ruby/gems/prometheus-client-mmap/-/merge_requests/59))
- [GitLab-mail_room](https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room) ([example](https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room/-/merge_requests/16))

To assess which of these repositories are critical to be updated alongside the main GitLab application consider:

- The Ruby version scope.
- The role that the service or library plays in the overall functioning of GitLab.

Refer to the [list of GitLab projects](https://handbook.gitlab.com/handbook/engineering/projects/) for a complete
account of which repositories could be affected.
For smaller version upgrades, it can be acceptable to delay updating libraries that are non-essential or where
we are certain that the main application test suite would catch regressions under a new Ruby version.

NOTE:
Consult with the respective code owners whether it is acceptable to merge these changes ahead
of updating the GitLab application. It might be best to get the necessary approvals
but wait to merge the change until everything is ready.

### Prepare the GitLab application MR

With the dependencies updated and the new gem versions released, you can update the main Rails
application with any necessary changes, similar to the gems and related systems.
On top of that, update the documentation to reflect the version change in the installation
and update instructions ([example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68363)).

NOTE:
Be especially careful with timing this merge request, since as soon as it is merged, all GitLab contributors
will be affected by it and the changes will be deployed. You must ensure that this MR remains
open until everything else is ready, but it can be useful to get approval early to reduce lead time.

### Give developers time to upgrade (grace period)

With the new Ruby made available as an option, and all merge requests either ready or merged,
there should be a grace period (1 week at minimum) during which developers can
install the new Ruby on their machines. For GDK and `asdf` users this should happen automatically
via `gdk update`.

This pause is a good time to assess the risk of this upgrade for GitLab SaaS.
For Ruby upgrades that are high risk, such as major version upgrades, it is recommended to
coordinate the changes with the infrastructure team through a [change management request](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/).
Create this issue early to give everyone enough time to schedule and prepare changes.

### Make it the default Ruby

If there are no known version compatibility issues left, and the grace
period has passed, all affected repositories and developer tools should be updated to make the new Ruby
default.

At this point, update the [GitLab Compose Kit (GCK)](https://gitlab.com/gitlab-org/gitlab-compose-kit).
This is an alternative development environment for users that prefer to run GitLab in `docker-compose`.
This project relies on the same Docker images as our runners, so it should maintain parity with changes
in that repository. This change is only necessary when the minor or major version changes
([example](https://gitlab.com/gitlab-org/gitlab-compose-kit/-/merge_requests/176).)

As mentioned above, if the impact of the Ruby upgrade on SaaS availability is uncertain, it is
prudent to skip this step until you have verified that it runs smoothly in production via a staged
rollout. In this case, go to the next step first, and then, after the verification period has passed, promote
the new Ruby to be the new default.

### Update CNG, Omnibus, Self-compiled and merge the GitLab MR

The last step is to use the new Ruby in production. This
requires updating Omnibus and production Docker images to use the new version.

To use the new Ruby in production, update the following projects:

- [Cloud-native GitLab Docker Images (CNG)](https://gitlab.com/gitlab-org/build/CNG) ([example](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/739))
- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) ([example](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5545))
- [Self-compiled installations](../install/installation.md): update the [Ruby system version check](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/system_check/app/ruby_version_check.rb)

Charts like the [GitLab Helm Chart](https://gitlab.com/gitlab-org/charts/gitlab) should also be updated if
they use Ruby in some capacity, for example
to run tests (see [this example](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2162)), though
this may not strictly be necessary.

If you submit a change management request, coordinate the rollout with infrastructure
engineers. When dealing with larger upgrades, involve [Release Managers](https://about.gitlab.com/community/release-managers/)
in the rollout plan.

### Create patch releases and backports for security patches

If the upgrade was a patch release and contains important security fixes, it should be released as a
GitLab patch release to self-managed customers. Consult our [release managers](https://about.gitlab.com/community/release-managers/)
for how to proceed.

## Ruby upgrade tooling

There are several tools that ease the upgrade process.

### Deprecation Toolkit

A common problem with Ruby upgrades is that deprecation warnings turn into errors. This means that every single
deprecation warning must be resolved before making the switch. To avoid new warnings from making it into the
main application branch, we use [`DeprecationToolkitEnv`](https://gitlab.com/gitlab-org/gitlab/blob/master/spec/deprecation_toolkit_env.rb).
This module observes deprecation warnings emitted from spec runs and turns them into test failures. This prevents
developers from checking in new code that would fail under a new Ruby.

Sometimes it cannot be avoided to introduce new warnings, for example when a Ruby gem we use emits these warnings
and we have no control over it. In these cases, add silences, like [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68865) did.

### Deprecation Logger

We also log Ruby and Rails deprecation warnings to a dedicated log file, `log/deprecation_json.log`
(see [GitLab Developers Guide to Logging](logging.md) for where to find GitLab log files),
which can provide clues when there is code that is not adequately covered by tests and hence would slip past `DeprecationToolkitEnv`.

For GitLab SaaS, GitLab team members can inspect these log events in Kibana
(`https://log.gprd.gitlab.net/goto/f7cebf1ff05038d901ba2c45925c7e01`).

## Recommendations

During the upgrade process, consider the following recommendations:

- **Front-load as many changes as possible.** Especially for minor and major releases, it is likely that application
  code will break or change. Any changes that are backward compatible should be merged into the main branch and
  released independently ahead of the Ruby version upgrade. This ensures that we move in small increments and
  get feedback from production environments early.
- **Create an experimental branch for larger updates.** We generally try to avoid long-running topic branches,
  but for purposes of feedback and experimentation, it can be useful to have such a branch to get regular
  feedback from CI/CD when running a newer Ruby. This can be helpful when first assessing what problems
  we might run into, as [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50640) demonstrates.
  These experimental branches are not intended to be merged; they can be closed once all required changes have been broken out
  and merged back independently.
- **Give yourself enough time to fix problems ahead of a milestone release.** GitLab moves fast.
  As a Ruby upgrade requires many MRs to be sent and reviewed, make sure all changes are merged at least a week
  before release day. This gives us extra time to act if something breaks. If in doubt, it is better to
  postpone the upgrade to the following month, as we [prioritize availability over velocity](https://handbook.gitlab.com/handbook/engineering/development/principles/#prioritizing-technical-decisions).
