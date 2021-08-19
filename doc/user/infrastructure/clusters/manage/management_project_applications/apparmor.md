---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install AppArmor with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install AppArmor you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/apparmor/helmfile.yaml
```

You can define one or more AppArmor profiles by adding them into
`applications/apparmor/values.yaml` as the following:

```yaml
profiles:
  profile-one: |-
    profile profile-one {
      file,
    }
```

Refer to the [AppArmor chart](https://gitlab.com/gitlab-org/charts/apparmor) for more information on this chart.
