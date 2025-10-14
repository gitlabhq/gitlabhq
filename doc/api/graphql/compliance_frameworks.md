---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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
  complianceFrameworkRequirementCreate(input: {
    frameworkId: "gid://gitlab/ComplianceManagement::Framework/1",
    name: "External Approval Requirement",
    description: "Require external system approval for deployments",
    externalControls: [{
      name: "ServiceNow Approval",
      externalUrl: "https://mycompany.service-now.com/api/approval",
      hmacSharedSecret: "my-secret-key"
    }]
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
  complianceFrameworkRequirementUpdate(input: {
    id: "gid://gitlab/ComplianceManagement::Requirement/1",
    name: "Updated Security Requirement",
    description: "Updated security scanning requirement with additional controls",
    controlIds: [
      "scanner_sast_running",
      "scanner_dep_scanning_running",
      "scanner_secret_detection_running",
      "scanner_container_scanning_running"
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

### Delete requirements

{{< details >}}

- Tier: Ultimate

{{< /details >}}

To delete a requirement from a framework:

```graphql
mutation {
  complianceFrameworkRequirementDestroy(input: {
    id: "gid://gitlab/ComplianceManagement::Requirement/1"
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
