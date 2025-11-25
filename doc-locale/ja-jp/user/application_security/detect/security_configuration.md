---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セキュリティ設定
description: 設定、テスト、コンプライアンス、スキャン、イネーブルメント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトごとにセキュリティスキャナーを設定したり、複数のプロジェクトで共有されるスキャナー設定を作成したりできます。各プロジェクトを手動で設定すると、最大限の柔軟性が得られますが、スケールすると維持が困難になります。複数のプロジェクトまたはグループの場合、共有スキャナー設定により、必要に応じてカスタマイズを可能にしながら、より簡単な管理が実現します。

たとえば、同じセキュリティスキャン設定が手動で適用された10個のプロジェクトがある場合、1つの変更を10回行う必要があります。代わりに共有CI/CD設定を作成すると、1回の変更のみで済みます。

## 個々のプロジェクトを設定する {#configure-an-individual-project}

個々のプロジェクトでセキュリティスキャンを設定するには、次のいずれかの方法を使用します:

- CI/CD設定ファイルを編集します。
- UIでCI/CD設定を編集します。

### CI/CDファイルを使用する {#with-a-cicd-file}

個々のプロジェクトのセキュリティスキャンを手動で有効にするには、次のいずれかの方法を使用します:

- 個々のセキュリティスキャナーを有効にします。
- Auto DevOpsを使用して、すべてのセキュリティスキャナーを有効にします。

AutoDevOpsは、ほとんどのセキュリティスキャナーを有効にするための、最も手間のかからないパスを提供します。ただし、カスタマイズオプションは、個々のセキュリティスキャナーを有効にする場合と比較して制限されています。

#### 個々のセキュリティスキャナーを有効にする {#enable-individual-security-scanners}

設定をカスタマイズするオプションを使用して個々のセキュリティスキャンツールを有効にするには、`.gitlab-ci.yml`ファイルにセキュリティスキャナーのテンプレートを含めます。

個々のセキュリティスキャナーを有効にする方法については、ドキュメントを参照してください。

#### Auto DevOpsを使用してセキュリティスキャンを有効にする {#enable-security-scanning-by-using-auto-devops}

次のセキュリティスキャンツールをデフォルト設定で有効にするには、[Auto DevOps](../../../topics/autodevops/_index.md)を有効にします:

- [Auto SAST](../../../topics/autodevops/stages.md#auto-sast)
- [Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection)
- [Auto DAST](../../../topics/autodevops/stages.md#auto-dast)
- [Auto Dependency Scanning](../../../topics/autodevops/stages.md#auto-dependency-scanning)
- [Autoコンテナスキャン](../../../topics/autodevops/stages.md#auto-container-scanning)

Auto DevOpsを直接カスタマイズすることはできませんが、[プロジェクトの`.gitlab-ci.yml`ファイルにAuto DevOpsテンプレートを含める](../../../topics/autodevops/customize.md#customize-gitlab-ciyml)ことで、必要に応じて設定をオーバーライドできます。

### UIを使用する場合 {#with-the-ui}

**セキュリティ設定**ページを使用して、プロジェクトのセキュリティテストと脆弱性管理設定を表示および設定します。

**セキュリティテスト**タブには、デフォルトブランチの最新コミットのCI/CDパイプラインをチェックすることにより、各セキュリティツールのステータスが反映されます。

有効: セキュリティテストツールのアーティファクトが、パイプラインの出力に見つかりました。

無効 : CI/CDパイプラインが存在しないか、セキュリティテストツールのアーティファクトがパイプラインの出力に見つかりませんでした。

#### セキュリティ設定ページを表示 {#view-security-configuration-page}

プロジェクトのセキュリティ設定を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。

CI/CD設定ファイルへの変更の履歴を表示するには、**設定履歴**を選択します。

#### プロジェクトのセキュリティ設定を編集 {#edit-a-projects-security-configuration}

プロジェクトのセキュリティ設定を編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. 有効または設定するセキュリティスキャナーを選択し、指示に従います。

個々のセキュリティスキャナーを有効にして設定する方法の詳細については、ドキュメントを参照してください。

## 共有設定を作成する {#create-a-shared-configuration}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

同じセキュリティスキャン設定を複数のプロジェクトに適用するには、次のいずれかの方法を使用します:

- [スキャン実行ポリシー](../policies/scan_execution_policies.md)
- [パイプライン実行ポリシー](../policies/pipeline_execution_policies.md)

これらの各方法により、セキュリティスキャンを含むCI/CD設定を1回定義し、複数のプロジェクトおよびグループに適用できます。これらの方法には、各プロジェクトを個別に設定するよりも、いくつかの利点があります:

- 設定の変更は、各プロジェクトの代わりに1回だけ行う必要があります。
- 設定の変更を行う権限は制限されており、職務分離が提供されます。

## セキュリティスキャンをカスタマイズ {#customize-security-scanning}

要件と環境に合わせてセキュリティスキャンをカスタマイズできます。個々のセキュリティスキャナーをカスタマイズする方法の詳細については、ドキュメントを参照してください。

### ベストプラクティス {#best-practices}

セキュリティスキャン設定をカスタマイズする場合:

- デフォルトブランチへの変更をマージする前に、マージリクエストを使用して、セキュリティスキャンツールのすべてのカスタマイズをテストします。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。
- スキャンツールのCI/CDテンプレートを[含めます](../../../ci/yaml/_index.md#include)。テンプレートのコンテンツをコピーしないでください。
- 必要に応じて、テンプレートの値をオーバーライドするだけです。他のすべての値はテンプレートから継承されます。
- 本番環境ワークフローには、各テンプレートの安定したバージョンを使用します。安定バージョンは変更頻度が低く、破壊的な変更はGitLabのメジャーバージョン間でのみ行われます。最新バージョンには最新の変更が含まれていますが、GitLabのマイナーバージョン間で大きな変更がある場合があります。

### テンプレートエディション {#template-editions}

GitLabアプリケーションセキュリティツールには、最大2つのテンプレートエディションがあります:

- **安定版**: 安定版テンプレートはデフォルトです。信頼性が高く一貫したアプリケーションセキュリティエクスペリエンスを提供します。CI/CDパイプラインで安定性と予測可能な動作を必要とするほとんどのユーザーおよびプロジェクトでは、安定版テンプレートを使用する必要があります。
- **Latest**（最新）: このテンプレートは、最先端の機能にアクセスしてテストしたい方を対象としています。テンプレート名に`latest`という単語で識別されます。安定版とは見なされておらず、次のメジャーリリースで計画されている破壊的な変更が含まれている可能性があります。このテンプレートを使用すると、新しい機能と更新が安定版リリースの一部になる前に試すことができます。

{{< alert type="note" >}}

同じプロジェクトでセキュリティテンプレートを混在させないでください。異なるセキュリティテンプレートエディションを混在させると、マージリクエストとブランチパイプラインの両方が実行される可能性があります。

{{< /alert >}}

### デフォルトレジストリベースアドレスをオーバーライドする {#override-the-default-registry-base-address}

デフォルトでは、GitLabセキュリティスキャナーは、Dockerイメージのベースアドレスとして`registry.gitlab.com/security-products`を使用します。CI/CD変数 `SECURE_ANALYZERS_PREFIX`を別の場所に設定することにより、ほとんどのスキャナーでこれをオーバーライドできます。これは、すべてのスキャナーに一度に影響します。

[コンテナスキャン](../container_scanning/_index.md)アナライザーは例外であり、`SECURE_ANALYZERS_PREFIX`変数を使用しません。Dockerイメージをオーバーライドするには、[オフライン環境でのコンテナスキャンの実行](../container_scanning/_index.md#running-container-scanning-in-an-offline-environment)の手順を参照してください。

### マージリクエストパイプラインでセキュリティスキャンツールを使用するを参照してください。 {#use-security-scanning-tools-with-merge-request-pipelines}

デフォルトでは、アプリケーションセキュリティジョブは、ブランチパイプラインでのみ実行するように設定されています。それらを[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)で使用するには、次のいずれかを行います:

- CI/CD変数 `AST_ENABLE_MR_PIPELINES`を`"true"`に設定します（[18.0で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/410880)）（推奨）
- [`latest`エディションテンプレート](#template-editions)を使用します。これにより、マージリクエストパイプラインがデフォルトで有効になります。

たとえば、マージリクエストパイプラインを有効にして、SASTと依存関係スキャンの両方を実行するには、次の設定を使用します:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  AST_ENABLE_MR_PIPELINES: "true"
```

### カスタムスキャンステージを使用する {#use-a-custom-scanning-stage}

セキュリティスキャナーテンプレートは、デフォルトで定義済みの`test`ステージを使用します。代わりに別のステージで実行するには、カスタムステージの名前を`stages:`ファイルの`.gitlab-ci.yml`セクションに追加します。

セキュリティジョブのオーバーライドの詳細については、以下を参照してください:

- [SAST](../sast/_index.md#overriding-sast-jobs)ジョブをオーバーライドする。
- [Dependency Scanning](../dependency_scanning/_index.md#overriding-dependency-scanning-jobs)ジョブをオーバーライドする。
- [コンテナスキャンのジョブをオーバーライドする](../container_scanning/_index.md#overriding-the-container-scanning-template)。
- [シークレット検出のジョブをオーバーライドする](../secret_detection/pipeline/configure.md)。
- [DASTジョブをオーバーライドする](../dast/browser/_index.md)。

## トラブルシューティング {#troubleshooting}

セキュリティスキャンを設定する際に、次の問題が発生する可能性があります。

### エラー: `chosen stage test does not exist` {#error-chosen-stage-test-does-not-exist}

パイプラインの実行中に、`chosen stage test does not exist`というエラーが発生する場合があります。

この問題は、セキュリティスキャンジョブで使用されるステージが`.gitlab-ci.yml`ファイルで宣言されていない場合に発生します。

このエラーを解決するには:

- `.gitlab-ci.yml`に`test`ステージを追加します:

  ```yaml
  stages:
    - test
    - unit-tests

  include:
    - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    - template: Jobs/SAST.gitlab-ci.yml
    - template: Jobs/Secret-Detection.gitlab-ci.yml

  custom job:
    stage: unit-tests
    script:
      - echo "custom job"
  ```

- 各セキュリティジョブのデフォルトステージをオーバーライドします。たとえば、`unit-tests`という名前の事前定義されたステージを使用するには:

  ```yaml
  stages:
    - unit-tests

  include:
    - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
      inputs:
        stage: unit-tests
    - template: Jobs/SAST.gitlab-ci.yml
    - template: Jobs/Secret-Detection.gitlab-ci.yml

  sast:
    stage: unit-tests

  .secret-analyzer:
    stage: unit-tests

  custom job:
    stage: unit-tests
    script:
      - echo "custom job"
  ```
