---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD変換フロー
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_in_ci`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。
- 機能フラグ`duo_workflow_in_ci`はGitLab 18.4でデフォルトで有効になりました。機能フラグ`duo_workflow`も有効にする必要がありますが、デフォルトでは有効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- 機能フラグ`duo_workflow_in_ci`と`duo_workflow`はGitLab 18.9で削除されました。
- GitLab 18.10では、GitLab.comのFreeティアでGitLabクレジットとともに利用できます。

{{< /history >}}

GitLab CI/CD変換フローは、JenkinsパイプラインをGitLab CI/CDに移行するのに役立ちます。このフローには次の特長があります:

- 既存のJenkinsパイプライン設定を分析します。
- Jenkinsパイプライン構文をGitLab CI/CDのYAMLに変換します。
- GitLab CI/CD実装に関するベストプラクティスを提案します。
- 変換されたパイプライン設定を含むマージリクエストを作成します。
- JenkinsプラグインをGitLabの機能に移行するためのガイダンスを提供します。

このフローは、GitLab UIでのみ使用できます。

## 前提条件 {#prerequisites}

Jenkinsfileを変換するには、次の条件を満たしている必要があります:

- Jenkinsパイプライン設定にアクセスできる。
- ターゲットのGitLabプロジェクトでデベロッパー、メンテナー、またはオーナーロールを持っていること。
- [他の前提条件](../../_index.md#prerequisites)を満たしている。
- [GitLab Duoサービスアカウントがコミットとブランチを作成できることを確認している](../../troubleshooting.md#session-is-stuck-in-created-state)。
- トップレベルグループで**基本フローを許可**および**GitLab CI/CD変換**が[有効になっている](_index.md#turn-foundational-flows-on-or-off)ことを確認してください。

## フローを使用する {#use-the-flow}

JenkinsfileをGitLab CI/CDに変換するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. Jenkinsfileを開きます。
1. ファイルの上にある**GitLab CI/CD変換**を選択します。
1. **自動化** > **セッション**を選択して、進捗状況を監視します。
1. パイプラインの実行が正常に完了したら、左サイドバーで**コード** > **マージリクエスト**を選択します。`Duo Workflow: Convert to GitLab CI`というタイトルのマージリクエストが表示されます。
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
