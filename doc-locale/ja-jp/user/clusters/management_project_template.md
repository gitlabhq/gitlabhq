---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: クラスターアプリケーションを管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、プロジェクト作成に使用するクラスター管理プロジェクトテンプレートを提供しています。このプロジェクトには、GitLabと統合し、GitLabの機能を拡張するクラスターアプリケーションが含まれています。プロジェクトに示されているパターンを使用して、カスタムクラスターアプリケーションを拡張できます。

> [!note]
>
> プロジェクトテンプレートは、変更なしでGitLab.comで機能します。Self-ManagedインスタンスのGitLabをご利用の場合、`.gitlab-ci.yml`ファイルを変更する必要があります。

## エージェントとマニフェストに1つのプロジェクトを使用する {#use-one-project-for-the-agent-and-your-manifests}

エージェントを使用してクラスターをGitLabに接続**したことがない**場合:

1. [クラスター管理プロジェクトテンプレートからプロジェクトを作成](#create-a-project-based-on-the-cluster-management-project-template)します。
1. [エージェント用にプロジェクトを構成](agent/install/_index.md)します。
1. プロジェクトの設定で、[環境変数](../../ci/variables/_index.md#for-a-project)という名前の`$KUBE_CONTEXT`を作成し、値を`path/to/agent-configuration-project:your-agent-name`に設定します。
1. 必要に応じて[ファイルを構成](#configure-the-project)します。

## エージェントとマニフェストに個別のプロジェクトを使用する {#use-separate-projects-for-the-agent-and-your-manifests}

すでにエージェントを構成し、クラスターをGitLabに接続している場合:

1. [クラスター管理プロジェクトテンプレートからプロジェクトを作成](#create-a-project-based-on-the-cluster-management-project-template)します。
1. エージェントを構成したプロジェクトで、[新規プロジェクトへのエージェントアクセスを許可](agent/ci_cd_workflow.md#authorize-agent-access)します。
1. 新しいプロジェクトで、[環境変数](../../ci/variables/_index.md#for-a-project)という名前の`$KUBE_CONTEXT`を作成し、値を`path/to/agent-configuration-project:your-agent-name`に設定します。
1. 新しいプロジェクトで、必要に応じて[ファイルを構成](#configure-the-project)します。

## クラスター管理プロジェクトテンプレートに基づいてプロジェクトを作成する {#create-a-project-based-on-the-cluster-management-project-template}

クラスター管理プロジェクトテンプレートからプロジェクトを作成するには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. テンプレートのリストから、**GitLabクラスターの管理**の横にある**テンプレートを使用**を選択します。
1. プロジェクトの詳細を入力します。
1. **プロジェクトを作成**を選択します。
1. 新しいプロジェクトで、必要に応じて[ファイルを構成](#configure-the-project)します。

## プロジェクトを設定する {#configure-the-project}

クラスター管理テンプレートを使用してプロジェクトを作成した後、以下を構成できます:

- [`.gitlab-ci.yml`ファイル](#the-gitlab-ciyml-file)。
- [メインの`helmfile.yml`ファイル](#the-main-helmfileyml-file)。
- [組み込みアプリケーションを含むディレクトリ](#built-in-applications)。

### `.gitlab-ci.yml`ファイル {#the-gitlab-ciyml-file}

`.gitlab-ci.yml`ファイル:

- Helmバージョン3を使用していることを確認します。
- プロジェクトから有効化されたアプリケーションをデプロイします。

パイプライン定義を編集および拡張できます。

パイプラインで使用されるベースイメージは、[cluster-applications](https://gitlab.com/gitlab-org/cluster-integration/cluster-applications)プロジェクトによって構築されます。このイメージには、[Helm v3リリース](https://helm.sh/docs/intro/using_helm/#three-big-concepts)をサポートするためのBashユーティリティスクリプトのセットが含まれています。

Self-ManagedインスタンスのGitLabをご利用の場合、`.gitlab-ci.yml`ファイルを変更する必要があります。特に、コメント`Automatic package upgrades`で始まるセクションは、`include`がGitLab.comプロジェクトを参照しているため、Self-ManagedインスタンスのGitLabでは機能しません。このコメントの下にあるすべてを削除すると、パイプラインは成功します。

### メインの`helmfile.yml`ファイル {#the-main-helmfileyml-file}

テンプレートには、[Helmfile](https://github.com/helmfile/helmfile)が含まれており、これを使用して[Helm v3](https://helm.sh/)でクラスターアプリケーションを管理できます。

このファイルには、各アプリの他のHelmファイルへのパスのリストが含まれています。それらはすべてデフォルトでコメントアウトされているため、クラスターで使用したいアプリのパスのコメントを解除する必要があります。

これらサブパス内の各`helmfile.yaml`には、属性`installed: true`がデフォルトで設定されています。これは、クラスターおよびHelmリリースの状態に応じて、パイプラインが実行されるたびにHelmfileがアプリをインストールまたは更新しようとすることを意味します。この属性を`installed: false`に変更すると、Helmfileはこのアプリをクラスターからアンインストールしようとします。[Helmfile](https://helmfile.readthedocs.io/en/latest/)の動作について読み取ります。

### 組み込みアプリケーション {#built-in-applications}

テンプレートには、テンプレート内の各アプリケーション用に構成された`helmfile.yaml`を含む`applications`ディレクトリが含まれています。

[組み込みでサポートされているアプリケーション](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/master/applications)は以下のとおりです:

- [Cert-manager](../infrastructure/clusters/manage/management_project_applications/certmanager.md)
- [GitLab Runner](../infrastructure/clusters/manage/management_project_applications/runner.md)
- [Ingress](../infrastructure/clusters/manage/management_project_applications/ingress.md)
- [Vault](../infrastructure/clusters/manage/management_project_applications/vault.md)

各アプリケーションには`applications/{app}/values.yaml`ファイルがあります。GitLab Runnerの場合、ファイルは`applications/{app}/values.yaml.gotmpl`です。

このファイルでは、アプリのHelmチャートのデフォルト値を定義できます。一部のアプリにはすでにデフォルトが定義されています。
