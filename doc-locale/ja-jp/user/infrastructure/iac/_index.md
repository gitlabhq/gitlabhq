---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenTofuとGitLabを使用したInfrastructure as Code
description: インフラストラクチャの管理、バージョニング、自動化、状態ストレージ、モジュール。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでインフラストラクチャを管理するには、OpenTofuとのインテグレーションを使用して、バージョン管理、再利用、共有が可能なリソースを定義できます:

- コンピューティング、ストレージ、ネットワーキングリソースなどの低レベルのコンポーネントを管理します。
- DNSエントリやSaaSの機能などの高レベルのコンポーネントを管理します。
- GitLabをOpenTofuステートストレージとして使用します。
- OpenTofuモジュールを保存して使用し、一般的かつ複雑なインフラストラクチャパターンを簡素化します。
- GitOpsデプロイとInfrastructure as Code（IaC）のワークフローを組み込みます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> GitLabがOpenTofuとのインテグレーションで提供する機能の[動画の概要](https://www.youtube.com/watch?v=iGXjUrkkzDI)をご覧ください。

以下の例では、主にOpenTofuを使用していますが、Terraformでも動作します。

## TerraformとOpenTofuのサポート {#terraform-and-opentofu-support}

GitLabは、TerraformとOpenTofuの両方と統合できます。ほとんどの機能は完全に互換性があり、以下が含まれます:

- [GitLab管理のTerraform/OpenTofuステート](terraform_state.md)
- [マージリクエストでのTerraform/OpenTofuインテグレーション](mr_integration.md)
- [Terraform/OpenTofuモジュールレジストリ](../../packages/terraform_module_registry/_index.md)

簡略化のため、GitLabドキュメントでは主にOpenTofuについて説明します。ただし、TerraformとOpenTofuのインテグレーションの違いについては、ドキュメントに記載されています。

## パイプラインでOpenTofuプロジェクトをクイックスタート {#quickstart-an-opentofu-project-in-pipelines}

OpenTofuは、GitLab OpenTofu CI/CDコンポーネントを使用して、Terraform固有のすべてのGitLab機能と統合できます。

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

テンプレート、インプット、およびOpenTofu CI/CDコンポーネントの使用方法の詳細については、[OpenTofu CI/CDコンポーネントのREADME](https://gitlab.com/components/opentofu)を参照してください。

## 独自のTerraform CI/CDテンプレートをビルドしてホストする {#build-and-host-your-own-terraform-cicd-templates}

GitLabはTerraform CI/CDテンプレートと`terraform-images`（`terraform`など、基盤となるジョブイメージ）を配布しなくなりましたが、GitLabパイプラインでTerraformを引き続き使用できます。

独自のテンプレートとイメージをビルドしてホストする方法については、[Terraform Images](https://gitlab.com/gitlab-org/terraform-images)プロジェクトを参照してください。

## 関連トピック {#related-topics}

- GitLabを[Terraform/OpenTofuモジュールレジストリ](../../packages/terraform_module_registry/_index.md)として使用します。
- ローカルストレージまたはリモートストアにステートファイルを保存するには、[GitLab管理のTerraform/OpenTofuステート](terraform_state.md)を使用します。
- Terraformコードの変更とIaCワークフローで共同作業を行うには、[マージリクエストでのTerraformインテグレーション](mr_integration.md)を使用します。
- ユーザー、グループ、プロジェクトなどのGitLabリソースを管理するには、[GitLab Terraformプロバイダー](https://gitlab.com/gitlab-org/terraform-provider-gitlab)を使用します。GitLab Terraformプロバイダーのドキュメントは、[Terraformドキュメントサイト](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs)で入手できます。
- [Amazon Elastic Kubernetes Service（EKS）で新しいクラスターを作成](../clusters/connect/new_eks_cluster.md)します。
- [Google Kubernetes Engine（GKE）で新しいクラスターを作成](../clusters/connect/new_gke_cluster.md)します。
- GitLabとTerraformの問題を[トラブルシューティング](troubleshooting.md)します。
- [`gitlab-terraform`Shellスクリプトを含むイメージを表示](https://gitlab.com/gitlab-org/terraform-images)します。
