---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 준수 프레임워크 GraphQL API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GraphQL API를 사용하여 최상위 그룹의 준수 프레임워크를 관리합니다.

## 전제 조건 {#prerequisites}

- 준수 프레임워크를 생성, 편집 및 삭제하려면 사용자는 다음 중 하나를 수행합니다:
  - 최상위 그룹의 소유자 역할을 보유합니다.
  - [사용자 지정 역할](../../user/custom_roles/_index.md)이(가) `admin_compliance_framework` [사용자 지정 권한](../../user/custom_roles/abilities.md#compliance-management)으로 할당되어 있습니다.

## 템플릿에서 준수 프레임워크 생성 {#create-a-compliance-framework-from-a-template}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `compliance_framework_templates`라는 이름의 [플래그와 함께](../../administration/feature_flags/_index.md) GitLab 19.0에 [도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/16808). 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

사전 정의된 템플릿에서 준수 프레임워크를 생성합니다. 템플릿에는 공통 준수 표준과 일치하도록 미리 구성된 요구 사항 및 제어가 포함되어 있습니다.

### 사용 가능한 템플릿 나열 {#list-available-templates}

사용 가능한 모든 준수 프레임워크 템플릿을 나열하려면:

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

ID로 특정 템플릿을 가져오고 해당 전체 JSON 구조를 보려면:

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

사용 가능한 템플릿 ID:

| 템플릿 ID | 이름 |
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

### 템플릿에서 프레임워크 생성 {#create-a-framework-from-a-template}

템플릿에서 준수 프레임워크를 생성하려면 `createComplianceFrameworkFromTemplate` 변경 작업을 사용합니다. `templateId` 및 `namespacePath` 인수는 필수입니다. 다른 모든 인수는 템플릿 기본값을 선택적으로 재정의합니다.

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

템플릿의 기본 이름, 설명, 색상 및 기본 상태를 재정의할 수 있습니다:

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

프레임워크는 템플릿의 모든 요구 사항 및 제어가 미리 채워진 상태로 생성됩니다. 소스 템플릿 ID 및 버전은 불변 출처 필드로 기록되며 생성 후 변경할 수 없습니다.

프레임워크는 다음 경우에 생성됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

## 준수 프레임워크 생성 {#create-a-compliance-framework}

최상위 그룹을 위한 새로운 준수 프레임워크를 생성합니다.

준수 프레임워크를 생성하려면 `createComplianceFramework` 변경 작업을 사용합니다:

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

프레임워크는 다음 경우에 생성됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

### 요구 사항이 있는 프레임워크 생성 {#create-a-framework-with-requirements}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

특정 요구 사항 및 제어가 있는 프레임워크를 생성할 수 있습니다:

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

프레임워크를 생성한 후, 생성 변경 작업에서 반환된 프레임워크 ID를 사용하여 요구 사항을 추가할 수 있습니다.

## 준수 프레임워크 나열 {#list-compliance-frameworks}

최상위 그룹의 모든 준수 프레임워크를 나열합니다.

`group` 쿼리를 사용하여 최상위 그룹의 준수 프레임워크 목록을 볼 수 있습니다:

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

결과 목록이 비어 있으면 해당 그룹에 대한 준수 프레임워크가 없습니다.

## 프로젝트에 할당된 준수 프레임워크 나열 {#list-compliance-frameworks-assigned-to-a-project}

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

`"my-project"`을(를) 프로젝트의 전체 경로로 바꿉니다.

## 준수 프레임워크 업데이트 {#update-a-compliance-framework}

최상위 그룹의 기존 준수 프레임워크를 업데이트합니다.

준수 프레임워크를 업데이트하려면 `updateComplianceFramework` 변경 작업을 사용합니다. [모든 준수 프레임워크 나열](#list-compliance-frameworks)에 의해 그룹의 프레임워크 ID를 검색할 수 있습니다.

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

프레임워크는 다음 경우에 업데이트됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

## 준수 프레임워크 삭제 {#delete-a-compliance-framework}

최상위 그룹에서 준수 프레임워크를 삭제합니다.

준수 프레임워크를 삭제하려면 `destroyComplianceFramework` 변경 작업을 사용합니다. [모든 준수 프레임워크 나열](#list-compliance-frameworks)에 의해 그룹의 프레임워크 ID를 검색할 수 있습니다.

```graphql
mutation {
  destroyComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1"
  }) {
    errors
  }
}
```

프레임워크는 다음 경우에 삭제됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

## 프로젝트에 준수 프레임워크 적용 {#apply-compliance-frameworks-to-projects}

하나 이상의 준수 프레임워크를 프로젝트에 적용합니다.

전제 조건:

- 프로젝트의 유지 관리자 또는 소유자 역할
- 프로젝트는 준수 프레임워크를 보유한 그룹에 속해야 합니다.

준수 프레임워크를 프로젝트에 적용하려면 `projectUpdateComplianceFrameworks` 변경 작업을 사용합니다:

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

프레임워크는 다음 경우에 적용됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

### 프로젝트에서 준수 프레임워크 제거 {#remove-compliance-frameworks-from-projects}

프로젝트에서 모든 준수 프레임워크를 제거하려면 빈 배열을 전달합니다:

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

## 요구 사항 및 제어 작업 {#working-with-requirements-and-controls}

GraphQL을 사용하여 준수 프레임워크의 요구 사항 및 제어를 관리할 수 있습니다.

### 쿼리 프레임워크 요구 사항 {#query-framework-requirements}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

준수 프레임워크의 요구 사항 및 제어를 보려면:

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

### 프레임워크에 요구 사항 추가 {#add-requirements-to-a-framework}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

기존 프레임워크에 GitLab 준수 제어를 포함한 요구 사항을 추가하려면:

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

### 외부 제어 추가 {#add-external-controls}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

외부 제어를 포함한 요구 사항을 추가하려면:

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

### 요구 사항 업데이트 {#update-requirements}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

기존 요구 사항을 업데이트하려면:

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

### 요구 사항 삭제 {#delete-requirements}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

프레임워크에서 요구 사항을 삭제하려면:

```graphql
mutation {
  destroyComplianceRequirement(input: {
    id: "gid://gitlab/ComplianceManagement::ComplianceFramework::ComplianceRequirement/1"
  }) {
    errors
  }
}
```

## 오류 처리 {#error-handling}

GraphQL을 통해 준수 프레임워크를 사용할 때 다음과 같은 일반적인 오류가 발생할 수 있습니다:

- **Framework name already exists**:  각 프레임워크 이름은 그룹 내에서 고유해야 합니다.
- **Invalid color format**:  색상은 16진수 형식이어야 합니다(예: `#1f75cb`).
- **권한 부족**:  `admin_compliance_framework` 권한을 가진 그룹 소유자 또는 사용자만 프레임워크를 관리할 수 있습니다.
- **Invalid control ID**:  제어 ID는 지원되는 [GitLab 준수 제어](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)와 일치해야 합니다.

항상 응답의 `errors` 필드를 확인하여 변경 작업 중에 발생하는 문제를 처리합니다.

## 관련 항목 {#related-topics}

- [준수 프레임워크](../../user/compliance/compliance_frameworks/_index.md)
- [준수 센터](../../user/compliance/compliance_center/_index.md)
- [GraphQL API 참조](reference/_index.md)
