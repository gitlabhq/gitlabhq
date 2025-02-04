---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab Licensing and Compatibility
---

[GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/) (CE) is licensed [under the terms of the MIT License](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/LICENSE). [GitLab Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/) (EE) is licensed under "[The GitLab Enterprise Edition (EE) license](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/LICENSE)" wherein there are more restrictions.

## Automated Testing

To comply with the terms the libraries we use are licensed under, we have to make sure to check new gems for compatible licenses whenever they're added. To automate this process, we use the [License Finder](https://github.com/pivotal/LicenseFinder) gem by Pivotal. It runs every time a new commit is pushed and verifies that all gems and node modules in the bundle use a license that doesn't conflict with the licensing of either GitLab Community Edition or GitLab Enterprise Edition.

There are some limitations with the automated testing, however. CSS, JavaScript, or Ruby libraries which are not included by way of Bundler, npm, or Yarn (for instance those manually copied into our source tree in the `vendor` directory), must be verified manually and independently. Take care whenever one such library is used, as automated tests don't catch problematic licenses from them.

Some gems may not include their license information in their `gemspec` file, and some node modules may not include their license information in their `package.json` file. These aren't detected by License Finder, and must be verified manually.

### License Finder commands

There are a few basic commands License Finder provides that you need to manage license detection.

To verify that the checks are passing, and/or to see what dependencies are causing the checks to fail:

```shell
bundle exec license_finder
```

To allowlist a new license:

```shell
license_finder permitted_licenses add MIT
```

To denylist a new license:

```shell
license_finder restricted_licenses add Unlicense
```

To tell License Finder about a dependency's license if it isn't auto-detected:

```shell
license_finder licenses add my_unknown_dependency MIT
```

For all of the above, include `--why "Reason"` and `--who "My Name"` so the `decisions.yml` file can keep track of when, why, and who approved of a dependency.

More detailed information on how the gem and its commands work is available in the [License Finder README](https://github.com/pivotal/LicenseFinder).

## Getting an unknown or Lead licensed software approved

We sometimes need to use third-party software whose license is not part of the Blue Oak Council
license list, or is marked as Lead-rated in the list. In this case, the use-case needs to be
legal-approved before the software can be installed. More on this can be [found in the Handbook](https://handbook.gitlab.com/handbook/legal/product/#using-open-source-software).

To get legal approval, follow these steps:

1. Create a new [legal issue](https://gitlab.com/gitlab-com/legal-and-compliance/-/issues/new?issuable_template=general-legal-template). Make sure to include as many details as possible:
   - What license is the software using?
   - How and where will it be used?
   - Is it being vendored or forked, or will we be using the upstream project?
   - Any relevant links.
1. After the usage has been legal-approved, allowlist the software in the GitLab project.
   See [License Finder commands](#license-finder-commands) above.
1. Make sure the software is also recognized by Omnibus. Create a new MR against the [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab)
   project. Refer to [this MR](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6870)
   for an example of what the changes should look like. You'll need to edit the following files:
   - `lib/gitlab/license/analyzer.rb`
   - `support/dependency_decisions.yml`

## Encryption keys

If your license was created in your local development or staging environment for Customers Portal or License App, an environment variable called `GITLAB_LICENSE_MODE` with the value `test` needs to be set to use the correct decryption key.

Those projects are set to use a test license encryption key by default.

## Additional information

See the [Open Source](https://handbook.gitlab.com/handbook/engineering/open-source/#using-open-source-software) page for more information on licensing.
