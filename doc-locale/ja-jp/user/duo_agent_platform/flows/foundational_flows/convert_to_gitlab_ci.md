---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDフローに変換する
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_in_ci`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にできます。
- `duo_workflow`フラグも有効にする必要がありますが、これはデフォルトで有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab CI/CDフローへの変換は、JenkinsのパイプラインをGitLab CI/CDに移行するのに役立ちます。このフローの内容:

- 既存のJenkinsのパイプライン設定を分析します。
- Jenkinsのパイプライン構文をGitLab CI/CDのYAMLに変換します。
- GitLab CI/CD実装のためのベストプラクティスを提案します。
- 変換されたパイプライン設定でマージリクエストを作成します。
- JenkinsのプラグインをGitLabの機能に移行するためのガイダンスを提供します。

このフローは、GitLab UIでのみ使用できます。

## 前提要件 {#prerequisites}

Jenkinsfileを変換するには、以下が必要です:

- Jenkinsのパイプライン設定にアクセスできること。
- ターゲットのGitLabプロジェクトで、少なくともデベロッパーロールを持っている必要があります。
- [他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしている。
- [GitLab Duoサービスアカウントがコミットとブランチを作成できることを確認している](../../troubleshooting.md#session-is-stuck-in-created-state)。

## フローを使用する {#use-the-flow}

JenkinsfileをGitLab CI/CDに変換するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. Jenkinsfileを開きます。
1. ファイルの上にある**GitLab CI/CDに変換**を選択します。
1. **自動化** > **セッション**を選択して、進捗状況を監視します。
1. パイプラインが正常に実行されたら、左側のサイドバーで**コード** > **マージリクエスト**を選択します。タイトル`Duo Workflow: Convert to GitLab CI`のマージリクエストが表示されます。
1. マージリクエストをレビューし、必要に応じて変更を加えます。

### 変換プロセス {#conversion-process}

このプロセスで変換されるもの:

- パイプラインステージとステップ。
- 環境変数。
- ビルドトリガーとパラメータ。
- アーティファクトと依存関係。
- 並列実行。
- 条件ロジック。
- ビルド後アクション。

## 例 {#example}

Jenkinsfile入力:

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

GitLab出力:

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
