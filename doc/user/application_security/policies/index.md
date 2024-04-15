---
stage: Govern
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Policies

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/321258) in GitLab 14.4. Feature flag `security_orchestration_policies_configuration` removed.

Policies provide security and compliance teams with a way to enforce controls globally in
their organization.

Security teams can ensure:

- Security scanners are enforced in development team pipelines with proper configuration.
- That all scan jobs execute without any changes or alterations.
- That proper approvals are provided on merge requests based on results from those findings.

Compliance teams can:

- Centrally enforce multiple approvers on all merge requests
- Enforce various settings on projects in scope of organizational requirements, such as enabling or
  locking merge request and repository settings.

The following policy types are available:

- [Scan execution policy](scan-execution-policies.md). Enforce security scans, either as part of the pipeline or on a specified schedule.
- [Merge request approval policy](scan-result-policies.md). Enforce project-level settings and approval rules based on scan results.

## Security policy project

A security policy project (SPP) is a special type of project used only to contain policies. The
policies are stored in the `.gitlab/security-policies/policy.yml` YAML file.

To enforce the policies contained in an SPP you link it to a project, subgroup, group, or multiples
of each. An SPP can contain multiple policies but they are enforced together. An
SPP enforced on a group or subgroup applies to everything below in the hierarchy, including all
subgroups and their projects.

Policy changes made in a merge request take effect as soon as the merge request is merged. Those
that do not go through a merge request, but instead are committed directly to the default branch, may
require up to 10 minutes before the policy changes take effect.

## Policy design guidelines

When designing your policies, your goals should be:

- Designing policy enforcement for minimum overhead but maximum coverage
- Separation of duties

### Policy enforcement design

To maximize policy coverage, link an SPP at the highest level that achieves your objectives: group
level, subgroup level, or project level. Enforcement at the highest level minimizes the number of
SPPs and therefore the management overhead. Policies cascade down from each level to a project, such that policies may be enforced from the group level, each subgroup above it, and then for any policies created at the project level itself.

Policy inheritance of policies not only ensures maximum coverage with the minimum
number of SPPs, but also helps when implementing policy changes. For example, to test a policy change
you could copy an existing policy and enforce the modified policy first to a project, then to a
subgroup, and, if applicable, to a group.

NOTE:
GitLab SaaS users may enforce policies against their top-level group or across subgroups, but cannot enforce policies across GitLab SaaS top-level groups. GitLab self-managed users can enforce policies across multiple top-level groups in their instance.

The following example illustrates two groups and their structure:

- Alpha group contains two subgroups, each of which contains multiple projects.
- Security and Compliance group contains two policies.

**Alpha** group (contains code projects)

- **Finance** (subgroup)
  - Project A
  - Accounts receiving (subgroup)
    - Project B
    - Project C
- **Engineering** (subgroup)
  - Project K
  - Project L
  - Project M

**Security and Compliance** group (contains SPPs)

- Security Policy Management
- Security Policy Management - security policy project
  - SAST policy
  - Secret Detection policy

Assuming no policies have already been enforced, consider the following examples:

- If the "SAST" policy is enforced at group Alpha, it applies to its subgroups, Finance and
  Engineering, and all their projects and subgroups. If the "Secret Detection" policy is enforced
  also at subgroup "Accounts receiving", both policies apply to projects B and C. However, only the
  "SAST" policy applies to project A.
- If the "SAST" policy is enforced at subgroup "Accounts receiving", it applies only to projects B
  and C. No policy applies to project A.
- If the "Secret Detection" is enforced at project K, it applies only to project K. No other
  subgroups or projects have a policy apply to them.

### Separation of duties

Separation of duties is vital to successfully implementing policies. Security and compliance teams
should be responsible for defining policies and working with development teams. Development teams
should not be able to disable, modify, or circumvent the policies, in any way, or for any
exceptions. The policies should be implemented to achieve the necessary compliance and security
requirements, while allowing development teams to achieve their goals.

The role required to enforce an SPP depends on the hierarchy level at which it's being linked:

| Organization unit | Group owner            | Subgroup owner         | Project owner          |
|-------------------|------------------------|------------------------|------------------------|
| Group             | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| Subgroup          | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| Project           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |

## Policy implementation

Implementation options for SPPs differ slightly between GitLab SaaS and GitLab self-managed. The
main difference is that on GitLab SaaS it's only possible to create subgroups. Ensuring separation
of duties requires more granular permission configuration.

### Enforce policies across subgroups and projects

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

To enforce policies against subgroups and projects, create a subgroup to contain the SPPs, separate
to the subgroups containing the projects. Using separate subgroups allows for separation of duties,
with the SPP managed by the security team, and the projects' subgroups managed by the development
team. The security team can add or change policies without intervention from the subgroups' owners.
Subgroup and project owners cannot override policies.

Prerequisites:

- You must have the Owner role to link to the SPP. For details see
  [Separation of duties](#separation-of-duties).

The high-level workflow for enforcing policies across multiple subgroups:

1. Create a subgroup to contain your policies and ensure separation of duties.

   By creating a separate standalone subgroup, you can minimize the number of users who inherit
   permissions.
1. In the new group or subgroup, create a new project for managing your policies, such as "Security
   Policy Management".

   This serves as the primary location of the policy editor, allowing you to create and manage
   policies in the UI.
1. Create a test policy. (you can create a policy as disabled for testing.)

   Creating the policy automatically creates a new SPP under your group or subgroup. This project is
   used to store your `policy.yml` or policy-as-code.
1. Check and set project permissions in the newly-created project so that only members of the security team have the Owner role.
1. If additional restrictions are needed to block inherited permissions or require additional review
   or approval of policy changes, you can create an additional and separate set of policies to
   enforce against the first. For example, you may define a single set of individual users
   responsible for approving policy changes.
1. In the SPP just created, create the policies required. You can use the policy editor in the `Security Policy Management` project you created, under the Policies tab. Or you can directly update the policies in the `policy.yml` file stored in the newly-created security policy project `Security Policy Management - security policy project`.
1. Link up groups, subgroups, or projects to the SPP. As a subgroup owner, or project
   owner, you can visit the Policies page and create a link to the SPP. Include the full
   path and the project's name should end with "- security policy project". For details, see
   [Link to a security policy project](#link-to-a-security-policy-project).

### Enforce policies across groups, subgroups, and projects

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed, GitLab Dedicated

To enforce policies against multiple groups, create a group to contain the SPPs, separate to the
groups containing the projects. Using separate groups allows for separation of duties, with the SPP
managed by the security team, and the projects' groups managed by the development team. The security
team can add or change policies without intervention from the groups' owners. Subgroup and project
owners cannot override policies.

Prerequisites:

- You must have the Owner role to link to the SPP. For details see
  [Separation of duties](#separation-of-duties).
- To support approval groups globally across your instance, enable `security_policy_global_group_approvers_enabled` in your [GitLab instance application settings](../../../api/settings.md).

The high-level workflow for enforcing policies across multiple groups:

1. Create a separate group to contain your policies and ensure separation of duties.

   By creating a separate standalone group, you can minimize the number of users who inherit
   permissions.
1. In the new group, create a new project for managing your policies, such as "Security Policy
   Management".

   This serves as the primary location of the policy editor, allowing you to
   create and manage policies in the UI.
1. Create a test policy (you can create a policy as disabled for testing).

   Creating the policy automatically creates a new SPP under your group. This project is
   used to store your `policy.yml` or policy-as-code.
1. Check and set permissions in the newly created project as desired. By default, Owners and
   Maintainers are able to create, edit, and delete policies.
1. If additional restrictions are needed to block inherited permissions or require additional review
   or approval of policy changes, you can create an additional and separate set of policies to
   enforce against the first. For example, you may define a single set of individual users
   responsible for approving policy changes.
1. Set the permissions of the SPP so that only members of the security team have the Owner role.
1. In the SPP just created, create the policies required.
1. Link up groups, subgroups, or projects to the SPP. As a group owner, subgroup owner, or project
   owner, you can visit the Policies page and create a link to the SPP. Include the full path and
   the project's name should end with "- security policy project". For details, see
   [Link to a security policy project](#link-to-a-security-policy-project).

### Enforce policies across multiple projects

When linking a group or subgroup to your policies is not granular enough, it is possible to link up
to the SPP per project. This allows you to filter projects from enforcement that are not applicable.
To enforce an SPP policies at the project level, create a security policy project and link them. Use
project permissions to ensure only the security team has the Owner role in the security policy
project.

To enforce policies against a project:

1. Create a security policy project at the same level as the target project.
1. In the security policy project, create the policies required.
1. Link the target project to the security policy project.

## Link to a security policy project

To enforce the policies contained in an SPP against a project, subgroup, or group, you link them.

Prerequisites:

- You must have the Owner role to link to the SPP. For details, see
  [Separation of duties](#separation-of-duties).

To link a project, subgroup, or group to an SPP:

1. On the left sidebar, select **Search or go to** and find your project, subgroup, or group.
1. Select **Secure > Policies**.
1. Select **Edit Policy Project**, then search for and select the project you would like to link
   from the dropdown list.
1. Select **Save**.

To unlink a security policy project, follow the same steps but instead select the trash can icon in
the dialog.

### Viewing the linked security policy project

All users who have access to the project policy page and are not project owners instead view a
button linking out to the associated security policy project.

## Policy management

The Policies page displays deployed policies for all available environments. You can check a
policy's information (for example, description or enforcement status), and create and edit deployed
policies:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Policies**.

![Policies List Page](img/policies_list_v15_1.png)

## Policy editor

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3403) in GitLab 13.4.

You can use the policy editor to create, edit, and delete policies:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Policies**.
   - To create a new policy, select **New policy** which is located in the **Policies** page's header.
     You can then select which type of policy to create.
   - To edit an existing policy, select **Edit policy** in the selected policy drawer.

The policy editor has two modes:

- The visual _Rule_ mode allows you to construct and preview policy
  rules using rule blocks and related controls.

  ![Policy Editor Rule Mode](img/policy_rule_mode_v15_9.png)

- YAML mode allows you to enter a policy definition in `.yaml` format
  and is aimed at expert users and cases that the Rule mode doesn't
  support.

  ![Policy Editor YAML Mode](img/policy_yaml_mode_v15_9.png)

You can use both modes interchangeably and switch between them at any
time. If a YAML resource is incorrect or contains data not supported
by the Rule mode, Rule mode is automatically
disabled. If the YAML is incorrect, you must use YAML
mode to fix your policy before Rule mode is available again.

When you finish creating or editing your policy, save and apply it by selecting the
**Configure with a merge request** button and then merging the resulting merge request. When you
press this button, the policy YAML is validated and any resulting errors are displayed.
Additionally, if you are a project owner and a security policy project has not been previously
associated with this project, then a new project is created and associated automatically at the same
time that the first policy merge request is created.

## Managing projects in bulk via a script

You can use the [Vulnerability-Check Migration](https://gitlab.com/gitlab-org/gitlab/-/snippets/2328089) script to bulk create policies or associate security policy projects with development projects. For instructions and a demonstration of how to use the Vulnerability-Check Migration script, see [this video](https://youtu.be/biU1N26DfBc).

## Troubleshooting

### `Branch name 'update-policy-<timestamp>' does not follow the pattern '<branch_name_regex>'`

When you create a new security policy or change an existing policy, a new branch is automatically created with the branch name following the pattern `update-policy-<timestamp>`. For example: `update-policy-1659094451`.

If you have group or instance [push rules that do not allow branch name patterns](../../project/repository/push_rules.md#validate-branch-names) that contain the text `update-policy-<timestamp>`, you will get an error that states `Branch name 'update-policy-<timestamp>' does not follow the pattern '<branch_name_regex>'`.

The workaround is to amend your group or instance push rules to allow branches following the pattern `update-policy-` followed by an integer timestamp.

### Troubleshooting common issues configuring security policies

- Confirm that scanners are properly configured and producing results for the latest branch.
  Security Policies are designed to require approval when there are no results (no security report),
  as this ensures that no vulnerabilities are introduced. We cannot know if there are any
  vulnerabilities unless the scans enforced by the policy complete successfully and are evaluated.
- For merge request approval policies, we require artifacts for each scanner defined in the policy for both the
  source and target branch. To ensure merge request approval policies capture the necessary results, confirm
  your scan execution is properly implemented and enforced. If using scan execution policies,
  enforcing on `all branches` often addresses this need.
- Comparison in merge request approval policies depends on a successful and completed merge base pipeline. If the merge base pipeline is [skipped](../../../ci/pipelines/index.md#skip-a-pipeline), merge requests with the merge base pipeline are blocked.
- When running scan execution policies based on a SAST action, ensure target repositories contain
  proper code files. SAST runs different analyzers
  [based on the types of files in the repository](../sast/index.md#supported-languages-and-frameworks),
  and if no supported files are found it does not run any jobs. See the
  [SAST CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)
  for more details.
- Check for any branch configuration conflicts. For example, if your policy is configured to enforce rules on
  `main` but some projects in the scope are using `master` as their default branch, the policy
  is not applied for the latter. You can define policies to enforce rules generically on `default`
  branches regardless of the name used in the project or on `all protected branches` to address this
  issue.
- Merge request approval policies created at the group or subgroup level can take some time to apply to all
  the merge requests in the group.
- Scheduled scan execution policies run with a minimum 15 minute cadence. Learn more [about the schedule rule type](../policies/scan-execution-policies.md#schedule-rule-type).
- When scheduling pipelines, keep in mind that CRON scheduling is based on UTC on GitLab SaaS and is
  based on your server time for self managed instances. When testing new policies, it may appear
  pipelines are not running properly when in fact they are scheduled in your server's time zone.
- When enforcing scan execution policies, security policies use a bot in the target project to
  trigger scheduled pipelines to ensure enforcement. When the bot is missing, it is automatically
  created, and the following scheduled scan uses it.
- You should not link a security policy project to a development project and to the group or
  subgroup the development project belongs to at the same time. Linking this way results in approval
  rules from the Scan Result Policy not being applied to merge requests in the development project.
- When creating a Scan Result Policy, neither the array `severity_levels` nor the array
  `vulnerability_states` in the [`scan_finding` rule](../policies/scan-result-policies.md#scan_finding-rule-type)
  can be left empty. For a working rule, at least one entry must exist.
- When merge request approval policies are enforced on projects containing manual jobs in their pipeline, policies evaluate the completed pipeline jobs and ignore the manual jobs. When the manual jobs are run, the policy re-evaluates the MR.

If you are still experiencing issues, you can [view recent reported bugs](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=popularity&state=opened&label_name%5B%5D=group%3A%3Asecurity%20policies&label_name%5B%5D=type%3A%3Abug&first_page_size=20) and raise new unreported issues.
