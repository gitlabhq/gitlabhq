---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コンプライアンスフレームワークGraphQL API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

トップレベルグループのコンプライアンスフレームワークを、GraphQL APIを使用して管理します。

## 前提条件 {#prerequisites}

- コンプライアンスフレームワークを作成、編集、削除するには、ユーザーは次のいずれかの操作を行う必要があります:
  - トップレベルグループのオーナーロールを持っていること。
  - [カスタムロール](../../user/custom_roles/_index.md)または`admin_compliance_framework`[カスタム権限](../../user/custom_roles/abilities.md#compliance-management)が割り当てられていること。

## テンプレートからコンプライアンスフレームワークを作成する {#create-a-compliance-framework-from-a-template}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.0で[導入され](https://gitlab.com/groups/gitlab-org/-/work_items/16808)、`compliance_framework_templates`という名前の[フラグで](../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

定義済みテンプレートからコンプライアンスフレームワークを作成します。テンプレートには、一般的なコンプライアンス標準に合わせた事前設定済みの要件とコントロールが含まれています。

### 利用可能なテンプレートを一覧表示 {#list-available-templates}

利用可能なすべてのコンプライアンスフレームワークテンプレートを一覧表示するには:

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

IDで特定のテンプレートをフェッチし、その完全なJSON構造を表示するには:

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

利用可能なテンプレートID:

| テンプレートID | 名前 |
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

### テンプレートからフレームワークを作成 {#create-a-framework-from-a-template}

テンプレートからコンプライアンスフレームワークを作成するには、`createComplianceFrameworkFromTemplate`ミューテーションを使用します。`templateId`と`namespacePath`引数は必須です。その他のすべての引数は、テンプレートのデフォルトのオプションの上書きです。

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

テンプレートのデフォルトの名前、説明、色、デフォルトのステータスを上書きできます:

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

フレームワークは、テンプレートから自動入力されたすべての要件とコントロールで作成されます。ソーステンプレートIDとバージョンは、イミュータブルな来歴フィールドとして記録され、作成後に変更することはできません。

フレームワークは次の場合に作成されます:

- 返された`errors`オブジェクトが空である。
- APIが`200 OK`で応答する。

## コンプライアンスフレームワークを作成 {#create-a-compliance-framework}

トップレベルグループ用の新しいコンプライアンスフレームワークを作成します。

コンプライアンスフレームワークを作成するには、`createComplianceFramework`ミューテーションを使用します:

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

フレームワークは次の場合に作成されます:

- 返された`errors`オブジェクトが空である。
- APIが`200 OK`で応答する。

### 要件を含むフレームワークを作成 {#create-a-framework-with-requirements}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

特定の要件とコントロールを含むフレームワークを作成できます:

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

フレームワークを作成した後、作成ミューテーションによって返されたフレームワークIDを使用して要件を追加できます。

## コンプライアンスフレームワークを一覧表示 {#list-compliance-frameworks}

トップレベルグループのすべてのコンプライアンスフレームワークを一覧表示します。

`group`クエリを使用して、トップレベルグループのコンプライアンスフレームワークのリストを表示できます:

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

結果のリストが空の場合、そのグループにはコンプライアンスフレームワークが存在しません。

## プロジェクトに割り当てられているコンプライアンスフレームワークを一覧表示 {#list-compliance-frameworks-assigned-to-a-project}

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

`"my-project"`をプロジェクトのフルパスに置き換えます。

## コンプライアンスフレームワークを更新 {#update-a-compliance-framework}

トップレベルグループの既存のコンプライアンスフレームワークを更新します。

コンプライアンスフレームワークを更新するには、`updateComplianceFramework`ミューテーションを使用します。グループの[すべてのコンプライアンスフレームワークを一覧表示](#list-compliance-frameworks)して、フレームワークIDを取得できます。

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

フレームワークは次の場合に更新されます:

- 返された`errors`オブジェクトが空である。
- APIが`200 OK`で応答する。

## コンプライアンスフレームワークを削除 {#delete-a-compliance-framework}

トップレベルグループからコンプライアンスフレームワークを削除します。

コンプライアンスフレームワークを削除するには、`destroyComplianceFramework`ミューテーションを使用します。グループの[すべてのコンプライアンスフレームワークを一覧表示](#list-compliance-frameworks)して、フレームワークIDを取得できます。

```graphql
mutation {
  destroyComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1"
  }) {
    errors
  }
}
```

フレームワークは次の場合に削除されます:

- 返された`errors`オブジェクトが空である。
- APIが`200 OK`で応答する。

## コンプライアンスフレームワークをプロジェクトに適用 {#apply-compliance-frameworks-to-projects}

1つまたは複数のコンプライアンスフレームワークをプロジェクトに適用します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロール。
- プロジェクトは、コンプライアンスフレームワークを持つグループに属している必要があります。

プロジェクトにコンプライアンスフレームワークを適用するには、`projectUpdateComplianceFrameworks`ミューテーションを使用します:

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

フレームワークは次の場合に適用されます:

- 返された`errors`オブジェクトが空である。
- APIが`200 OK`で応答する。

### プロジェクトからコンプライアンスフレームワークを削除 {#remove-compliance-frameworks-from-projects}

プロジェクトからすべてのコンプライアンスフレームワークを削除するには、空の配列を渡します:

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

## 要件とコントロールを操作する {#working-with-requirements-and-controls}

GraphQLを使用して、コンプライアンスフレームワークの要件とコントロールを管理できます。

### フレームワークの要件をクエリ {#query-framework-requirements}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

コンプライアンスフレームワークの要件とコントロールを表示するには:

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

### フレームワークに要件を追加 {#add-requirements-to-a-framework}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

GitLabのコンプライアンスコントロールを持つ要件を既存のフレームワークに追加するには:

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

### 外部コントロールを追加 {#add-external-controls}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

外部コントロールを持つ要件を追加するには:

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

### 要件を更新 {#update-requirements}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

既存の要件を更新するには:

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

### 要件を削除 {#delete-requirements}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

フレームワークから要件を削除するには:

```graphql
mutation {
  destroyComplianceRequirement(input: {
    id: "gid://gitlab/ComplianceManagement::ComplianceFramework::ComplianceRequirement/1"
  }) {
    errors
  }
}
```

## エラー処理 {#error-handling}

GraphQLを介してコンプライアンスフレームワークを操作する際に、以下の一般的なエラーが発生する可能性があります:

- **Framework name already exists**: 各フレームワーク名はグループ内で一意である必要があります。
- **Invalid color format**: 色は16進数形式である必要があります（例: `#1f75cb`）。
- **権限が不十分です**: グループオーナーまたは`admin_compliance_framework`権限を持つユーザーのみがフレームワークを管理できます。
- **Invalid control ID**: コントロールIDは、サポートされている[GitLabコンプライアンスコントロール](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)と一致する必要があります。

ミューテーション中に発生する問題を処理するには、常にレスポンスの`errors`フィールドを確認してください。

## 関連トピック {#related-topics}

- [コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/_index.md)
- [コンプライアンスセンター](../../user/compliance/compliance_center/_index.md)
- [GraphQL APIリファレンス](reference/_index.md)
