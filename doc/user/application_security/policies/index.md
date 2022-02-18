---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Policies **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5329) in GitLab 13.10 with a flag named `security_orchestration_policies_configuration`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/321258) in GitLab 14.3.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/321258) in GitLab 14.4.

Policies in GitLab provide security teams a way to require scans of their choice to be run
whenever a project pipeline runs according to the configuration specified. Security teams can
therefore be confident that the scans they set up have not been changed, altered, or disabled. You
can access these by navigating to your project's **Security & Compliance > Policies** page.

GitLab supports the following security policies:

- [Scan Execution Policy](scan-execution-policies.md)
- [Scan Result Policy](scan-result-policies.md)
- [Container Network Policy](#container-network-policy) (DEPRECATED)

## Policy management

The Policies page displays deployed
policies for all available environments. You can check a
policy's information (for example, description or enforcement
status), and create and edit deployed policies:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Policies**.

![Policies List Page](img/policies_list_v14_3.png)

Network policies are fetched directly from the selected environment's
deployment platform while other policies are fetched from the project's
security policy project. Changes performed outside of this tab are
reflected upon refresh.

By default, the policy list contains predefined network policies in a
disabled state. Once enabled, a predefined policy deploys to the
selected environment's deployment platform and you can manage it like
the regular policies.

Note that if you're using [Auto DevOps](../../../topics/autodevops/index.md)
and change a policy in this section, your `auto-deploy-values.yaml` file doesn't update. Auto DevOps
users must make changes by following the
[Container Network Policy documentation](../../../topics/autodevops/stages.md#network-policy).

## Policy editor

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3403) in GitLab 13.4.

You can use the policy editor to create, edit, and delete policies:

1. On the top bar, select **Menu > Projects** and find your group.
1. On the left sidebar, select **Security & Compliance > Policies**.
   - To create a new policy, select **New policy** which is located in the **Policies** page's header.
   - To edit an existing policy, select **Edit policy** in the selected policy drawer.

The policy editor has two modes:

- The visual _Rule_ mode allows you to construct and preview policy
  rules using rule blocks and related controls.

  ![Policy Editor Rule Mode](img/container_policy_rule_mode_v14_3.png)

- YAML mode allows you to enter a policy definition in `.yaml` format
  and is aimed at expert users and cases that the Rule mode doesn't
  support.

  ![Policy Editor YAML Mode](img/container_policy_yaml_mode_v14_3.png)

You can use both modes interchangeably and switch between them at any
time. If a YAML resource is incorrect or contains data not supported
by the Rule mode, Rule mode is automatically
disabled. If the YAML is incorrect, you must use YAML
mode to fix your policy before Rule mode is available again.

## Security Policies project

NOTE:
We recommend using the [Security Policies project](#security-policies-project)
exclusively for managing policies for the project. Do not add your application's source code to such
projects.

The Security Policies feature is a repository to store policies. All security policies are stored in
the `.gitlab/security-policies/policy.yml` YAML file. The format for this YAML is specific to the type of policy that is being stored there. Examples and schema information are available for the following policy types:

- [Scan execution policy](scan-execution-policies.md#example-security-policies-project)
- [Scan result policy](scan-result-policies.md#example-security-scan-result-policies-project)

Policies created in this project are applied through a background job that runs once every 10
minutes. Allow up to 10 minutes for any policy changes committed to this project to take effect.

## Security Policy project selection

NOTE:
Only project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

When the Security Policy project is created and policies are created within that repository, you
must create an association between that project and the project you want to apply policies to:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Policies**.
1. Select **Edit Policy Project**, and search for and select the
   project you would like to link from the dropdown menu.
1. Select **Save**.

   ![Security Policy Project](img/security_policy_project_v14_6.png)

### Unlink Security Policy projects

Project owners can unlink Security Policy projects from development projects. To do this, follow
the steps described in [Security Policy project selection](#security-policy-project-selection),
but select the trash can icon in the modal.

## Scan execution policies

See [Scan execution policies](scan-execution-policies.md).

## Scan result policy editor

See [Scan result policies](scan-result-policies.md).

## Container Network Policy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32365) in GitLab 12.9.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/7476) in GitLab 14.8, and planned for [removal](https://gitlab.com/groups/gitlab-org/-/epics/7477) in GitLab 15.0.

WARNING:
Container Network Policy is in its end-of-life process. It's [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/7476)
for use in GitLab 14.8, and planned for [removal](https://gitlab.com/groups/gitlab-org/-/epics/7477)
in GitLab 15.0.

The **Container Network Policy** section provides packet flow metrics for
your application's Kubernetes namespace. This section has the following
prerequisites:

- Your project contains at least one [environment](../../../ci/environments/index.md).
- You've [installed Cilium](../../project/clusters/protect/container_network_security/quick_start_guide.md#use-the-cluster-management-template-to-install-cilium).
- You've configured the [Prometheus service](../../project/integrations/prometheus.md#enabling-prometheus-integration).

If you're using custom Helm values for Cilium, you must enable Hubble
with flow metrics for each namespace by adding the following lines to
your [Cilium values](../../project/clusters/protect/container_network_security/quick_start_guide.md#use-the-cluster-management-template-to-install-cilium):

```yaml
hubble:
  enabled: true
  metrics:
    enabled:
      - 'flow:sourceContext=namespace;destinationContext=namespace'
```

The **Container Network Policy** section displays the following information
about your packet flow:

- The total amount of the inbound and outbound packets
- The proportion of packets dropped according to the configured
  policies
- The per-second average rate of the forwarded and dropped packets
  accumulated over time window for the requested time interval

If a significant percentage of packets is dropped, you should
investigate it for potential threats by
examining the Cilium logs:

```shell
kubectl -n gitlab-managed-apps logs -l k8s-app=cilium -c cilium-monitor
```

### Change the status

To change a network policy's status:

- Select the network policy you want to update.
- Select **Edit policy**.
- Select the **Policy status** toggle to update the selected policy.
- Select **Save changes** to deploy network policy changes.

Disabled network policies have the `network-policy.gitlab.com/disabled_by: gitlab` selector inside
the `podSelector` block. This narrows the scope of such a policy and as a result it doesn't affect
any pods. The policy itself is still deployed to the corresponding deployment namespace.

### Container Network Policy editor

The policy editor only supports the [CiliumNetworkPolicy](https://docs.cilium.io/en/v1.8/policy/)
specification. Regular Kubernetes [NetworkPolicy](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#networkpolicy-v1-networking-k8s-io)
resources aren't supported.

Rule mode supports the following rule types:

- [Labels](https://docs.cilium.io/en/v1.8/policy/language/#labels-based).
- [Entities](https://docs.cilium.io/en/v1.8/policy/language/#entities-based).
- [IP/CIDR](https://docs.cilium.io/en/v1.8/policy/language/#ip-cidr-based). Only
  the `toCIDR` block without `except` is supported.
- [DNS](https://docs.cilium.io/en/v1.8/policy/language/#dns-based).
- [Level 4](https://docs.cilium.io/en/v1.8/policy/language/#layer-4-examples)
  can be added to all other rules.

Once your policy is complete, save it by selecting **Save policy**
at the bottom of the editor. Existing policies can also be
removed from the editor interface by selecting **Delete policy**
at the bottom of the editor.

### Configure a Network Policy Alert

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3438) and [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/287676) in GitLab 13.9.
> - The feature flag was removed and the Threat Monitoring Alerts Project was [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/287676) in GitLab 14.0.

You can use policy alerts to track your policy's impact. Alerts are only available if you've
[installed](../../clusters/agent/repository.md)
and [configured](../../clusters/agent/install/index.md#register-the-agent-with-gitlab)
an agent for this project.

There are two ways to create policy alerts:

- In the [policy editor UI](#container-network-policy-editor),
  by clicking **Add alert**.
- In the policy editor's YAML mode, through the `metadata.annotations` property:

  ```yaml
  metadata:
    annotations:
      app.gitlab.com/alert: 'true'
  ```

Once added, the UI updates and displays a warning about the dangers of too many alerts.

## Roadmap

See the [Category Direction page](https://about.gitlab.com/direction/protect/security_orchestration/)
for more information on the product direction of security policies within GitLab.
