---
stage: Security Risk Management
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dependency firewall
description: Block packages with disallowed licenses, high vulnerability risk, or malicious code before a package manager installs them.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/22189) in GitLab 19.0 as an
  [experiment](../../../policy/development_stages_support.md).
- Changed to [beta](../../../policy/development_stages_support.md) in GitLab
  19.5. Available in Premium and Ultimate on GitLab.com and GitLab Self-Managed.
  GitLab Dedicated support is planned for general availability.

{{< /history >}}

> [!warning]
> The dependency firewall is in [beta](../../../policy/development_stages_support.md). Behavior,
> the policy schema, and the supported ecosystems can change between releases. Test policies in
> `warn` mode before you enforce them.

Use the dependency firewall to control which packages your developers and CI/CD jobs install. A
dependency firewall policy evaluates each package against rules that you define for licenses,
vulnerability risk, and malicious code. When a package matches a denying rule, the firewall
refuses the download and records the decision.

## How does dependency firewall work

You run your package manager through the [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md)
with `glab dependency-firewall`, or its shorter alias `glab df`. Each package is evaluated as
the package manager resolves it, before it reaches your machine:

1. Your package manager requests a package from whichever registry it is already configured to
   use, such as npmjs.com, PyPI, Maven Central, or RubyGems.org.
1. The CLI intercepts the request through a local inspection proxy, and asks GitLab to evaluate
   the package name and version against the policies that apply to your project.
1. GitLab returns one of three outcomes. An allowed package is fetched as usual. A warned
   package is fetched and reported. A blocked package is refused, and the package manager
   receives a `403 Forbidden` response.

GitLab does not host or mirror the packages it evaluates, so you do not have to move your
dependencies into the GitLab package registry or change the registry configuration your project
already uses.

## Supported ecosystems

| Ecosystem | Package managers |
|-----------|------------------|
| Java      | Maven, Gradle |
| Node.js   | npm, pnpm, Yarn |
| Python    | pip, `uv`, Poetry, pipenv, twine |
| Ruby      | `gem`, Bundler |

Packages in other ecosystems are fetched without evaluation.

## Restrictions

- Only the traffic that `glab df` proxies is evaluated. A package manager run on its own, such
  as `npm install` without the prefix, does not reach the firewall. To make the firewall the
  only route to a registry, see [Prevent bypassing the firewall](#prevent-bypassing-the-firewall).
- Policies are evaluated against the package name, version, and ecosystem. The firewall resolves
  licenses, vulnerabilities, and malicious package data from the package metadata database and
  the [GitLab advisory database](../gitlab_advisory_database/_index.md).
- A package that is absent from the package metadata database is allowed. An allowed outcome is
  not an assertion that GitLab holds license or vulnerability data for the package.
- A maximum of five dependency firewall policies are allowed per security policy project. This
  limit is controlled by the `dependency_firewall_policies_per_configuration_limit` application
  setting.
- The local proxy connects to registries directly. It does not use an outbound corporate proxy,
  so `glab df` cannot reach registries in a network that requires one.
- Registries must use HTTPS. The proxy accepts HTTPS traffic only and refuses plain `http://`
  requests.
- Packages already in a package manager cache are not re-evaluated. Maven reads from
  `~/.m2/repository/`, npm from `node_modules/`, and Bundler from `vendor/bundle/`. The firewall
  is evaluated only when the package manager fetches a package over the network.

## Prerequisites

To use the dependency firewall:

- Your namespace must have access to the Premium or Ultimate tier.
- A [security policy project](../policies/enforcement/security_policy_projects.md) must be linked
  to the project, or to one of its parent groups.
- The dependency firewall must be turned on. See
  [Turn on the dependency firewall](#turn-on-the-dependency-firewall).
- Developers must have the GitLab CLI installed and authenticated against your GitLab instance.
- Developers, and the users who run CI/CD jobs, must have at least the Reporter role on the
  project.

## Turn on the dependency firewall

On GitLab.com, the firewall is turned on for each top-level group. On GitLab Self-Managed, it
is turned on once for the whole instance.

### On GitLab.com

Prerequisites:

- You must have the Owner role for the top-level group.

To turn on the dependency firewall:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Secure**.
1. Turn on the **Enable dependency firewall** toggle.

This setting is available on top-level groups only. Subgroups and projects inherit the setting
from their top-level group.

### On GitLab Self-Managed

Prerequisites:

- You must be an administrator.

To turn on the dependency firewall:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Security and compliance**.
1. Expand **Dependency firewall**.
1. Select the **Enable dependency firewall** checkbox.
1. Select **Save changes**.

The setting applies to every project on the instance. There is no per-group toggle.

To turn off the firewall, repeat the steps for your offering and turn the setting off. Existing
policies are preserved, but the firewall stops evaluating packages.

## Prevent bypassing the firewall

The firewall evaluates only the traffic that `glab df` can see. A package manager run on its
own installs whatever it resolves, and so does an AI coding agent that calls a package manager
for you. Neither reaches the firewall, so neither sees a block. Furthermore,
the packages may be cached, as mentioned above.

To close that gap, enforce the firewall at your network egress point instead of relying on
every caller to remember the prefix.

The CLI adds the following header to every request it forwards to a registry, including
metadata and index requests, and requests for allowed and warned packages:

```plaintext
X-Gitlab-Dependency-Firewall: allowed
```

Configure your egress proxy or gateway to allow HTTPS traffic to package registries only when
that header is present. A package manager that runs outside `glab df` sends no such header, so
the request is refused at the network boundary rather than quietly succeeding.

This control needs:

- An egress control point that inspects HTTPS traffic. The header travels inside the TLS
  session the CLI opens to the registry, so a gateway that sees only the destination host
  cannot read it.
- A rule for each registry hostname your teams use, such as `registry.npmjs.org`, `pypi.org`,
  `files.pythonhosted.org`, `repo.maven.apache.org`, and `rubygems.org`.

The header is set by the CLI, so this is a guardrail rather than a boundary. It stops a package
manager or agent that does not know about the header. A caller that sets the header itself
still reaches the registry.

The header also does not prove that a policy evaluated the request. The CLI adds it even when
the firewall is not evaluating the project, for example when the firewall is turned off or the
project cannot be found. The header shows only that the request went through `glab df`. The CLI
never forwards blocked packages.

Some configurations also send traffic around the CLI. For example, an `http_proxy:` setting in a
`gemrc` file takes precedence over the proxy settings the CLI applies for `gem` and `bundle`, so
that traffic is not inspected. RubyGems reads the system `gemrc` file, `~/.gemrc`, and the file
named by the `GEMRC` variable. It does not read these files from the repository, so a committed
project file cannot cause this, but a CI image or a developer machine can.

## Pricing during beta

The dependency firewall is free during beta. At general availability it becomes a paid feature,
billed through [GitLab Credits](../../../subscriptions/gitlab_credits.md). You must opt in
before you are charged, and GitLab gives notice before that happens.

## Create a dependency firewall policy

Dependency firewall policies are stored in the `.gitlab/security-policies/policy.yml` file of a
[security policy project](../policies/enforcement/security_policy_projects.md). Build a policy
in the policy editor, or commit to that file directly.

Creating policies at the group level means the policy applies to every project in the group, as well as its subgroups. Creating a policy at the project level, means the policy applies only to that project.

Prerequisites:

- By default, only group, subgroup, or project Owners have the [permissions](../../permissions.md#project-application-security)
  required to create or assign a security policy project. Alternatively, you can create a custom
  role with the permission to [manage security policy links](../../custom_roles/abilities.md#security-policy-management).

To create a dependency firewall policy:

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **Secure** > **Policies**.
1. Select **New policy**.
1. In **Dependency firewall policy**, select **Select policy**.
1. Complete the fields. For what each one means, see [Policy schema](#policy-schema).
1. Select **Configure with a merge request**.
1. Review and merge the merge request.

After the merge request is merged, the policy takes effect on the next evaluation.

### Editor modes

The policy editor opens in rule mode, a form that builds the policy for you. Rule mode covers
the name, description, scope, enforcement mode, and rules. Bypass settings are under
**Advanced**.

To write the policy as YAML instead, select **YAML mode**. Use YAML mode to copy a policy
between projects, or to use a field that rule mode does not show.

You can switch between the two modes at any time. If the YAML contains an error, rule mode is
turned off until you fix it. For more information, see
[Policy editor](../policies/_index.md#policy-editor).

### Policy schema

A dependency firewall policy has the following top-level fields.

| Field              | Type    | Required | Description |
|--------------------|---------|----------|-------------|
| `name`             | string  | yes      | Name of the policy. Maximum 255 characters. |
| `description`      | string  | no       | Longer description of the policy. |
| `enabled`          | boolean | yes      | Whether the policy is evaluated. Set to `false` to turn off the policy without removing it. |
| `enforcement_type` | string  | yes      | One of `enforced` or `warn`. See [Enforcement modes](#enforcement-modes). |
| `rules`            | array   | yes      | One or more rules. See [Rule types](#rule-types). |
| `bypass_settings`  | object  | no       | Users and access tokens that bypass the policy. See [Bypass settings](#bypass-settings). |
| `policy_scope`     | object  | no       | Groups and projects that the policy applies to. See [Policy scope](#policy-scope). |

### Enforcement modes

The `enforcement_type` field controls what happens when a rule matches:

- `enforced`: The firewall refuses the package. The package manager receives a `403 Forbidden`
  response and the package is not installed.
- `warn`: The firewall fetches the package and reports it in the run summary. Use this mode to
  test a policy before you enforce it.

When no rule in any active policy matches a package, the firewall allows it.

### Rule types

A policy must contain at least one rule. Each rule has a `type` field that is one of `license`,
`risk_severity`, or `malicious`. In rule mode, select the type from **Choose a rule type**.

> [!note]
> Rule mode also offers a **Vulnerability** rule type. It is deprecated and is being removed.
> Use **Risk severity** instead, which counts vulnerabilities per severity rather than matching
> a single severity floor.

#### License rules

License rules match packages by their SPDX license name. Use `denied` to block packages that
declare any of the listed licenses. Use `allowed` to block packages that declare a license that
is not in the list. The two keys are mutually exclusive.

```yaml
rules:
  - type: license
    denied:
      - name: GNU General Public License v3.0 only
      - name: GNU Affero General Public License v3.0 only
```

```yaml
rules:
  - type: license
    allowed:
      - name: MIT License
      - name: Apache License 2.0
```

#### Risk severity rules

Risk severity rules match packages by how many known vulnerabilities they carry at each
severity. Each entry pairs a `severity` with a `threshold`, which is the maximum number of
vulnerabilities you permit at that severity. A package is denied when it carries more than that
number.

A `threshold` of `0` permits none, so it denies a package that has even one vulnerability at
that severity. A `threshold` of `2` permits two and denies a third.

Severities are `critical`, `high`, `medium`, and `low`. List each severity at most once. Only
`denied` is supported.

The following rule blocks any package with a critical vulnerability, with more than two high
vulnerabilities, or with more than ten medium vulnerabilities:

```yaml
rules:
  - type: risk_severity
    denied:
      - severity: critical
        threshold: 0
      - severity: high
        threshold: 2
      - severity: medium
        threshold: 10
```

Vulnerabilities of unknown severity are never counted.

#### Malicious package rules

Malicious package rules block packages that the GitLab malicious packages data feed has flagged.
Only `denied` is supported, and the single entry must be `is_malicious: true`.

```yaml
rules:
  - type: malicious
    denied:
      - is_malicious: true
```

### Rule exceptions

Each rule supports an optional `exceptions` array. An exception entry is either a package URL
(PURL) or a vulnerability identifier such as a CVE. A matching exception removes the package or
the vulnerability from the evaluation of that rule.

Use PURL exceptions to exempt internal packages from a license or malicious rule. The PURL can
include or omit a version. When the version is omitted, the exception applies to every version
of the package.

```yaml
rules:
  - type: license
    denied:
      - name: GNU General Public License v3.0 only
    exceptions:
      - purl: pkg:npm/my-internal-lib
      - purl: pkg:npm/another-lib@1.2.3
```

Use ID exceptions to exempt specific CVEs from a risk severity rule. An excepted vulnerability
is not counted toward any threshold.

```yaml
rules:
  - type: risk_severity
    denied:
      - severity: high
        threshold: 0
    exceptions:
      - id: CVE-2024-12345
```

### Bypass settings

Bypass settings let specific users or access tokens skip a policy. A request made by a listed
user, or with a listed access token, is allowed, and the bypass reason is recorded.

```yaml
bypass_settings:
  users:
    - id: 1234
  access_tokens:
    - id: 5678
```

To find a user ID, view the user's profile and append `.json` to the URL. To find an access
token ID, view the project or group access token list.

Use bypass settings for service accounts that must install internal packages, or for emergency
access during an incident.

### Policy scope

By default, a dependency firewall policy applies to every project that the policy is enforced
on. Use `policy_scope` to narrow that to a specific set of groups or projects, or to exclude
projects from a broader rollout.

`policy_scope` accepts two keys, `groups` and `projects`. Each key takes an `including` list, an
`excluding` list, or both.

In all cases, each entry is an object with an `id`.

| Field                | Type  | Description |
|----------------------|-------|-------------|
| `groups.including`   | array | Groups that the policy applies to. |
| `groups.excluding`   | array | Groups that the policy does not apply to. |
| `projects.including` | array | Projects that the policy applies to. |
| `projects.excluding` | array | Projects that the policy does not apply to. A `type` of `personal` or `archived` excludes all personal or archived projects. |

For example, the following scope applies the policy to two groups, but excludes one project and
all archived projects in those groups:

```yaml
policy_scope:
  groups:
    including:
      - id: 100
      - id: 101
  projects:
    excluding:
      - id: 555
      - type: archived
```

When `policy_scope` is omitted, the policy applies to every project in the security policy
project's enforcement target.

> [!note]
> Dependency firewall `policy_scope` supports `groups` and `projects` only. Compliance
> frameworks and security attributes are not supported.

### Example policy

The following policy:

- blocks copyleft licenses
- blocks packages that carry critical
- vulnerabilities or more than two high vulnerabilities
- blocks malicious packages
- and exempts an internal library and a known false-positive CVE.

```yaml
---
dependency_firewall_policy:
  - name: Restrict copyleft licenses and high-risk packages
    description: Blocks copyleft-licensed packages, high-risk packages, and malicious packages.
    enabled: true
    enforcement_type: enforced
    rules:
      - type: license
        denied:
          - name: GNU General Public License v3.0 only
          - name: GNU Affero General Public License v3.0 only
        exceptions:
          - purl: pkg:npm/my-internal-lib
      - type: risk_severity
        denied:
          - severity: critical
            threshold: 0
          - severity: high
            threshold: 2
        exceptions:
          - id: CVE-2024-12345
      - type: malicious
        denied:
          - is_malicious: true
    bypass_settings:
      users:
        - id: 1234
    policy_scope:
      projects:
        excluding:
          - type: archived
```

## Edit a dependency firewall policy

To edit a dependency firewall policy:

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **Secure** > **Policies**.
1. In the policy row, select **Edit**.
1. Edit the policy.
1. Select **Configure with a merge request**.
1. Review and merge the merge request.

The updated policy takes effect on the next evaluation after the merge request is merged.

## View dependency firewall activity

The dependency firewall dashboard shows what the firewall has blocked and warned on, and which
policy rules are active.

Prerequisites:

- The dependency firewall must be turned on.
- You must have permission to read security policies for the group or project.

To view the dashboard:

1. In the top bar, select **Search or go to** and find your group or project.
1. Select **Secure** > **Dependency firewall**.

The dashboard has two summary cards and a table:

- **All activity** counts the packages blocked, the packages warned on, and the total triggers
  in the selected time period.
- **Active policy rules** counts the enabled rules, split by how many blocks and how many warnings.
- **Policies** lists each active rule with its policy name, rule type, mode, status, trigger
  count, and when it was last modified and by whom.

Select **Last 7 days** or **Last 30 days** to change the time period. The default is the last
seven days.

### Audit events

Every evaluation also produces a project-scoped audit event. To view audit events:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Audit events**.

The following audit event types are recorded:

| Event type                    | Recorded when |
|-------------------------------|---------------|
| `dependency_firewall_allowed` | The firewall allows the package, including through a bypass or an exception. |
| `dependency_firewall_warned`  | A `warn` policy matches the package. |
| `dependency_firewall_blocked` | An `enforced` policy matches the package. |

Each event records the package, the operation, the policy name, and the rule that matched. For
more information, see [Audit event types](../../compliance/audit_event_types.md#dependency-firewall).
