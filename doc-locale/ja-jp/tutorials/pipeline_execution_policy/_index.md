---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "チュートリアル: パイプライン実行ポリシーをセットアップする"
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、`inject_policy`ストラテジを使用して[パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)を作成および構成する方法を説明します。これらのポリシーを使用すると、ポリシーがリンクされているプロジェクトで、必要なパイプラインを常に実行できます。

このチュートリアルでは、パイプライン実行ポリシーを作成し、テストプロジェクトにリンクして、パイプラインが実行されることを確認できます。

パイプライン実行ポリシーをセットアップするには、次のようにします:

1. [テストプロジェクトの作成](#create-a-test-project)。
1. [CI/CDの設定ファイルを作成](#create-a-cicd-configuration-file)。
1. [パイプライン実行ポリシーを追加](#add-a-pipeline-execution-policy)。
1. [パイプライン実行ポリシーをテスト](#test-the-pipeline-execution-policy)。

## はじめる前 {#before-you-begin}

このチュートリアルを完了するには、以下が必要です:

- 既存のグループでプロジェクトを作成する権限。
- セキュリティポリシーを作成し、リンクする権限。

## テストプロジェクトの作成 {#create-a-test-project}

まず、パイプライン実行ポリシーを適用するテストプロジェクトを作成します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **新規プロジェクト**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. フィールドに入力します。
   - **プロジェクト名**：`my-pipeline-execution-policy`。
   - **静的アプリケーションセキュリティテスト (SAST) を有効にする**チェックボックスを選択します。
1. **プロジェクトを作成**を選択します。

## CI/CDの設定ファイルを作成 {#create-a-cicd-configuration-file}

次に、パイプライン実行ポリシーで適用するCI/CD設定ファイルを作成します:

1. **コード** > **リポジトリ**を選択します。
1. **追加**(+) ドロップダウンリストから、**新しいファイル**を選択します。
1. **ファイル名**フィールドに、`pipeline-config.yml`と入力します。
1. ファイルの内容に、以下をコピーします:

   ```yaml
   # This file defines the CI/CD jobs that will be enforced by the pipeline execution policy
   enforced-security-scan:
     stage: .pipeline-policy-pre
     script:
       - echo "Running enforced security scan from pipeline execution policy"
       - echo "This job cannot be skipped by developers"
       - echo "Checking for security vulnerabilities..."
       - echo "Security scan completed successfully"
     rules:
       - when: always

   enforced-test-job:
     stage: test
     script:
      - echo "Running enforced test job in test stage"
      - echo "Creating test stage if it doesn't exist"
      - echo "Performing mandatory testing requirements..."
      - echo "Enforced tests completed successfully"
    rules:
      - when: always

   enforced-compliance-check:
     stage: .pipeline-policy-post
     script:
       - echo "Running enforced compliance check"
       - echo "Verifying pipeline compliance requirements"
       - echo "Compliance check passed"
     rules:
       - when: always
   ```

1. **コミットメッセージ**フィールドに、`Add pipeline execution policy configuration`と入力します。
1. **変更をコミットする**を選択します。

## パイプライン実行ポリシーを追加 {#add-a-pipeline-execution-policy}

次に、パイプライン実行ポリシーをテストプロジェクトに追加します:

1. **セキュリティ** > **ポリシー**を選択します。
1. **新規ポリシー**を選択します。
1. **パイプライン実行ポリシー**で、**ポリシーの選択**を選択します。
1. フィールドに入力します。
   - **名前**: `Enforce Security and Compliance Jobs`
   - **説明**：`Enforces required security and compliance jobs across all pipelines`
   - **ポリシーステータス**: **有効**

1. **アクション**を以下のように設定します:

   ```plaintext
   Inject into into the .gitlab-ci.yml with the pipeline execution file from My Pipeline Execution Policy
   Filepath: [group]/my-pipeline-execution/policy/pipeline-config.yml
   ```

1. **マージリクエスト経由で設定**を選択します。

1. マージリクエストの**変更**タブで、生成されたポリシーYAMLをレビューします。ポリシーは次のようになります:

   ```yaml
   ---
   pipeline_execution_policy:
   - name: Enforce Security and Compliance Jobs
     description: Enforces required security and compliance jobs across all pipelines
     enabled: true
     pipeline_config_strategy: inject_policy
     content:
       include:
       - project: [group]/my-pipeline-execution-policy
         file: pipeline-config.yml
     skip_ci:
       - allowed: false
   ```

1. **概要**タブに移動し、**マージ**を選択します。このステップでは、`My Pipeline Execution Policy - Security Policy Project`という新しいプロジェクトが作成されます。セキュリティポリシープロジェクトは、セキュリティポリシーを保存するために使用され、同じポリシーを複数のプロジェクトに適用できます。

1. 左側のサイドバーで、**検索または移動先**を選択し、`my-pipeline-execution-policy`プロジェクトを見つけます。

1. **セキュリティ** > **ポリシー**を選択します。

   前の手順で追加されたポリシーのリストを確認できます。

## パイプライン実行ポリシーをテスト {#test-the-pipeline-execution-policy}

次に、マージリクエストを作成して、パイプライン実行ポリシーをテストします:

1. **コード** > **リポジトリ**を選択します。
1. **追加**(+) ドロップダウンリストから、**新しいファイル**を選択します。
1. **ファイル名**フィールドに、`test-file.txt`と入力します。
1. ファイルの内容に、以下を追加します:

   ```plaintext
   This is a test file to trigger the pipeline execution policy.
   ```

1. **コミットメッセージ**フィールドに、`Add test file to trigger pipeline`と入力します。
1. **Target Branch**（ターゲットブランチ）フィールドに、`test-policy-branch`と入力します。
1. **変更をコミットする**を選択します。
1. マージリクエストページが開いたら、**マージリクエストを作成**を選択します。

   パイプラインが完了するまで待ちます。これには数分かかる場合があります。

1. マージリクエストで**パイプライン**タブを選択し、作成されたパイプラインを選択します。

   強制されたジョブの実行が表示されるはずです:
   - `enforced-security-scan` (`.pipeline-policy-pre`ステージで最初に実行)
   - `enforced-test-job` (ポリシーによってインジェクトされた) `test`ステージ
   - `enforced-compliance-check` (`.pipeline-policy-post`ステージで最後に実行)

1. `enforced-security-scan`ジョブを選択して、そのログを表示し、ポリシーで定義されているセキュリティスキャンが実行されたことを確認します。

パイプライン実行ポリシーは、デベロッパーがプロジェクトの`.gitlab-ci.yml`ファイルに含める内容に関係なく、必要なジョブを正常に強制し、実行されるようにします。

これで、パイプライン実行ポリシーを設定して使用し、組織内のプロジェクト全体で必要なCI/CDジョブの使用を強制する方法がわかりました。

## 次の手順 {#next-steps}

- [パイプライン実行ポリシーの構成ストラテジ](../../user/application_security/policies/pipeline_execution_policies.md#pipeline-configuration-strategies)の詳細をご覧ください。
- [高度なパイプライン実行ポリシーの例](../../user/application_security/policies/pipeline_execution_policies.md#examples)を調査する。
