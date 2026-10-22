---
stage: Security Risk Management
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Get started with the dependency firewall
description: Turn on the dependency firewall, add a policy in warn mode, and check the results.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

Set up the dependency firewall and see its first result. You turn the firewall on, add a policy
that reports matches without blocking them, install a package, and read what the firewall saw.

The policy in this guide uses `warn` mode, so nothing is blocked while you try it out. The last
step covers switching to enforcement.

Expect this to take about 15 minutes.

Prerequisites:

- Your namespace must have access to the Premium or Ultimate tier.
- On GitLab.com, you must have the Owner role for the top-level group.
  On GitLab Self-Managed, you must be an administrator.
- You need a project with a package manager this feature supports. This guide uses npm.

## Step 1: Turn on the firewall

On GitLab.com:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **Secure**.
1. Turn on the **Enable dependency firewall** toggle.

On GitLab Self-Managed:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Security and compliance**.
1. Expand **Dependency firewall**.
1. Select the **Enable dependency firewall** checkbox, then select **Save changes**.

Nothing is evaluated yet. The firewall needs a policy, which you add next.

## Step 2: Add a policy in warn mode

Policies live in a [security policy project](../policies/enforcement/security_policy_projects.md).
If your group does not have one, GitLab creates it when you save your first policy.

1. In the top bar, select **Search or go to** and find your group.
1. Select **Secure** > **Policies**.
1. Select **New policy**.
1. In **Dependency firewall policy**, select **Select policy**.
   <!-- markdownlint-disable-next-line MD044 -->
1. The editor opens in rule mode, a form. To paste the policy instead, select **.yaml mode**.
1. Replace the contents of the editor with the following policy:

   ```yaml
   dependency_firewall_policy:
     - name: Audit high-risk packages
       description: Reports packages with critical vulnerabilities or malicious code.
       enabled: true
       enforcement_type: warn
       rules:
         - type: risk_severity
           denied:
             # threshold is the number of vulnerabilities you permit.
             # 0 permits none, so a single critical vulnerability matches.
             - severity: critical
               threshold: 0
         - type: malicious
           denied:
             - is_malicious: true
   ```

1. Select **Configure with a merge request**.
1. Review and merge the merge request.

This policy reports any package that carries a critical vulnerability or is flagged as
malicious. Because `enforcement_type` is `warn`, nothing is blocked.

## Step 3: Install a package through the firewall

Policies are evaluated by the [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md), so
install and authenticate it first:

```shell
glab auth login
```

Clone the project the policy applies to, then install its dependencies with `glab df` in front
of your usual command:

```shell
git clone https://gitlab.example.com/my-group/my-project.git
cd my-project
glab df npm install
```

`npm` runs as it always does. The CLI checks each package it resolves against your policy.

## Step 4: Read the result

After `npm` finishes, the CLI prints what the firewall saw:

```plaintext
╭──────────────────────────────────────────────────────────────────────────────────╮
│ ▲  GitLab Dependency Firewall                                                    │
│ 1 package warning                                                                │
├──────────────────────────────────────────────────────────────────────────────────┤
│    PACKAGE  VERSION  REASON                                                      │
│ ▲  lodash   4.17.15  Package 'lodash' violates 'Audit high-risk packages' policy │
╰──────────────────────────────────────────────────────────────────────────────────╯
```

A `▲` marks a warned package. Had the policy been in `enforced` mode, this package would show a
`✖` instead, and `npm` would have failed.

If no summary is printed, none of the packages matched your policy. Try
`glab df npm install lodash@4.17.15`, which has known vulnerabilities, to see a match.

> [!tip]
> To check a package without installing it, run `glab df package pkg:npm/lodash@4.17.15`.
> For more information, see [Check a single package](gitlab_cli.md#check-a-single-package).

To see the same results in GitLab, select **Secure** > **Dependency firewall** in your group or
project. The dashboard counts what has been blocked and warned on, and lists each active rule.

## Step 5: Switch to enforcement

When the warnings match what you expect to block, change the policy to enforce them:

1. Select **Secure** > **Policies**.
1. In the policy row, select **Edit**.
   <!-- markdownlint-disable-next-line MD044 -->
1. For **Enforcement mode**, select **Enforce**. In **.yaml mode**, set `enforcement_type` to
   `enforced`.
1. Select **Configure with a merge request**, then review and merge it.

Matching packages are now refused. The package manager receives a `403 Forbidden` response and
the install fails, which stops the package from reaching the machine or the pipeline.

Roll out enforcement gradually. Use [`policy_scope`](_index.md#policy-scope) to apply a policy
to a few projects first, and [bypass settings](_index.md#bypass-settings) to exempt a service
account that must keep publishing.

## Next steps

- Add rules for [licenses](_index.md#license-rules), or tune the
  [risk severity thresholds](_index.md#risk-severity-rules).
- Run the firewall in CI/CD with
  [`glab df` in your job scripts](gitlab_cli.md#use-the-firewall-in-cicd).
- Use the firewall with [other package managers](package_managers.md).
