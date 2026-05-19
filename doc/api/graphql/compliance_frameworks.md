---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Compliance frameworks GraphQL API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Manage compliance frameworks for top-level groups by using a GraphQL API.

## Prerequisites

- To create, edit, and delete compliance frameworks, users either:
  - Have the Owner role for the top-level group.
  - Be assigned a [custom role](../../user/custom_roles/_index.md) with the `admin_compliance_framework`
    [custom permission](../../user/custom_roles/abilities.md#compliance-management).

## Create a compliance framework from a template

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/16808) in GitLab 19.0
  [with a flag](../../administration/feature_flags/_index.md) named
  `compliance_framework_templates`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Create a compliance framework from a predefined template. Templates include
preconfigured requirements and controls aligned to common compliance standards.

### List available templates

To list all available compliance framework templates:

```graphql
query {
  complianceFrameworkTemplates {
    id
    name
    description
    color
    templateVersion
  }
}
```

To fetch a specific template by ID and view its full JSON structure:

```graphql
query {
  complianceFrameworkTemplates(
    id: "gid://gitlab/ComplianceManagement::Frameworks::TemplateRegistry::Template/soc2"
  ) {
    id
    name
    description
    color
    templateVersion
    json
  }
}
```

Available template IDs:

| Template ID | Name |
|-------------|------|
| `cis_csc_v8-1` | CIS CSC v8.1 |
| `csa_ccm_v4` | CSA CCM v4 |
| `cyber_essentials` | Cyber Essentials |
| `dora` | DORA |
| `fedramp_high_r5` | FedRAMP High |
| `fedramp_low_r5` | FedRAMP Low |
| `fedramp_moderate_r5` | FedRAMP Moderate |
| `irap_official` | IRAP Official |
| `irap_protected` | IRAP Protected |
| `irap_secret` | IRAP Secret |
| `irap_top_secret` | IRAP Top Secret |
| `ismap` | ISMAP |
| `iso_27001:2022` | ISO 27001:2022 |
| `nis_2` | NIS 2 |
| `nist_800-171_r3_cmmc` | NIST 800-171 Rev. 3 CMMC |
| `nist_800-218_v1-1` | NIST SP 800-218 |
| `nist_800-53_r5` | NIST 800-53 Revision 5 |
| `soc2` | SOC 2 |
| `tisax` | TISAX |

### Create a framework from a template

To create a compliance framework from a template, use the
`createComplianceFrameworkFromTemplate` mutation. The `templateId` and
`namespacePath` arguments are required. All other arguments are optional
overrides of the template defaults.

```graphql
mutation {
  createComplianceFrameworkFromTemplate(
    input: {
      namespacePath: "my-group"
      templateId: "gid://gitlab/ComplianceManagement::Frameworks::TemplateRegistry::Template/soc2"
    }
  ) {
    framework {
      id
      name
      description
      color
    }
    errors
  }
}
```

You can override the template's default name, description, color, and
default status:

```graphql
mutation {
  createComplianceFrameworkFromTemplate(
    input: {
      namespacePath: "my-group"
      templateId: "gid://gitlab/ComplianceManagement::Frameworks::TemplateRegistry::Template/soc2"
      name: "Custom SOC 2"
      description: "Our organization's SOC 2 compliance framework"
      color: "#FCA121"
      default: true
    }
  ) {
    framework {
      id
      name
      description
      color
    }
    errors
  }
}
```

The framework is created with all requirements and controls from the template
pre-populated. The source template ID and version are recorded as immutable
provenance fields and cannot be changed after creation.

The framework is created if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Create a compliance framework

Create a new compliance framework for a top-level group.

To create a compliance framework, use the `createComplianceFramework` mutation:

```graphql
mutation {
  createComplianceFramework(input: {
    namespacePath: "my-group",
    params: {
      name: "SOX Compliance",
      description: "Sarbanes-Oxley compliance framework for financial reporting",
      color: "#1f75cb",
      default: false
    }
  }) {
    errors
    framework {
      id
      name
      description
      color
      default
      namespace {
        name
      }
    }
  }
}
```

The framework is created if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

### Create a framework with requirements

{{< details >}}

- Tier: Ultimate

{{< /details >}}

You can create frameworks with specific requirements and controls:

```graphql
mutation {
  createComplianceFramework(input: {
    namespacePath: "my-group",
    params: {
      name: "Security Framework",
      description: "Security compliance framework with SAST and dependency scanning",
      color: "#e24329",
      default: false
    }
  }) {
    errors
    framework {
      id
      name
      description
      color
      default
      namespace {
        name
      }
    }
  }
}
```

After creating the framework, you can add requirements by using the framework ID returned by the creation mutation.

## List compliance frameworks

List all compliance frameworks for a top-level group.

You can view a list of compliance frameworks for a top-level group by using the `group` query:

```graphql
query {
  group(fullPath: "my-group") {
    id
    complianceFrameworks {
      nodes {
        id
        name
        description
        color
        default
        pipelineConfigurationFullPath
      }
    }
  }
}
```

If the resulting list is empty, then no compliance frameworks exist for that group.

## List compliance frameworks assigned to a Project

```graphql
query {
 project(fullPath: "my-project"){
  id
  name
  complianceFrameworks{
    nodes{
      id
      name
      }
    }
  }
}

```

Replace `"my-project"` with your project's full path.

## Update a compliance framework

Update an existing compliance framework for a top-level group.

To update a compliance framework, use the `updateComplianceFramework` mutation. You can retrieve the framework ID
by [listing all compliance frameworks](#list-compliance-frameworks) for the group.

```graphql
mutation {
  updateComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1",
    params: {
      name: "Updated SOX Compliance",
      description: "Updated Sarbanes-Oxley compliance framework",
      color: "#6b4fbb",
      default: true
    }
  }) {
    errors
    framework {
      id
      name
      description
      color
      default
      namespace {
        name
      }
    }
  }
}
```

The framework is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Delete a compliance framework

Delete a compliance framework from a top-level group.

To delete a compliance framework, use the `destroyComplianceFramework` mutation. You can retrieve the framework ID
by [listing all compliance frameworks](#list-compliance-frameworks) for the group.

```graphql
mutation {
  destroyComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1"
  }) {
    errors
  }
}
```

The framework is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Apply compliance frameworks to projects

Apply one or more compliance frameworks to projects.

Prerequisites:

- Maintainer or Owner role for the project.
- The project must belong to a group that has compliance frameworks.

To apply compliance frameworks to a project, use the `projectUpdateComplianceFrameworks` mutation:

```graphql
mutation {
  projectUpdateComplianceFrameworks(input: {
    projectId: "gid://gitlab/Project/1",
    complianceFrameworkIds: [
      "gid://gitlab/ComplianceManagement::Framework/1",
      "gid://gitlab/ComplianceManagement::Framework/2"
    ]
  }) {
    errors
    project {
      id
      complianceFrameworks {
        nodes {
          id
          name
          color
        }
      }
    }
  }
}
```

The frameworks are applied if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

### Remove compliance frameworks from projects

To remove all compliance frameworks from a project, pass an empty array:

```graphql
mutation {
  projectUpdateComplianceFrameworks(input: {
    projectId: "gid://gitlab/Project/1",
    complianceFrameworkIds: []
  }) {
    errors
    project {
      id
      complianceFrameworks {
        nodes {
          id
          name
        }
      }
    }
  }
}
```

## Working with requirements and controls

You can manage requirements and controls for compliance frameworks by using GraphQL.

### Query framework requirements

{{< details >}}

- Tier: Ultimate

{{< /details >}}

To view requirements and controls for a compliance framework:

```graphql
query {
  group(fullPath: "my-group") {
    complianceFrameworks {
      nodes {
        id
        name
        requirements {
          nodes {
            id
            name
            description
            controls {
              nodes {
                id
                name
                controlId
                controlType
              }
            }
          }
        }
      }
    }
  }
}
```

### Add requirements to a framework

{{< details >}}

- Tier: Ultimate

{{< /details >}}

To add a requirement with GitLab compliance controls to an existing framework:

```graphql
mutation {
  complianceFrameworkRequirementCreate(input: {
    frameworkId: "gid://gitlab/ComplianceManagement::Framework/1",
    name: "Security Scanning Requirement",
    description: "Ensure security scanning is enabled for all projects",
    controlIds: [
      "scanner_sast_running",
      "scanner_dep_scanning_running",
      "scanner_secret_detection_running"
    ]
  }) {
    errors
    requirement {
      id
      name
      description
      controls {
        nodes {
          id
          name
          controlId
        }
      }
    }
  }
}
```

### Add external controls

{{< details >}}

- Tier: Ultimate

{{< /details >}}

To add a requirement with external controls:

```graphql
mutation {
  createComplianceRequirement(
    input: {
      complianceFrameworkId: "gid://gitlab/ComplianceManagement::Framework/1",
      controls: [{
        controlType: "external",
        name: "external_control",
        externalControlName: "ServiceNowApproval",
        externalUrl: "https://mycompany.service-now.com/api/approval",
        secretToken: "my-secret-key"
      }],
      params: {
        name: "External Approval Requirement",
        description: "Require external system approval for deployments"
      }
    }
  ) {
    errors
    requirement {
      id
      name
      description
      complianceRequirementsControls {
        nodes {
          id
          name
          controlType
          externalUrl
        }
      }
    }
  }
}
```

### Update requirements

{{< details >}}

- Tier: Ultimate

{{< /details >}}

To update an existing requirement:

```graphql
mutation {
  updateComplianceRequirement(input: {
    id: "gid://gitlab/ComplianceManagement::ComplianceFramework::ComplianceRequirement/1",
    params: {
      name: "Updated Security Requirement",
      description: "Updated security scanning requirement with additional controls"
    },
    controls: [{
        expression: "{\"field\":\"scanner_sast_running\",\"operator\":\"=\",\"value\":true}",
        name: "scanner_sast_running"
      },
      {
        expression: "{\"field\":\"scanner_dep_scanning_running\",\"operator\":\"=\",\"value\":true}",
        name: "scanner_dep_scanning_running"
      },
      {
        expression: "{\"field\":\"scanner_secret_detection_running\",\"operator\":\"=\",\"value\":true}",
        name: "scanner_secret_detection_running"
      }]
  })
  {
    errors
    requirement {
      id
      name
      description
      complianceRequirementsControls {
        nodes {
          id
          name
        }
      }
    }
  }
}
```

### Delete requirements

{{< details >}}

- Tier: Ultimate

{{< /details >}}

To delete a requirement from a framework:

```graphql
mutation {
  destroyComplianceRequirement(input: {
    id: "gid://gitlab/ComplianceManagement::ComplianceFramework::ComplianceRequirement/1"
  }) {
    errors
  }
}
```

## Error handling

When working with compliance frameworks via GraphQL, you may encounter the following common errors:

- **Framework name already exists**: Each framework name must be unique within a group.
- **Invalid color format**: Colors must be in hexadecimal format (for example, `#1f75cb`).
- **Insufficient permissions**: Only group owners or users with the `admin_compliance_framework` permission can manage frameworks.
- **Invalid control ID**: Control IDs must match the supported [GitLab compliance controls](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls).

Always check the `errors` field in the response to handle any issues that occur during mutations.

## Related topics

- [Compliance frameworks](../../user/compliance/compliance_frameworks/_index.md)
- [Compliance center](../../user/compliance/compliance_center/_index.md)
- [GraphQL API reference](reference/_index.md)
