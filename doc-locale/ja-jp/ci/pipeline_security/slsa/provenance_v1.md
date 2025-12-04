---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SLSA来歴仕様
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`slsa_provenance_statement`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/547865)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

[SLSA](https://slsa.dev/spec/v1.1/provenance)構成証明の仕様では、`buildType`参照をドキュメント化し、公開する必要があります。この参照は、GitLab SLSA構成証明のコンシューマーが、GitLab SLSA構成証明ステートメントに固有の特定のフィールドを解析するのを支援するためのものです。

詳細については、[`buildType`のドキュメント](https://slsa.dev/spec/v1.1/provenance#builddefinition)を参照してください。

## `buildType` {#buildtype}

この公式の[SLSA Provenance](https://slsa.dev/spec/v1.1/provenance) `buildType`参照:

- GitLab [CI/CD](_index.md)ジョブの実行について説明します。
- GitLabによってホストおよびメンテナンスされています。

### 説明 {#description}

この`buildType`は、ソフトウェアアーティファクトをビルドするワークフローの実行について説明します。

{{< alert type="note" >}}

コンシューマーは、認識されない外部パラメータを無視する必要があります。変更によって、既存の外部パラメータのセマンティクスが変更されてはなりません。

{{< /alert >}}

### 外部パラメータ {#external-parameters}

外部パラメータ:

| フィールド        | 値 |
|--------------|-------|
| `source`     | プロジェクトのURL。 |
| `entryPoint` | ビルドをトリガーしたCI/CDジョブの名前。 |
| `variables`  | ビルドコマンドの実行時に使用できるCI/CDまたは環境変数の名前と値。変数が[マスクまたは非表示](../../variables/_index.md)の場合、変数の値は`[MASKED]`に設定されます。 |

### 内部パラメータ {#internal-parameters}

内部パラメータ（デフォルトで入力されたもの）:

| フィールド          | 値 |
|----------------|-------|
| `name`         | Runnerの名前。 |
| `executor`     | Runnerのexecutor。 |
| `architecture` | CI/CDジョブが実行されるアーキテクチャ。 |
| `job`          | ビルドをトリガーしたCI/CDジョブのID。 |

### 例 {#example}

この例は、GitLabで生成された構成証明ステートメントの形式を示しています:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "name": "artifacts.zip",
      "digest": {
        "sha256": "717a1ee89f0a2829cf5aad57054c83615675b04baa913bdc19999d7519edf3f2"
      }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "<Link to Build Type>",
      "externalParameters": {
        "source": "http://gdk.test:3000/root/repo_name",
        "entryPoint": "build-job",
        "variables": {
          "CI_PIPELINE_ID": "576",
          "CI_PIPELINE_URL": "http://gdk.test:3000/root/repo_name/-/pipelines/576",
          "CI_JOB_ID": "412",
[... additional environment variables ...]
          "masked_and_hidden_variable": "[MASKED]",
          "masked_variable": "[MASKED]",
          "visible_variable": "visible_variable",
        }
      },
      "internalParameters": {
        "architecture": "arm64",
        "executor": "docker",
        "job": 412,
        "name": "9-mfdkBG"
      },
      "resolvedDependencies": [
        {
          "uri": "http://gdk.test:3000/root/repo_name",
          "digest": {
            "gitCommit": "a288201509dd9a85da4141e07522bad412938dbe"
          }
        }
      ]
    },
    "runDetails": {
      "builder": {
        "id": "http://gdk.test:3000/groups/user/-/runners/33",
        "version": {
          "gitlab-runner": "4d7093e1"
        }
      },
      "metadata": {
        "invocationId": 412,
        "startedOn": "2025-06-05T01:33:18Z",
        "finishedOn": "2025-06-05T01:33:23Z"
      }
    }
  }
}
```
