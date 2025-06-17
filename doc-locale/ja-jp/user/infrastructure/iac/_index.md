---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenTofu と GitLab を使用した Infrastructure as Code
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab でインフラストラクチャを管理するには、OpenTofu とのインテグレーションを使用して、バージョン管理、再利用、共有が可能なリソースを定義できます:

- コンピューティング、ストレージ、ネットワーキングリソースなどの低レベルのコンポーネントを管理します。
- DNS エントリや SaaS の機能などの高レベルのコンポーネントを管理します。
- GitLab を OpenTofu の状態ストレージとして使用します。
- OpenTofu モジュールを保存して使用し、一般的で複雑なインフラストラクチャパターンを簡素化します。
- GitOps デプロイと Infrastructure as Code（IaC）のワークフローを組み込みます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> OpenTofu とのインテグレーションで GitLab が提供する機能の[ビデオの概要](https://www.youtube.com/watch?v=iGXjUrkkzDI)をご覧ください。

以下の例では、主に OpenTofu を使用していますが、Terraform でも動作します。

## Terraform と OpenTofu のサポート

GitLab は、Terraform と OpenTofu の両方と統合できます。ほとんどの機能は完全に互換性があり、以下が含まれます。

- [GitLab 管理の Terraform/OpenTofu 状態](terraform_state.md)
- [マージリクエストでの Terraform/OpenTofu インテグレーション](mr_integration.md)
- [Terraform/OpenTofu モジュールレジストリ](../../packages/terraform_module_registry/_index.md)

簡略化のため、GitLabドキュメントでは主に OpenTofu について説明します。ただし、Terraform と OpenTofu の インテグレーションの違いについては、ドキュメントに記載されています。

## パイプラインで OpenTofu プロジェクトをクイックスタート

OpenTofu は、GitLab OpenTofu CI/CD コンポーネントを使用して、Terraform 固有のすべての GitLab 機能と統合できます。

コンポーネントを含めることで、*検証*、*プラン*、*適用*ワークフローをパイプラインに追加できます:

```yaml
include:
  - component: gitlab.com/components/opentofu/validate-plan-apply@<VERSION>
    inputs:
      version: <VERSION>
      opentofu_version: <OPENTOFU_VERSION>
      root_dir: terraform/
      state_name: production

stages: [validate, build, deploy]
```

テンプレート、インプット、および OpenTofu CI/CD コンポーネントの使用方法の詳細については、[OpenTofu CI/CD コンポーネントの README](https://gitlab.com/components/opentofu)を参照してください。

## パイプラインで Terraform プロジェクトをクイックスタート

{{< alert type="warning" >}}

Terraform CI/CD テンプレートは非推奨となり、GitLab 18.0 で削除されます。詳細情報については、[非推奨のお知らせ](../../../update/deprecations.md#deprecate-terraform-cicd-templates)を参照してください。

{{< /alert >}}

GitLab と Terraform のインテグレーションは、GitLab CI/CD を通じて行われます。`include`属性を使用して Terraform テンプレートをプロジェクトに追加し、そこからカスタマイズします。

まず、ニーズに最適なテンプレートを選択します。

- [最新テンプレート](#latest-terraform-template-deprecated)
- [安定版テンプレートと高度なテンプレート](#stable-and-advanced-terraform-templates-deprecated)

すべてのテンプレート:

- [GitLab 管理の Terraform 状態](terraform_state.md)を Terraform 状態ストレージバックエンドとして使用します。
- 4 つのパイプラインステージ（`test`、`validate`、`build`、`deploy`）をトリガーします。
- Terraform コマンド（`test`、`validate`、`plan`、`plan-json`）を実行します。また、デフォルトブランチでのみ`apply`を実行します。
- [IaC スキャン](../../application_security/iac_scanning/_index.md)を使用してセキュリティの問題を確認します。

### 最新の Terraform テンプレート (非推奨)

[最新テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml)は、最新の GitLab バージョンと互換性があります。最新の GitLab 機能を提供しますが、破壊的な変更が含まれる可能性があります。

最新の Terraform テンプレートは安全に使用できます。

- GitLab.com を使用する場合。
- 新しい GitLab リリースごとに更新された GitLab Self-Managedインスタンスを使用する場合。

### 安定版および高度な Terraform テンプレート (非推奨)

以前のバージョンの GitLab を使用している場合は、GitLab のバージョンとテンプレートのバージョン間に互換性のないエラーが発生する可能性があります。この場合、次のいずれかのテンプレートを使用できます:

- 上に構築できるスケルトンを備えた[安定版テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml)。
- セットアップを完全にカスタマイズするための[高度なテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml)。

{{< alert type="note" >}}

各 GitLab メジャーリリース (例: 15.0) では、最新のテンプレートが古いテンプレートに置き換わります。このプロセスにより、破壊的な変更が発生する可能性があります。必要に応じて、[テンプレートの古いバージョンを使用](troubleshooting.md#use-an-older-version-of-the-template)できます。

{{< /alert >}}

### Terraform テンプレートの使用 (非推奨)

Terraform テンプレートを使用するには:

1. 左側のサイドバーで、**検索または移動**を選択し、Terraform と統合するプロジェクトを見つけます。
1. **コード > リポジトリ**を選択します。
1. `.gitlab-ci.yml`ファイルを編集し、`include`属性を使用して Terraform テンプレートをフェッチします:

   ```yaml
   include:
    # To fetch the latest template, use:
     - template: Terraform.latest.gitlab-ci.yml
    # To fetch the advanced latest template, use:
     - template: Terraform/Base.latest.gitlab-ci.yml
    # To fetch the stable template, use:
     - template: Terraform.gitlab-ci.yml
    # To fetch the advanced stable template, use:
     - template: Terraform/Base.gitlab-ci.yml
   ```

1. 以下に示すように、変数を追加します。

   ```yaml
   variables:
     TF_STATE_NAME: default
     # If your terraform files are in a subdirectory, set TF_ROOT accordingly. For example:
     # TF_ROOT: terraform/production
   ```

1. 任意。`.gitlab-ci.yml`ファイルで、フェッチしたテンプレートに存在する属性を上書きして、設定をカスタマイズします。

### 独自の Terraform CI/CD テンプレートをビルドしてホストする

GitLab は Terraform CI/CD テンプレートと`terraform-images` (基盤となるジョブイメージ、`terraform` を含む) を配布しなくなりましたが、GitLab パイプラインで Terraform を引き続き使用できます。

独自のテンプレートとイメージをビルドしてホストする方法については、[Terraform Images](https://gitlab.com/gitlab-org/terraform-images) プロジェクトを参照してください。

### Terraform テンプレートレシピ

GitLab でキュレートされたテンプレートレシピについては、[Terraform テンプレートレシピ](terraform_template_recipes.md)を参照してください。

## 関連トピック

- GitLab を[Terraform/OpenTofu モジュールレジストリ](../../packages/terraform_module_registry/_index.md)として使用します。
- ローカルストレージまたは remote ストアにステートファイルを保存するには、[GitLab 管理の Terraform/OpenTofu ステート](terraform_state.md)を使用します。
- Terraform コードの変更と IaC ワークフローで共同作業を行うには、[マージリクエストでの Terraform インテグレーション](mr_integration.md)を使用します。
- ユーザー、グループ、プロジェクトなどの GitLab リソースを管理するには、[GitLabTerraform プロバイダー](https://gitlab.com/gitlab-org/terraform-provider-gitlab)を使用します。GitLabTerraform プロバイダーのドキュメントは、[Terraform ドキュメントサイト](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs)で入手できます。
- [Amazon Elastic Kubernetes Service（EKS）で新しいクラスターを作成](../clusters/connect/new_eks_cluster.md)します。
- [Google Kubernetes Engine（GKE）で新しいクラスターを作成](../clusters/connect/new_gke_cluster.md)します。
- GitLab と Terraform の[トラブルシューティング](troubleshooting.md)を行います。
- `gitlab-terraform` Shell スクリプトを含む[イメージを表示](https://gitlab.com/gitlab-org/terraform-images)します。
