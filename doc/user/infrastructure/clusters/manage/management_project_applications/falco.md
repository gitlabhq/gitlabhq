---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Falco with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

GitLab Container Host Security Monitoring uses [Falco](https://falco.org/)
as a runtime security tool that listens to the Linux kernel using eBPF. Falco parses system calls
and asserts the stream against a configurable rules engine in real-time. For more information, see
[Falco's Documentation](https://falco.org/docs/).

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install Falco you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/falco/helmfile.yaml
```

You can customize Falco's Helm variables by defining the
`applications/falco/values.yaml` file in your cluster
management project. Refer to the
[Falco chart](https://github.com/falcosecurity/charts/tree/master/falco)
for the available configuration options.

WARNING:
By default eBPF support is enabled and Falco uses an
[eBPF probe](https://falco.org/docs/event-sources/drivers/#using-the-ebpf-probe)
to pass system calls to user space. If your cluster doesn't support this, you can
configure it to use Falco kernel module instead by adding the following to
`applications/falco/values.yaml`:

```yaml
ebpf:
  enabled: false
```

In rare cases where probe installation on your cluster isn't possible and the kernel/probe
isn't pre-compiled, you may need to manually prepare the kernel module or eBPF probe with
[`driverkit`](https://github.com/falcosecurity/driverkit#against-a-kubernetes-cluster)
and install it on each cluster node.

By default, Falco is deployed with a limited set of rules. To add more rules, add
the following to `applications/falco/values.yaml` (you can get examples from
[Cloud Native Security Hub](https://securityhub.dev/)):

```yaml
customRules:
  file-integrity.yaml: |-
    - rule: Detect New File
      desc: detect new file created
      condition: >
        evt.type = chmod or evt.type = fchmod
      output: >
        File below a known directory opened for writing (user=%user.name
        command=%proc.cmdline file=%fd.name parent=%proc.pname pcmdline=%proc.pcmdline gparent=%proc.aname[2])
      priority: ERROR
      tags: [filesystem]
    - rule: Detect New Directory
      desc: detect new directory created
      condition: >
        mkdir
      output: >
        File below a known directory opened for writing (user=%user.name
        command=%proc.cmdline file=%fd.name parent=%proc.pname pcmdline=%proc.pcmdline gparent=%proc.aname[2])
      priority: ERROR
      tags: [filesystem]
```

By default, Falco only outputs security events to logs as JSON objects. To set it to output to an
[external API](https://falco.org/docs/alerts/#https-output-send-alerts-to-an-https-end-point)
or [application](https://falco.org/docs/alerts/#program-output),
add the following to `applications/falco/values.yaml`:

```yaml
falco:
  programOutput:
    enabled: true
    keepAlive: false
    program: mail -s "Falco Notification" someone@example.com

  httpOutput:
    enabled: true
    url: http://some.url
```

You can check these logs with the following command:

```shell
kubectl -n gitlab-managed-apps logs -l app=falco
```

Support for installing the Falco managed application is provided by the
GitLab Container Security group. If you run into unknown issues,
[open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new), and ping at
least 2 people from the
[Container Security group](https://about.gitlab.com/handbook/product/categories/#container-security-group).
