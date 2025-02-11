---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Gems development guidelines
---

GitLab uses Gems as a tool to improve code reusability and modularity
in a monolithic codebase.

We extract libraries from our codebase when their functionality
is highly isolated and we want to use them in other applications
ourselves or we think it would benefit the wider community.

Extracting code to a gem also ensures that the gem does not contain any hidden
dependencies on our application code.

Gems should always be used when implementing functionality that can be considered isolated,
that are decoupled from the business logic of GitLab and can be developed separately.

The best place in a Rails codebase with opportunities to extract new gems
is the [lib/](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/) folder.

Our **lib/** folder is a mix of code that is generic/universal, GitLab-specific, and tightly integrated with the rest of the codebase.

In order to decide whether to extract part of the codebase as a Gem, ask yourself the following questions:

1. Is this code generic or universal that can be done as a separate and small project?
1. Do I expect it to be used internally outside of the Monolith?
1. Is this useful for the wider community that we should consider releasing as a separate component?

If the answer is **Yes** for any of the questions above, you should strongly consider creating a new Gem.

You can always start by creating a new Gem [in the same repository](#in-the-same-repo) and later evaluate whether to migrate it to a separate repository, when it is intended
to be used by a wider community.

WARNING:
To prevent malicious actors from name-squatting the extracted Gems, follow the instructions
to [reserve a gem name](#reserve-a-gem-name).

## Advantages of using Gems

Using Gems can provide several benefits for code maintenance:

- Code Reusability - Gems are isolated libraries that serve single purpose. When using Gems, a common functions
  can be isolated in a simple package, that is well documented, tested, and re-used in different applications.

- Modularity - Gems help to create isolation by encapsulating specific functionality within self-contained library.
  This helps to better organize code, better define who is owner of a given module, makes it easier to maintain
  or update specific gems.

- Small - Gems by design due to implementing isolated set of functions are small. Small projects are much easier
  to comprehend, extend and maintain.

- Testing - Using Gems since they are small makes much faster to run all tests, or be very through with testing of the gem.
  Since the gem is packaged, not changed too often, it also allows us to run those tests less frequently improving
  CI testing time.

## Gem naming

Gems can fall under three different case:

- `unique_gem`: Don't include `gitlab` in the gem name if the gem doesn't include anything specific to GitLab
- `existing_gem-gitlab`: When you fork and modify/extend a publicly available gem, add the `-gitlab` suffix, according to [Rubygems' convention](https://guides.rubygems.org/name-your-gem/)
- `gitlab-unique_gem`: Include a `gitlab-` prefix to gems that are only useful in the context of GitLab projects.

Examples of existing gems:

- `y-rb`: Ruby bindings for yrs. Yrs "wires" is a Rust port of the Yjs framework.
- `activerecord-gitlab`: Adds GitLab-specific patches to the `activerecord` public gem.
- `gitlab-rspec` and `gitlab-utils`: GitLab-specific set of classes to help in a particular context, or re-use code.

## In the same repo

**When extracting Gems from existing codebase, put them in `gems/` of the GitLab monorepo**

That gives us the advantages of gems (modular code, quicker to run tests in development).
and prevents complexity (coordinating changes across repositories, new permissions, multiple projects, etc.).

Gems stored in the same repository should be referenced in `Gemfile` with the `path:` syntax.

WARNING:
To prevent malicious actors from name-squatting the extracted Gems, follow the instructions
to [reserve a gem name](#reserve-a-gem-name).

### Create and use a new Gem

You can see example adding a new gem: [!121676](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121676).

1. Pick a good name for the gem, by following the [Gem naming](#gem-naming) convention.
1. Create the new gem in `gems/<name-of-gem>` with `bundle gem gems/<name-of-gem> --no-exe --no-coc --no-ext --no-mit`.
1. Remove the `.git` folder in `gems/<name-of-gem>` with `rm -rf gems/<name-of-gem>/.git`.
1. Edit `gems/<name-of-gem>/README.md` to provide a simple description of the Gem.
1. Edit `gems/<name-of-gem>/<name-of-gem>.gemspec` and fill the details about the Gem as in the following example:

   ```ruby
   # frozen_string_literal: true

   require_relative "lib/name/of/gem/version"

   Gem::Specification.new do |spec|
     spec.name = "<name-of-gem>"
     spec.version = Name::Of::Gem::Version::VERSION
     spec.authors = ["group::tenant-scale"]
     spec.email = ["engineering@gitlab.com"]

     spec.summary = "Gem summary"
     spec.description = "A more descriptive text about what the gem is doing."
     spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/<name-of-gem>"
     spec.license = "MIT"
     spec.required_ruby_version = ">= 3.0"
     spec.metadata["rubygems_mfa_required"] = "true"

     spec.files = Dir['lib/**/*.rb']
     spec.require_paths = ["lib"]
   end
   ```

1. Update `gems/<name-of-gem>/.rubocop.yml` with:

   ```yaml
   inherit_from:
     - ../config/rubocop.yml
   ```

1. Configure CI for a newly added Gem:

   - Add `gems/<name-of-gem>/.gitlab-ci.yml`:

     ```yaml
     include:
       - local: gems/gem.gitlab-ci.yml
         inputs:
           gem_name: "<name-of-gem>"
     ```

   - To `.gitlab/ci/gitlab-gems.gitlab-ci.yml` add:

     ```yaml
     include:
       - local: .gitlab/ci/templates/gem.gitlab-ci.yml
         inputs:
           gem_name: "<name-of-gem>"
     ```

1. Reference Gem in `Gemfile` with:

   ```ruby
   gem '<name-of-gem>', path: 'gems/<name-of-gem>'
   ```

### Specifying dependencies for the Gem

While the gem has its own `Gemfile`, in the
actual application the top-level `Gemfile` for the monolith GitLab is
used instead of the individual `Gemfile` sitting in the directory of the gem.

This means we should be aware that the `Gemfile` for the gem should not use
any versions of dependencies which might be conflicting with the top-level
`Gemfile`, and we should try to use the same dependencies if possible.

An example of this is [Rack](https://rubygems.org/gems/rack). If the monolith
is using Rack 2 and we're in the process of
[upgrading to Rack 3](https://gitlab.com/gitlab-org/gitlab/-/issues/396273),
all gems we develop should also be tested against Rack 2, optionally also with
Rack 3 if a separate `Gemfile` is used in CI. See an
[example here](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140463).

This does not limit to just Rack, but any dependencies.

### Examples of Gem extractions

The `gitlab-utils` is a Gem containing as of set of class that implement common intrinsic functions
used by GitLab developers, like `strong_memoize` or `Gitlab::Utils.to_boolean`.

The `gitlab-database-schema-migrations` is a potential Gem containing our extensions to Rails
framework improving how database migrations are stored in repository. This builds on top of Rails
and is not specific to GitLab the application, and could be generally used for other projects
or potentially be upstreamed.

The `gitlab-database-load-balancing` similar to previous is a potential Gem to implement GitLab specific
load balancing to Rails database handling. Since this is rather complex and highly specific code
maintaining its complexity in a isolated and well tested Gem would help with removing this complexity
from a big monolithic codebase.

The `gitlab-flipper` is another potential Gem implementing all our custom extensions to support feature
flags in a codebase. Over-time the monolithic codebase did grow with the check for feature flags
usage, adding consistency checks and various helpers to track owners of feature flags added. This is
not really part of GitLab business logic and could be used to better track our implementation
of Flipper and possibly much easier change it to dogfood [GitLab Feature Flags](../operations/feature_flags.md).

The `activerecord-gitlab` is a gem adding GitLab specific Active Record patches.
It is very well desired for such to be managed separately to isolate complexity.

### Other potential use cases

The `gitlab-ci-config` is a potential Gem containing all our CI code used to parse `.gitlab-ci.yml`.
This code is today lightly interlocked with GitLab the application due to lack of proper abstractions.
However, moving this to dedicated Gem could allow us to build various adapters to handle integration
with GitLab the application. The interface would for example define an adapter to resolve `includes:`.
Once we would have a `gitlab-ci-config` Gem it could be used within GitLab and outside of GitLab Rails
and [GitLab CLI](https://gitlab.com/gitlab-org/cli).

## In the external repo

In general, we want to think carefully before doing this as there are
severe disadvantages.

Gems stored in the external repository MUST be referenced in `Gemfile` with `version` syntax.
They MUST be always published to RubyGems.

### Examples

At GitLab we use a number of external gems:

- [LabKit Ruby](https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby)
- [GitLab Ruby Gems](https://gitlab.com/gitlab-org/ruby/gems)

### Potential disadvantages

- Gems - even those maintained by GitLab - do not necessarily go
  through the same [code review process](code_review.md) as the main
  Rails application. This is particularly critical for Application Security.
- Requires setting up CI/CD from scratch, including tools like Danger that
  support consistent code review standards.
- Extracting the code into a separate project means that we need a
  minimum of two merge requests to change functionality: one in the gem
  to make the functional change, and one in the Rails app to bump the
  version.
- Integration with `gitlab-rails` requiring a second MR means integration problems
  may be discovered late.
- With a smaller pool of reviewers and maintainers compared to `gitlab-rails`,
  it may take longer to get code reviewed and the impact of "bus factor" increases.
- Inconsistent workflows for how a new gem version is released. It is currently at
  the discretion of library maintainers to decide how it works.
- Promotes knowledge silos because code has less visibility and exposure than `gitlab-rails`.
- We have a well defined process for promoting GitLab reviewers to maintainers.
  This is not true for extracted libraries, increasing the risk of lowering the bar for code reviews,
  and increasing the risk of shipping a change.
- Our needs for our own usage of the gem may not align with the wider
  community's needs. In general, if we are not using the latest version
  of our own gem, that might be a warning sign.

### Potential advantages

- Faster feedback loops, since CI/CD runs against smaller repositories.
- Ability to expose the project to the wider community and benefit from external contributions.
- Repository owners are most likely the best audience to review a change, which reduces
  the necessity of finding the right reviewers in `gitlab-rails`.

### Create and publish a Ruby gem

The project for a new Gem should always be created in [`gitlab-org/ruby/gems` namespace](https://gitlab.com/gitlab-org/ruby/gems/):

1. Determine a suitable name for the gem. If it's a GitLab-owned gem, prefix
   the gem name with `gitlab-`. For example, `gitlab-sidekiq-fetcher`.
1. Locally create the gem or fork as necessary.
1. [Publish an empty `0.0.1` version of the gem to rubygems.org](https://guides.rubygems.org/publishing/#publishing-to-rubygemsorg) to ensure the gem name is reserved.
<!-- vale gitlab_base.Spelling = NO -->
1. Add the [`gitlab_rubygems`](https://rubygems.org/profiles/gitlab_rubygems) user as owner of the new gem by running:

   ```shell
   gem owner <gem-name> --add gitlab_rubygems
   ```

   - Ping [Rémy Coutable](https://gitlab.com/rymai) to confirm the ownership in the private [Rubygems committee project](https://gitlab.com/gitlab-dependency-committees/rubygems-committee/-/issues/).
1. Optional. Add some or all of the following users as co-owners:
   - [Marin Jankovski](https://rubygems.org/profiles/marinjankovski)
   - [Rémy Coutable](https://rubygems.org/profiles/rymai)
   - [Stan Hu](https://rubygems.org/profiles/stanhu)
<!-- vale gitlab_base.Spelling = YES -->
1. Optional. Add any other relevant developers as co-owners.
1. Visit `https://rubygems.org/gems/<gem-name>` and verify that the gem was published
   successfully and `gitlab_rubygems` is also an owner.
1. Create a project in the [`gitlab-org/ruby/gems` group](https://gitlab.com/gitlab-org/ruby/gems/) (or in a subgroup of it):
   1. Follow the [instructions for new projects](https://handbook.gitlab.com/handbook/engineering/gitlab-repositories/#creating-a-new-project).
   1. Follow the instructions for setting up a [CI/CD configuration](https://handbook.gitlab.com/handbook/engineering/gitlab-repositories/#cicd-configuration).
   1. Use the [`gem-release` CI component](https://gitlab.com/gitlab-org/components/gem-release)
      to release and publish new gem versions by adding the following to their `.gitlab-ci.yml`:

      ```yaml
      include:
        - component: $CI_SERVER_FQDN/gitlab-org/components/gem-release/gem-release@~latest
      ```

      This job will handle building and publishing the gem (it uses a `gitlab_rubygems` Rubygems.org
      API token inherited from the `gitlab-org/ruby/gems` group, in order to publish the gem
      package), as well as creating the tag, release and populating its release notes by
      using the
      [Generate changelog data](../api/repositories.md#generate-changelog-data)
      API endpoint.

      For instructions for when and how to generate a changelog entry file, see the
      dedicated [Changelog entries](changelog.md)
      page.
      [To be consistent with the GitLab project](changelog.md),
      Gem projects could also define a changelog YAML configuration file at
      `.gitlab/changelog_config.yml` with the same content
      as [in the `gitlab-styles` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-styles/-/blob/master/.gitlab/changelog_config.yml).
   1. To ease the release process, you could also create a `.gitlab/merge_request_templates/Release.md` MR template with the same content
      as [in the `gitlab-styles` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-styles/-/raw/master/.gitlab/merge_request_templates/Release.md)
      (make sure to replace `gitlab-styles` with the actual gem name).
   1. Follow the instructions for [publishing a project](https://handbook.gitlab.com/handbook/engineering/gitlab-repositories/#publishing-a-project).

Notes: In some cases we may want to move a gem to its own namespace. Some
examples might be that it will naturally have more than one project
(say, something that has plugins as separate libraries), or that we
expect users outside GitLab to be maintainers on this project as
well as GitLab team members.
The latter situation (maintainers from outside GitLab) could also
apply if someone who currently works at GitLab wants to maintain
the gem beyond their time working at GitLab.

## The `vendor/gems/`

The purpose of `vendor/` is to pull into GitLab monorepo external dependencies,
which do have external repositories, but for the sake of simplicity we want
to store them in monorepo:

- The `vendor/gems/` MUST ONLY be used if we are pulling from external repository either via script, or manually.
- The `vendor/gems/` MUST NOT be used for storing in-house gems.
- The `vendor/gems/` MAY accept fixes to make them buildable with GitLab monorepo
- The `gems/` MUST be used for storing all in-house gems that are part of GitLab monorepo.
- The **RubyGems** MUST be used for all externally stored dependencies that are not in `gems/` in GitLab monorepo.

### Handling of an existing gems in `vendor/gems`

- For in-house Gems that do not have external repository and are currently stored in `vendor/gems/`:

  - For Gems that are used by other repositories:

    - We will migrate it into its own repository.
    - We will start or continue publishing them via RubyGems.
    - Those Gems will be referenced via version in `Gemfile` and fetched from RubyGems.

  - For Gems that are only used by monorepo:

    - We will stop publishing new versions to RubyGems.
    - We will not pull from RubyGems already published versions since there might
      be applications dependent on those.
    - We will move those gems to `gems/`.
    - Those Gems will be referenced via `path:` in `Gemfile`.

- For `vendor/gems/` that are external and vendored in monorepo:

  - We will maintain them in the repository if they require some fixes that cannot be or are not yet upstreamed.
  - It is expected that vendored gems might be published by third-party.
  - Those Gems will not be published by us to RubyGems.
  - Those Gems will be referenced via `path:` in `Gemfile`, since we cannot depend on RubyGems.

## Considerations regarding rubygems.org

### Reserve a gem name

We may reserve gem names as a precaution **before publishing any public code that contains a new gem**, to avoid name-squatters taking over the name in RubyGems.

To reserve a gem name, follow the steps to [Create and publish a Ruby gem](#create-and-publish-a-ruby-gem), with the following changes:

- Use `0.0.0` as the version.
- Include a single file `lib/NAME.rb` with the content `raise "Reserved for GitLab"`.
- Perform the `build` and `publish`, and check <https://rubygems.org/gems/> to confirm it succeeded.

### Account creation

In case you are considering the creation of an account on RubyGems.org for the purpose of your work at GitLab, make sure to use your corporate email account.

### Maintainer and Account Changes

All changes such as modifications to account emails or passwords, gem owners, and gem deletion ought to be communicated previously to the directly responsible teams, through issues or Slack (the team's Slack channel, `#rubygems`, `#ruby`, `#development`).
