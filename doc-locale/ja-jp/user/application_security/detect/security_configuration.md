---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セキュリティ設定
description: 設定、テスト、コンプライアンス、スキャン、およびイネーブルメント。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

個々のプロジェクトに対してセキュリティスキャナーを設定することも、複数のプロジェクトで共有するスキャナー設定を作成することもできます。各プロジェクトを手動で設定すると最大の柔軟性が得られますが、規模が拡大すると維持が困難になります。複数のプロジェクトやグループの場合、共有スキャナー設定により管理が容易になり、必要な場合はカスタマイズも可能です。

たとえば、同じセキュリティスキャン設定が手動で適用されたプロジェクトが10個ある場合、1つの変更を10回行う必要があります。代わりに共有CI/CD設定を作成した場合、1つの変更は1回行うだけで済みます。

## 個々のプロジェクトを設定する {#configure-an-individual-project}

個々のプロジェクトでセキュリティスキャンを設定するには、次のいずれかの方法を使用します:

- CI/CD設定ファイルを編集します。
- UIでCI/CD設定を編集します。

### CI/CDファイルを使用する {#with-a-cicd-file}

個々のプロジェクトのセキュリティスキャンを手動で有効にするには、次のいずれかの方法を使用します:

- 個々のセキュリティスキャナーを有効にします。
- Auto DevOpsを使用してすべてのセキュリティスキャナーを有効にします。

Auto DevOpsは、ほとんどのセキュリティスキャナーを有効にするための最小限の労力で済むパスを提供します。ただし、個々のセキュリティスキャナーを有効にする場合と比較して、カスタマイズオプションは制限されています。

#### 個々のセキュリティスキャナーを有効にする {#enable-individual-security-scanners}

個々のセキュリティスキャンツールを設定のカスタマイズオプション付きで有効にするには、セキュリティスキャナーのテンプレートを`.gitlab-ci.yml`ファイルに含めます。

個々のセキュリティスキャナーを有効にする方法については、それらのドキュメントを参照してください。

#### Auto DevOpsを使用してセキュリティスキャンを有効にする {#enable-security-scanning-by-using-auto-devops}

次のセキュリティスキャンツールをデフォルト設定で有効にするには、[Auto DevOps](../../../topics/autodevops/_index.md)を有効にしてください:

- [Auto SAST](../../../topics/autodevops/stages.md#auto-sast)
- [Autoシークレット検出](../../../topics/autodevops/stages.md#auto-secret-detection)
- [Auto DAST](../../../topics/autodevops/stages.md#auto-dast)
- [Auto依存関係スキャン](../../../topics/autodevops/stages.md#auto-dependency-scanning)
- [Autoコンテナスキャン](../../../topics/autodevops/stages.md#auto-container-scanning)

Auto DevOpsを直接カスタマイズすることはできませんが、[プロジェクトの`.gitlab-ci.yml`ファイルにAuto DevOpsテンプレートを含める](../../../topics/autodevops/customize.md#customize-gitlab-ciyml)ことで、必要に応じて設定をオーバーライドできます。

### UIを使用する場合 {#with-the-ui}

「**セキュリティ設定**」ページを使用して、プロジェクトのセキュリティテストと脆弱性管理設定を表示および設定できます。

「**セキュリティテスト**」タブには、デフォルトブランチの最新のコミットにおけるCI/CDパイプラインをチェックすることにより、各セキュリティツールのステータスが反映されます。

有効: セキュリティテストツールのアーティファクトがパイプラインの出力で検出されました。

無効: CI/CDパイプラインが存在しないか、セキュリティテストツールのアーティファクトがパイプラインの出力で見つかりませんでした。

#### 「セキュリティ設定」ページを表示する {#view-security-configuration-page}

プロジェクトの「セキュリティ設定」を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。

CI/CD設定ファイルへの変更の履歴を表示するには、「**設定履歴**」を選択します。

#### プロジェクトの「セキュリティ設定」を編集する {#edit-a-projects-security-configuration}

プロジェクトの「セキュリティ設定」を編集するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. 有効にする、または設定するセキュリティスキャナーを選択し、指示に従ってください。

個々のセキュリティスキャナーを有効にして設定する方法の詳細については、それらのドキュメントを参照してください。

## 共有設定を作成する {#create-a-shared-configuration}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

同じセキュリティスキャン設定を複数のプロジェクトに適用するには、次のいずれかの方法を使用します:

- [スキャン実行ポリシー](../policies/scan_execution_policies.md)
- [パイプライン実行ポリシー](../policies/pipeline_execution_policies.md)

これらの各方法により、セキュリティスキャンを含むCI/CD設定を一度定義し、複数のプロジェクトやグループに適用することができます。これらの方法は、各プロジェクトを個別に設定する場合に比べて、いくつかの利点があります:

- 設定の変更は、各プロジェクトに対してではなく、1回行うだけで済みます。
- 設定変更を行う権限が制限され、職務分離が提供されます。

## セキュリティスキャンをカスタマイズする {#customize-security-scanning}

要件と環境に合わせてセキュリティスキャンをカスタマイズできます。個々のセキュリティスキャナーをカスタマイズする方法の詳細については、それらのドキュメントを参照してください。

### ベストプラクティス {#best-practices}

セキュリティスキャン設定をカスタマイズする際には、次の点に注意してください:

- デフォルトブランチへの変更をマージする前に、マージリクエストを使用してセキュリティスキャンツールのすべてのカスタマイズをテストしてください。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。
- スキャンツールのCI/CDテンプレートを[含めます](../../../ci/yaml/_index.md#include)。テンプレートの内容をコピーしないでください。
- 必要な場合にのみテンプレートの値をオーバーライドしてください。他のすべての値はテンプレートから継承されます。
- 本番環境ワークフローには、各テンプレートの安定版エディションを使用してください。安定版エディションの変更頻度は少なく、破壊的な変更はGitLabのメジャーバージョン間でのみ行われます。最新バージョンには最も新しい変更が含まれていますが、マイナーなGitLabバージョン間で大きな変更がある場合があります。

### テンプレートエディション {#template-editions}

GitLabアプリケーションセキュリティツールには、最大2つのテンプレートエディションがあります:

- **安定版**: 安定版テンプレートはデフォルトです。これは信頼性が高く一貫したアプリケーションセキュリティエクスペリエンスを提供します。CI/CDパイプラインで安定性と予測可能な動作を必要とするほとんどのユーザーおよびプロジェクトでは、安定版テンプレートを使用する必要があります。
- **Latest**: 最新テンプレートは、最先端の機能にアクセスしてテストしたい方向けです。テンプレート名にある単語`latest`で識別されます。安定版とは見なされておらず、次のメジャーリリースで計画されている破壊的な変更が含まれている可能性があります。このテンプレートを使用すると、安定版リリースの一部となる前に、新機能やアップデートを試すことができます。

> [!note]
> 同じプロジェクト内でセキュリティテンプレートを混在させないでください。異なるセキュリティテンプレートエディションを混在させると、マージリクエストパイプラインとブランチパイプラインの両方が実行される可能性があります。

### デフォルトレジストリベースアドレスをオーバーライドする {#override-the-default-registry-base-address}

デフォルトでは、GitLabセキュリティスキャナーは`registry.gitlab.com/security-products`をDockerイメージのベースアドレスとして使用します。ほとんどのスキャナーでこれをオーバーライドするには、CI/CD変数`SECURE_ANALYZERS_PREFIX`を別の場所に設定します。これはすべてのスキャナーに一度に影響します。

[コンテナスキャン](../container_scanning/_index.md)アナライザーは例外であり、`SECURE_ANALYZERS_PREFIX`という変数は使用しません。そのDockerイメージをオーバーライドするには、[オフライン環境でコンテナスキャンを実行する](../container_scanning/_index.md#offline-environment)の手順を参照してください。

### マージリクエストパイプラインでセキュリティスキャンツールを使用する {#use-security-scanning-tools-with-merge-request-pipelines}

デフォルトでは、アプリケーションセキュリティジョブはブランチパイプラインに対してのみ実行されるように設定されています。[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)で使用するには、次のいずれかの方法を使用します:

- CI/CD変数`AST_ENABLE_MR_PIPELINES`を`"true"`に設定します（[18.0で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/410880)）（推奨）
- マージリクエストパイプラインをデフォルトで有効にする[`latest`エディションテンプレート](#template-editions)を使用します。

たとえば、SASTと依存関係スキャンの両方をマージリクエストパイプラインで有効にして実行するには、次の設定を使用します:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  AST_ENABLE_MR_PIPELINES: "true"
```

### カスタムスキャンパイプラインステージを使用する {#use-a-custom-scanning-stage}

セキュリティスキャナーテンプレートは、デフォルトで事前定義された`test`パイプラインステージを使用します。代わりに別のステージで実行させるには、カスタムステージの名前を`.gitlab-ci.yml`ファイルの`stages:`セクションに追加します。

セキュリティジョブをオーバーライドする方法の詳細については、以下を参照してください:

- [SASTジョブをオーバーライド](../sast/_index.md#override-sast-jobs)。
- [依存関係スキャンジョブのオーバーライド](../dependency_scanning/_index.md#overriding-dependency-scanning-jobs)。
- [コンテナスキャンジョブのオーバーライド](../container_scanning/_index.md#overriding-the-container-scanning-template)。
- [シークレット検出ジョブのオーバーライド](../secret_detection/pipeline/configure.md)。
- [DASTジョブのオーバーライド](../dast/browser/_index.md)。

## トラブルシューティング {#troubleshooting}

セキュリティスキャンを設定する際に、以下の問題が発生する可能性があります。

### エラー: `chosen stage test does not exist` {#error-chosen-stage-test-does-not-exist}

パイプラインの実行中に、`chosen stage test does not exist`というエラーが表示されることがあります。

この問題は、セキュリティスキャンジョブで使用されるパイプラインステージが`.gitlab-ci.yml`ファイルで宣言されていない場合に発生します。

これを解決するには、次のいずれかの方法を使用します:

- `.gitlab-ci.yml`に`test`パイプラインステージを追加します:

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

- 各セキュリティジョブのデフォルトパイプラインステージをオーバーライドします。たとえば、`unit-tests`という名前の事前定義されたパイプラインステージを使用するには:

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
