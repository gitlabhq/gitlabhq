---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize pipeline secret detection
---

<!-- markdownlint-disable MD025 -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Depending on your [subscription tier](_index.md#availability) and configuration method, you can change how pipeline secret detection works.

[Customize analyzer behavior](#customize-analyzer-behavior) to:

- Change what types of secrets the analyzer detects.
- Use a different analyzer version.
- Scan your project with a specific method.

[Customize analyzer rulesets](#customize-analyzer-rulesets) to:

- Detect custom secret types.
- Override default scanner rules.

## Customize analyzer behavior

To change how the analyzer behaves, define variables using the [`variables`](../../../../ci/yaml/_index.md#variables) parameter in `.gitlab-ci.yml`.

{{< alert type="warning" >}}

All configuration of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

{{< /alert >}}

### Add new patterns

To search for other types of secrets in your repositories, you can [customize analyzer rulesets](#customize-analyzer-rulesets).

To propose a new detection rule for all users of pipeline secret detection, [see our single source of truth for our rules](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/README.md) and follow the guidance to create a merge request.

If you operate a cloud or SaaS product and you're interested in partnering with GitLab to better protect your users, learn more about our [partner program for leaked credential notifications](../automatic_response.md#partner-program-for-leaked-credential-notifications).

### Pin to specific analyzer version

The GitLab-managed CI/CD template specifies a major version and automatically pulls the latest analyzer release within that major version.

In some cases, you may need to use a specific version.
For example, you might need to avoid a regression in a later release.

To override the automatic update behavior, set the `SECRETS_ANALYZER_VERSION` CI/CD variable
in your CI/CD configuration file after you include the [`Secret-Detection.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml).

You can set the tag to:

- A major version, like `4`. Your pipelines use any minor or patch updates that are released within this major version.
- A minor version, like `4.5`. Your pipelines use any patch updates that are released within this minor version.
- A patch version, like `4.5.0`. Your pipelines don't receive any updates.

This example uses a specific minor version of the analyzer:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRETS_ANALYZER_VERSION: "4.5"
```

### Enable historic scan

To enable a historic scan, set the variable `SECRET_DETECTION_HISTORIC_SCAN` to `true` in your `.gitlab-ci.yml` file.

### Run jobs in merge request pipelines

See [Use security scanning tools with merge request pipelines](../../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines).

### Override the analyzer jobs

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the `secret_detection` job to override. Place this new job after
the template inclusion and specify any additional keys under it.

In the following example _extract_ of a `.gitlab-ci.yml` file:

- The `Jobs/Secret-Detection` CI template is [included](../../../../ci/yaml/_index.md#include).
- In the `secret_detection` job, the CI/CD variable `SECRET_DETECTION_HISTORIC_SCAN` is set to
  `true`. Because the template is evaluated before the pipeline configuration, the last mention of
  the variable takes precedence, so an historic scan is performed.

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

### Available CI/CD variables

Change the behavior of pipeline secret detection by defining available CI/CD variables:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | Exclude vulnerabilities from output based on the paths. The paths are a comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec` ). Parent directories also match patterns. Detected secrets previously added to the vulnerability report are not removed. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225273) in GitLab 13.3. |
| `SECRET_DETECTION_HISTORIC_SCAN`  | false         | Flag to enable a historic Gitleaks scan. |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | Suffix added to the image name. If set to `-fips`, `FIPS-enabled` images are used for scan. See [Use FIPS-enabled images](_index.md#fips-enabled-images) for more details. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355519) in GitLab 14.10. |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""        | Flag to specify a commit range to scan. Gitleaks uses [`git log`](https://git-scm.com/docs/git-log) to determine the commit range. When defined, pipeline secret detection attempts to fetch all commits in the branch. If the analyzer can't access every commit, it continues with the already checked out repository. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350660) in GitLab 15.1. |

In previous GitLab versions, the following variables were also available:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_COMMIT_FROM`    | -             | The commit a Gitleaks scan starts at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMIT_TO`      | -             | The commit a Gitleaks scan ends at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMITS`        | -             | The list of commits that Gitleaks should scan. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352565) in GitLab 15.0. |

## Customize analyzer rulesets

{{< details >}}

- Tier: Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) in GitLab 13.5.
- Expanded to include additional passthrough types of `file` and `raw` in GitLab 14.6.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/336395) support for passthrough chains and included additional passthrough types of `git` and `url` in GitLab 17.2.

{{< /history >}}

You can customize the types of secrets detected using pipeline secret detection by [creating a ruleset configuration file](#create-a-ruleset-configuration-file),
either in the repository being scanned or a remote repository. Customization enables you to modify, replace, or extend the default ruleset.

There are multiple kinds of customizations available:

- Modify the behavior of **rules predefined in the default ruleset**. This includes:
  - [Override a rule from the default ruleset](#override-a-rule).
  - [Disable a rule from the default ruleset](#disable-a-rule).
  - [Disable or override a rule with a remote ruleset](#with-a-remote-ruleset).
- Replace the default ruleset with a custom ruleset using passthroughs. This includes:
  - [Use configuration from an inline ruleset](#with-an-inline-ruleset).
  - [Use configuration from a local ruleset](#with-a-local-ruleset).
  - [Use configuration from a remote ruleset](#with-a-remote-ruleset-1).
  - [Use configuration from a private remote ruleset](#with-a-private-remote-ruleset)
- Extend the behavior of the default ruleset using passthroughs. This includes:
  - [Use configuration from a local ruleset](#with-a-local-ruleset-1).
  - [Use configuration from a remote ruleset](#with-a-remote-ruleset-2).
- Ignore secrets and paths using Gitleaks-native functionality. This includes:
  - Use [`Gitleaks' [allowlist] directive`](https://github.com/gitleaks/gitleaks#configuration) to [ignore patterns and paths](#ignore-patterns-and-paths).
  - Use `gitleaks:allow` comment to [ignore secrets inline](#ignore-secrets-inline).

### Create a ruleset configuration file

To create a ruleset configuration file:

1. Create a `.gitlab` directory at the root of your project, if one doesn’t already exist.
1. Create a file named `secret-detection-ruleset.toml` in the `.gitlab` directory.

### Modify rules from the default ruleset

You can modify rules predefined in the [default ruleset](../detected_secrets.md).

Modifying rules can help you adapt pipeline secret detection to an existing workflow or tool. For example you may want to override the severity of a detected secret or disable a rule from being detected at all.

You can also use a ruleset configuration file stored remotely (that is, a remote Git repository or website) to modify predefined rules. New rules must use the [custom rule format](custom_rulesets_schema.md#custom-rule-format).

#### Disable a rule

{{< history >}}

- Ability to disable a rule with a remote ruleset was [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/425251) in GitLab 16.0 and later.

{{< /history >}}

You can disable rules that you don't want active. To disable rules from the analyzer default ruleset:

1. [Create a ruleset configuration file](#create-a-ruleset-configuration-file), if one doesn't exist already.
1. Set the `disabled` flag to `true` in the context of a [`ruleset` section](custom_rulesets_schema.md#the-secretsruleset-section).
1. In one or more `ruleset.identifier` subsections, list the rules to disable. Every
   [`ruleset.identifier` section](custom_rulesets_schema.md#the-secretsrulesetidentifier-section) has:
   - A `type` field for the predefined rule identifier.
   - A `value` field for the rule name.

In the following example `secret-detection-ruleset.toml` file, the disabled rules are matched by the `type` and `value` of identifiers:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
```

#### Override a rule

{{< history >}}

- Ability to override a rule with a remote ruleset was [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/425251) in GitLab 16.0 and later.

{{< /history >}}

If there are specific rules to customize, you can override them. For example, you may increase the severity of a specific type of secret because leaking it would have a higher impact on your workflow.

To override rules from the analyzer default ruleset:

1. [Create a ruleset configuration file](#create-a-ruleset-configuration-file), if one doesn't exist already.
1. In one or more `ruleset.identifier` subsections, list the rules to override. Every
   [`ruleset.identifier` section](custom_rulesets_schema.md#the-secretsrulesetidentifier-section) has:
   - A `type` field for the predefined rule identifier.
   - A `value` field for the rule name.
1. In the [`ruleset.override` context](custom_rulesets_schema.md#the-secretsrulesetoverride-section) of a [`ruleset` section](custom_rulesets_schema.md#the-secretsruleset-section), provide the keys to override. Any combination of keys can be overridden. Valid keys are:
   - `description`
   - `message`
   - `name`
   - `severity` (valid options are: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info`)

In the following `secret-detection-ruleset.toml` file, rules are matched by the `type` and `value` of identifiers and then overridden:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
    [secrets.ruleset.override]
      description = "OVERRIDDEN description"
      message     = "OVERRIDDEN message"
      name        = "OVERRIDDEN name"
      severity    = "Info"
```

#### With a remote ruleset

A **remote ruleset is a configuration file stored outside the current repository**. It can be used to modify rules across multiple projects.

To modify a predefined rule with a remote ruleset, you can use the `SECRET_DETECTION_RULESET_GIT_REFERENCE` [CI/CD variable](../../../../ci/variables/_index.md):

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "gitlab.com/example-group/remote-ruleset-project"
```

Pipeline secret detection assumes the configuration is defined in `.gitlab/secret-detection-ruleset.toml` file in the repository referenced by the CI variable where the remote ruleset is stored. If that file doesn't exist, please make sure to [create one](#create-a-ruleset-configuration-file) and follow the steps to [override](#override-a-rule) or [disable](#disable-a-rule) a predefined rule as outlined above.

{{< alert type="note" >}}

A local `.gitlab/secret-detection-ruleset.toml` file in the project takes precedence over `SECRET_DETECTION_RULESET_GIT_REFERENCE` by default because `SECURE_ENABLE_LOCAL_CONFIGURATION` is set to `true`.
If you set `SECURE_ENABLE_LOCAL_CONFIGURATION` to `false`, the local file is ignored and the default configuration or `SECRET_DETECTION_RULESET_GIT_REFERENCE` (if set) is used.

{{< /alert >}}

The `SECRET_DETECTION_RULESET_GIT_REFERENCE` variable uses a format similar to [Git URLs](https://git-scm.com/docs/git-clone#_git_urls) for specifying a URI, optional authentication, and optional Git SHA. The variable uses the following format:

```plaintext
<AUTH_USER>:<AUTH_PASSWORD>@<PROJECT_PATH>@<GIT_SHA>
```

If the configuration file is stored in a private project that requires authentication, you may use a [Group Access Token](../../../group/settings/group_access_tokens.md) securely stored in a CI variable to load the remote ruleset:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$GROUP_ACCESS_TOKEN@gitlab.com/example-group/remote-ruleset-project"
```

The group access token must have the `read_repository` scope and at least the Reporter role. For details, see [Repository permissions](../../../permissions.md#repository).

See [bot users for groups](../../../group/settings/group_access_tokens.md#bot-users-for-groups) to learn how to find the username associated with a group access token.

### Replace the default ruleset

You can replace the default ruleset configuration using a number of [customizations](custom_rulesets_schema.md). Those can be combined using [passthroughs](custom_rulesets_schema.md#passthrough-types) into a single configuration.

Using passthroughs, you can:

- Chain up to [20 passthroughs](custom_rulesets_schema.md#the-secretspassthrough-section) into a single configuration to replace or extend predefined rules.
- Include [environment variables in passthroughs](custom_rulesets_schema.md#interpolate).
- Set a [timeout](custom_rulesets_schema.md#the-secrets-configuration-section) for evaluating passthroughs.
- [Validate](custom_rulesets_schema.md#the-secrets-configuration-section) TOML syntax used in each defined passthrough.

#### With an inline ruleset

You can use [`raw` passthrough](custom_rulesets_schema.md#passthrough-types) to replace default ruleset with configuration provided inline.

To do so, add the following in the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the rule defined under `[[rules]]` as appropriate:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "raw"
    target = "gitleaks.toml"
    value  = """
title = "replace default ruleset with a raw passthrough"

[[rules]]
description = "Test for Raw Custom Rulesets"
regex = '''Custom Raw Ruleset T[est]{3}'''
"""
```

The above example replaces the default ruleset with a rule that checks for the regex defined - `Custom Raw Ruleset T` with a suffix of 3 characters from either one of `e`, `s`, or `t` letters.

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

#### With a local ruleset

You can use [`file` passthrough](custom_rulesets_schema.md#passthrough-types) to replace the default ruleset with another file committed to the current repository.

To do so, add the following in the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository and adjust the `value` as appropriate to point to the path of the file with the local ruleset configuration:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "config/gitleaks.toml"
```

This would replace the default ruleset with the configuration defined in `config/gitleaks.toml` file.

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

#### With a remote ruleset

You can replace the default ruleset with configuration defined in a remote Git repository or a file stored somewhere online using the `git` and `url` passthroughs, respectively.

A remote ruleset can be used across multiple projects. For example, you may want to apply the same
ruleset to a number of projects in one of your namespaces, in such case, you may use either type of
passthrough to load up that remote ruleset and have it used by multiple projects. It also enables
centralized management of a ruleset, with only authorized people able to edit.

To use `git` passthrough, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in a repository and adjust the `value` to point to the address of the Git repository:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

In this configuration the analyzer loads the ruleset from the `gitleaks.toml` file inside the `config` directory in the `main` branch of the repository stored at `user_group/central_repository_with_shared_ruleset`. You can then proceed to include the same configuration in projects other than `user_group/basic_repository`.

Alternatively, you may use the `url` passthrough to replace the default ruleset with a remote ruleset configuration.

To use the `url` passthrough, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in a repository and adjust the `value` to point to the address of the remote file:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

In this configuration the analyzer loads the ruleset configuration from `gitleaks.toml` file stored at the address provided.

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

#### With a private remote ruleset

If a ruleset configuration is stored in a private repository you must provide the credentials to access the repository by using the passthrough's [`auth` setting](custom_rulesets_schema.md#the-secretspassthrough-section).

{{< alert type="note" >}}

The `auth` setting only works with `git` passthrough.

{{< /alert >}}

To use a remote ruleset stored in a private repository, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in a repository, adjust the `value` to point to the address of the Git repository, and update `auth` to use the appropriate credentials:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    auth   = "USERNAME:PASSWORD" # replace USERNAME and PASSWORD as appropriate
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

{{< alert type="warning" >}}

Beware of leaking credentials when using this feature. Check [this section](custom_rulesets_schema.md#interpolate) for an example on how to use environment variables to minimize the risk.

{{< /alert >}}

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

### Extend the default ruleset

You can also extend the [default ruleset](../detected_secrets.md) configuration with additional rules as appropriate. This can be helpful when you would still like to benefit from the high-confidence predefined rules maintained by GitLab in the default ruleset, but also want to add rules for types of secrets that may be used in your own projects and namespaces. New rules must follow the [custom rule format](custom_rulesets_schema.md#custom-rule-format).

#### With a local ruleset

You can use a `file` passthrough to extend the default ruleset to add additional rules.

Add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value` as appropriate to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

The extended configuration stored in `extended-gitleaks-config.toml` is included in the configuration used by the analyzer
in the CI/CD pipeline.

In the example below, we add a couple of new `[[rules]]` sections that define a number of regular expressions to be detected:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

With this ruleset configuration the analyzer detects any strings matching with those two defined regex patterns.

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

#### With a remote ruleset

Similar to how you can replace the default ruleset with a remote ruleset, you can also extend the default ruleset with configuration stored in a remote Git repository or file stored external to the repository in which you have the `.gitlab/secret-detection-ruleset.toml` configuration file.

This can be achieved by using either of the `git` or `url` passthroughs as discussed previously.

To do that with a `git` passthrough, add the following to `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value`, `ref`, and `subdir` as appropriate to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

Pipeline secret detection assumes the remote ruleset configuration file is called `gitleaks.toml`, and is stored in `config` directory on the `main` branch of the referenced repository.

To extend the default ruleset, the `gitleaks.toml` file should use `[extend]` directive similar to the example above:

```toml
# https://gitlab.com/user_group/central_repository_with_shared_ruleset/-/raw/main/config/gitleaks.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

To use a `url` passthrough, add the following to `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value` as appropriate to point to the path of the extended configuration file

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

### Ignore patterns and paths

There may be situations in which you need to ignore a certain pattern or path from being detected by pipeline secret detection. For example, you may have a file including fake secrets to be used in a test suite.

In that case, you can utilize [Gitleaks' native `[allowlist]`](https://github.com/gitleaks/gitleaks#configuration) directive to ignore specific patterns or paths.

{{< alert type="note" >}}

This feature works regardless of whether you're using a local or a remote ruleset configuration file. The examples below utilizes a local ruleset using `file` passthrough though.

{{< /alert >}}

To ignore a pattern, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value` as appropriate to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

The extended configuration stored in `extended-gitleaks-config.toml` will be included in the configuration used by the analyzer.

In the example below, we add an `[allowlist]` directive that defines a regex that matches the secret to be ignored ("allowed"):

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  regexTarget = "match"
  regexes = [
    '''glpat-[0-9a-zA-Z_\\-]{20}'''
  ]
```

This ignores any string matching `glpat-` with a suffix of 20 characters of digits and letters.

Similarly, you can exclude specific paths from being scanned. In the example below, we define an array of paths to ignore under the `[allowlist]` directive. A path could either be a regular expression, or a specific file path:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  paths = [
    '''/gitleaks.toml''',
    '''(.*?)(jpg|gif|doc|pdf|bin|svg|socket)'''
  ]
```

This ignores any secrets detected in either `/gitleaks.toml` file or any file ending with one of the specified extensions.

For more information on the passthrough syntax to use, see [Schema](custom_rulesets_schema.md#schema).

### Ignore secrets inline

In some instances, you might want to ignore a secret inline. For example, you may have a fake secret in an example or a test suite. In these instances, you will want to ignore the secret instead of having it reported as a vulnerability.

To ignore a secret, add `gitleaks:allow` as a comment to the line that contains the secret.

For example:

```ruby
"A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB"  # gitleaks:allow
```

### Detecting complex strings

The [default ruleset](_index.md#detected-secrets) provides patterns to detect structured strings with a low rate of false positives.
However, you might want to detect more complex strings like passwords. Because [Gitleaks doesn't support lookahead or lookbehind](https://github.com/google/re2/issues/411),
writing a high-confidence, general rule to detect unstructured strings is not possible.

Although you can't detect every complex string, you can extend your ruleset to meet specific use cases.

For example, this rule modifies the [`generic-api-key` rule](https://github.com/gitleaks/gitleaks/blob/4e43d1109303568509596ef5ef576fbdc0509891/config/gitleaks.toml#L507-L514) from the Gitleaks default ruleset:

```regex
(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)
```

This regular expression matches:

1. A case-insensitive identifier that starts with `pwd`, or `passwd` or `password`. You can adjust this with other variations like `secret` or `key`.
1. A suffix that follows the identifier. The suffix is a combination of digits, letters, and symbols, and is between zero and 23 characters long.
1. Commonly used assignment operators, like `=`, `:=`, `:`, or `=>`.
1. A secret prefix, often used as a boundary to help with detecting the secret.
1. A string of digits, letters, and symbols, which is between three and 50 characters long. This is the secret itself. If you expect longer strings, you can adjust the length.
1. A secret suffix, often used as a boundary. This matches common endings like ticks, line breaks, and new lines.

Here are example strings which are matched by this regular expression:

```plaintext
pwd = password1234
passwd = 'p@ssW0rd1234'
password = thisismyverylongpassword
password => mypassword
password := mypassword
password: password1234
"password" = "p%ssward1234"
'password': 'p@ssW0rd1234'
```

To use this regex, extend your ruleset with one of the methods documented on this page.

For example, imagine you wish to extend the default ruleset [with a local ruleset](#with-a-local-ruleset-1) that includes this rule.

Add the following to a `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository. Adjust the `value` to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

In `extended-gitleaks-config.toml` file, add a new `[[rules]]` section with the regular expression you want to use:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Generic Password Rule"
  id = "generic-password"
  regex = '''(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)'''
  entropy = 3.5
  keywords = ["pwd", "passwd", "password"]
```

{{< alert type="note" >}}

This example configuration is provided only for convenience, and might not work
for all use cases. If you configure your ruleset to detect complex strings, you might
create a large number of false positives, or fail to capture certain patterns.

{{< /alert >}}

### Demonstrations

There are [demonstration projects](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection) that illustrate some of these configuration options.

Below is a table with the demonstration projects and their associated workflows:

| Action/Workflow         | Applies to/via   | With inline or local ruleset                                                                                                                                                                                                                                                                                                                                                                                       | With remote ruleset |
|-------------------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| Disable a rule          | Predefined rules | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project)   | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-ruleset) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-project) |
| Override a rule         | Predefined rules | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project) | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-ruleset) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-project) |
| Replace default ruleset | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough/-/blob/main/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough)                                                                     | Not applicable      |
| Replace default ruleset | Raw Passthrough  | [Inline Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough)                                      | Not applicable      |
| Replace default ruleset | Git Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/git-passthrough) |
| Replace default ruleset | URL Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/url-passthrough) |
| Extend default ruleset  | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough)                                                       | Not applicable      |
| Extend default ruleset  | Git Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/git-passthrough) |
| Extend default ruleset  | URL Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/url-passthrough) |
| Ignore paths            | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough)                                                                           | Not applicable      |
| Ignore paths            | Git Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/git-passthrough) |
| Ignore paths            | URL Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/url-passthrough) |
| Ignore patterns         | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough)                                                                     | Not applicable      |
| Ignore patterns         | Git Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/git-passthrough) |
| Ignore patterns         | URL Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/url-passthrough) |
| Ignore values           | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough)                                                                         | Not applicable      |
| Ignore values           | Git Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/git-passthrough) |
| Ignore values           | URL Passthrough  | Not applicable                                                                                                                                                                                                                                                                                                                                                                                                     | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/url-passthrough) |

There are also some video demonstrations walking through setting up remote rulesets:

- [Secret detection with local and remote ruleset](https://youtu.be/rsN1iDug5GU)

## Offline configuration

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

An offline environment has limited, restricted, or intermittent access to external resources through
the internet. For instances in such an environment, pipeline secret detection requires
some configuration changes. The instructions in this section must be completed together with the
instructions detailed in [offline environments](../../offline_deployments/_index.md).

### Configure GitLab Runner

By default, a runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. You should use this default setting, to ensure Docker images remain current.
However, if no network connectivity is available, you must change the default GitLab Runner
`pull_policy` variable.

Configure the GitLab Runner CI/CD variable `pull_policy` to
[`if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy).

### Use local pipeline secret detection analyzer image

Use a local pipeline secret detection analyzer image if you want to obtain the image from a local Docker
registry instead of the GitLab container registry.

Prerequisites:

- Importing Docker images into a local offline Docker registry depends on your
  network security policy. Consult your IT staff to find an accepted and approved process
  to import or temporarily access external resources.

1. Import the default pipeline secret detection analyzer image from `registry.gitlab.com` into your
   [local Docker container registry](../../../packages/container_registry/_index.md):

   ```plaintext
   registry.gitlab.com/security-products/secrets:6
   ```

   The pipeline secret detection analyzer's image is [periodically updated](../../detect/vulnerability_scanner_maintenance.md)
   so you should periodically update the local copy.

1. Set the CI/CD variable `SECURE_ANALYZERS_PREFIX` to the local Docker container registry.

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

The pipeline secret detection job should now use the local copy of the analyzer Docker image,
without requiring internet access.

## Using a custom SSL CA certificate authority

To trust a custom Certificate Authority, set the `ADDITIONAL_CA_CERT_BUNDLE` variable to the bundle
of CA certificates that you trust. Do this either in the `.gitlab-ci.yml` file, in a file
variable, or as a CI/CD variable.

- In the `.gitlab-ci.yml` file, the `ADDITIONAL_CA_CERT_BUNDLE` value must contain the
  [text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1).

  For example:

  ```yaml
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  ```

- If using a file variable, set the value of `ADDITIONAL_CA_CERT_BUNDLE` to the path to the
  certificate.

- If using a variable, set the value of `ADDITIONAL_CA_CERT_BUNDLE` to the text
  representation of the certificate.
