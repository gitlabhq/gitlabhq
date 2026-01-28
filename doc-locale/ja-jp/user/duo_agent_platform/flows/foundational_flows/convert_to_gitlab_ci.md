---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDに変換フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

この機能は[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_in_ci`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。
- 機能フラグ`duo_workflow_in_ci`は、18.4ではデフォルトで有効になっています。フラグはGitLab 18.9で削除されました。
- `duo_workflow`フラグも有効にする必要がありますが、これはデフォルトで有効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab CI/CDに変換フローは、JenkinsパイプラインをGitLab CI/CDに移行するのに役立ちます。このフローには次の特長があります:

- 既存のJenkinsパイプライン設定を分析します。
- Jenkinsパイプライン構文をGitLab CI/CDのYAMLに変換します。
- GitLab CI/CD実装に関するベストプラクティスを提案します。
- 変換されたパイプライン設定を含むマージリクエストを作成します。
- JenkinsプラグインをGitLabの機能に移行するためのガイダンスを提供します。

このフローは、GitLab UIでのみ使用できます。

> [!note] GitLab CI/CDに変換フローは、サービスアカウントを使用してマージリクエストを作成します。SOC 2、SOX法、ISO 27001、またはFedRAMPの要件がある組織は、適切なピアレビューポリシーが整備されていることを確認してください。詳細については、[マージリクエストに関するコンプライアンス上の考慮事項](../../composite_identity.md#compliance-considerations-for-merge-requests)を参照してください。

## 前提条件 {#prerequisites}

Jenkinsfileを変換するには、次の要件を満たしている必要があります:

- Jenkinsパイプライン設定にアクセスできる。
- 対象となるGitLabプロジェクトのデベロッパーロール以上を持っている。
- [他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしている。
- [GitLab Duoサービスアカウントがコミットとブランチを作成できることを確認している](../../troubleshooting.md#session-is-stuck-in-created-state)。
- GitLab CI/CDに変換フローが[オンになっている](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off)ことを確認してください。

## フローを使用する {#use-the-flow}

JenkinsfileをGitLab CI/CDに変換するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. Jenkinsfileを開きます。
1. ファイルの上にある**GitLab CI/CDに変換**を選択します。
1. **自動化** > **セッション**を選択して、進捗状況を監視します。
1. パイプラインが正常に実行されたら、左側のサイドバーで、**コード** > **マージリクエスト**を選択します。`Duo Workflow: Convert to GitLab CI`というタイトルのマージリクエストが表示されます。
1. マージリクエストをレビューし、必要に応じて変更を加えます。

### 変換プロセス {#conversion-process}

このプロセスでは、次の内容が変換されます:

- パイプラインステージとステップ。
- 環境変数。
- ビルドトリガーとパラメータ。
- アーティファクトと依存関係。
- 並列実行。
- 条件ロジック。
- ビルド後アクション。

## 例 {#example}

Jenkinsfileの入力:

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm build'
            }
        }
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        stage('Deploy') {
            when { branch 'main' }
            steps {
                sh './deploy.sh'
            }
        }
    }
}
```

GitLabの出力:

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - npm install
    - npm build
  artifacts:
    paths:
      - node_modules/
      - dist/

test:
  stage: test
  script:
    - npm test

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - main
```
