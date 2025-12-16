---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンプライアンスフレームワークGraphQL 
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

 を使用して、トップレベルグループのコンプライアンスフレームワークを管理します。

## 前提要件 {#prerequisites}

- コンプライアンスフレームワークを作成、編集、削除するには、次のいずれかのユーザーである必要があります:
  - トップレベルグループのオーナーロールが必要です。
  - `admin_compliance_framework` [カスタムパーミッション](../../user/custom_roles/abilities.md#compliance-management)を持つ[カスタムロール](../../user/custom_roles/_index.md)を割り当てられていること。

## コンプライアンスフレームワークを作成 {#create-a-compliance-framework}

トップレベルグループの新しいコンプライアンスフレームワークを作成します。

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

コンプライアンスフレームワークは、以下の場合に作成されます:

- 返された`errors`オブジェクトが空である。
- が`200 OK`で応答する。

### 要件を持つフレームワークを作成 {#create-a-framework-with-requirements}

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

フレームワークを作成した後、作成ミューテーションによって返されるフレームワークを使用して、要件を追加できます。

## コンプライアンスフレームワークの一覧表示 {#list-compliance-frameworks}

トップレベルグループのすべてのコンプライアンスフレームワークをリストします。

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

結果のリストが空の場合、そのグループのコンプライアンスフレームワークは存在しません。

## コンプライアンスフレームワークを更新 {#update-a-compliance-framework}

トップレベルグループの既存のコンプライアンスフレームワークを更新します。

コンプライアンスフレームワークを更新するには、`updateComplianceFramework`ミューテーションを使用します。グループの[すべてのコンプライアンスフレームワークを一覧表示](#list-compliance-frameworks)して、フレームワークを取得できます。

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

コンプライアンスフレームワークは、以下の場合に更新されます:

- 返された`errors`オブジェクトが空である。
- が`200 OK`で応答する。

## コンプライアンスフレームワークを削除 {#delete-a-compliance-framework}

トップレベルグループからコンプライアンスフレームワークを削除します。

コンプライアンスフレームワークを削除するには、`destroyComplianceFramework`ミューテーションを使用します。グループの[すべてのコンプライアンスフレームワークを一覧表示](#list-compliance-frameworks)して、フレームワークを取得できます。

```graphql
mutation {
  destroyComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1"
  }) {
    errors
  }
}
```

コンプライアンスフレームワークは、以下の場合に削除されます:

- 返された`errors`オブジェクトが空である。
- が`200 OK`で応答する。

## コンプライアンスフレームワークをプロジェクトに適用 {#apply-compliance-frameworks-to-projects}

1つ以上のコンプライアンスフレームワークをプロジェクトに適用します。

前提要件: 

- プロジェクトのメンテナーまたはオーナーのロールが必要です。
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

フレームワークは、以下の場合に適用されます:

- 返された`errors`オブジェクトが空である。
- が`200 OK`で応答する。

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

## 要件とコントロールの操作 {#working-with-requirements-and-controls}

を使用して、コンプライアンスフレームワークの要件とコントロールを管理できます。

### フレームワーク要件をクエリ {#query-framework-requirements}

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

 コンプライアンスコントロールを使用して、既存のフレームワークに要件を追加するには:

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

### 外部コントロールの追加 {#add-external-controls}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

外部コントロールを使用して要件を追加するには:

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

### 要件を更新 {#update-requirements}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

既存の要件を更新するには:

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

### 要件を削除 {#delete-requirements}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

フレームワークから要件を削除するには:

```graphql
mutation {
  complianceFrameworkRequirementDestroy(input: {
    id: "gid://gitlab/ComplianceManagement::Requirement/1"
  }) {
    errors
  }
}
```

## エラー処理 {#error-handling}

経由でコンプライアンスフレームワークを操作する場合、次の一般的なエラーが発生する可能性があります:

- **Framework name already exists**（フレームワーク名が既に存在します）: 各フレームワーク名は、グループ内で一意である必要があります。
- **Invalid color format**（無効な色の形式）: 色は16進形式である必要があります（例: `#1f75cb`）。
- **権限が不十分です**: グループオーナーまたは`admin_compliance_framework`権限を持つユーザーのみがフレームワークを管理できます。
- **Invalid control ID**（無効なコントロール）: コントロールは、サポートされている[コンプライアンスコントロール](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)と一致する必要があります。

応答の`errors`フィールドを常に確認して、ミューテーション中に発生する問題を処理してください。

## 関連トピック {#related-topics}

- [コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/_index.md)
- [コンプライアンスセンター](../../user/compliance/compliance_center/_index.md)
- GraphQL APIリファレンス[GraphQL APIリファレンス](reference/_index.md)
