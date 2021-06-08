---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Licensing and Compatibility

[GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/) (CE) is licensed [under the terms of the MIT License](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/LICENSE). [GitLab Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/) (EE) is licensed under "[The GitLab Enterprise Edition (EE) license](https://gitlab.com/gitlab-org/gitlab/-/blob/master/LICENSE)" wherein there are more restrictions.

## Automated Testing

In order to comply with the terms the libraries we use are licensed under, we have to make sure to check new gems for compatible licenses whenever they're added. To automate this process, we use the [license_finder](https://github.com/pivotal/LicenseFinder) gem by Pivotal. It runs every time a new commit is pushed and verifies that all gems and node modules in the bundle use a license that doesn't conflict with the licensing of either GitLab Community Edition or GitLab Enterprise Edition.

There are some limitations with the automated testing, however. CSS, JavaScript, or Ruby libraries which are not included by way of Bundler, npm, or Yarn (for instance those manually copied into our source tree in the `vendor` directory), must be verified manually and independently. Take care whenever one such library is used, as automated tests don't catch problematic licenses from them.

Some gems may not include their license information in their `gemspec` file, and some node modules may not include their license information in their `package.json` file. These aren't detected by License Finder, and must be verified manually.

### License Finder commands

There are a few basic commands License Finder provides that you need in order to manage license detection.

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

For all of the above, please include `--why "Reason"` and `--who "My Name"` so the `decisions.yml` file can keep track of when, why, and who approved of a dependency.

More detailed information on how the gem and its commands work is available in the [License Finder README](https://github.com/pivotal/LicenseFinder).

## Encryption keys

If your license was created in your local development or staging environment for Customers Portal or License App, an environment variable called `GITLAB_LICENSE_MODE` with the value `test` needs to be set to use the correct decryption key.

Those projects are set to use a test license encryption key by default.

## Additional information

Please see the [Open Source](https://about.gitlab.com/handbook/engineering/open-source/#using-open-source-libraries) page for more information on licensing.
