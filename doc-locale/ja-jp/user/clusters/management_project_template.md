---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスターアプリケーションを管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、プロジェクトの作成に使用するクラスター管理プロジェクトテンプレートを提供します。このプロジェクトには、GitLabと統合し、GitLabの機能を拡張するクラスターアプリケーションが含まれています。プロジェクトに示されているパターンを使用して、カスタムクラスターアプリケーションを拡張できます。

{{< alert type="note" >}}

プロジェクトテンプレートは、変更なしでGitLab.comで動作します。GitLab Self-Managedインスタンスを使用している場合は、`.gitlab-ci.yml`ファイルを変更する必要があります。

{{< /alert >}}

## エージェントとマニフェストに1つのプロジェクトを使用する {#use-one-project-for-the-agent-and-your-manifests}

**have not yet**（まだ）エージェントを使用してGitLabとクラスターを接続していない場合:

1. [クラスタ管理プロジェクトテンプレートからプロジェクトを作成](#create-a-project-based-on-the-cluster-management-project-template)。
1. [エージェントのプロジェクトを設定](agent/install/_index.md)。
1. プロジェクトの設定で、[環境変数](../../ci/variables/_index.md#for-a-project) `$KUBE_CONTEXT`を作成し、値を`path/to/agent-configuration-project:your-agent-name`に設定します。
1. 必要に応じて[ファイルを構成](#configure-the-project)します。

## エージェントとマニフェストに個別のプロジェクトを使用する {#use-separate-projects-for-the-agent-and-your-manifests}

エージェントをすでに設定し、クラスターをGitLabに接続している場合:

1. [クラスタ管理プロジェクトテンプレートからプロジェクトを作成](#create-a-project-based-on-the-cluster-management-project-template)。
1. エージェントを設定したプロジェクトで、[新しいプロジェクトへのエージェントアクセスを許可](agent/ci_cd_workflow.md#authorize-agent-access)します。
1. 新しいプロジェクトで、[環境変数](../../ci/variables/_index.md#for-a-project) `$KUBE_CONTEXT`を作成し、値を`path/to/agent-configuration-project:your-agent-name`に設定します。
1. 新しいプロジェクトで、必要に応じて[ファイルを構成](#configure-the-project)します。

## クラスター管理プロジェクトテンプレートに基づいてプロジェクトを作成する {#create-a-project-based-on-the-cluster-management-project-template}

クラスター管理プロジェクトテンプレートからプロジェクトを作成するには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。[新しいナビゲーションをオンにしている](../interface_redesign.md#turn-new-navigation-on-or-off)場合、このボタンは右上隅にあります。
1. **テンプレートから作成**を選択します。
1. テンプレートのリストから、**GitLabクラスターの管理**の横にある**テンプレートを使用**を選択します。
1. プロジェクトの詳細を入力してください。
1. **プロジェクトを作成**を選択します。
1. 新しいプロジェクトで、必要に応じて[ファイルを構成](#configure-the-project)します。

## プロジェクトを設定する {#configure-the-project}

クラスター管理テンプレートを使用してプロジェクトを作成した後、以下を設定できます:

- [The `.gitlab-ci.yml`ファイル](#the-gitlab-ciyml-file)。
- [メイン`helmfile.yml`ファイル](#the-main-helmfileyml-file)。
- [組み込みアプリケーションを含むディレクトリ](#built-in-applications)。

### `.gitlab-ci.yml`ファイル {#the-gitlab-ciyml-file}

`.gitlab-ci.yml`ファイル:

- Helmバージョン3を使用していることを確認します。
- プロジェクトから有効になっているアプリケーションをデプロイします。

パイプライン定義を編集および拡張できます。

パイプラインで使用されるベースイメージは、[cluster-applications](https://gitlab.com/gitlab-org/cluster-integration/cluster-applications)プロジェクトによってビルドされます。このイメージには、[Helm v3リリース](https://helm.sh/docs/intro/using_helm/#three-big-concepts)をサポートするためのBashユーティリティスクリプトのセットが含まれています。

GitLab Self-Managedインスタンスを使用している場合は、`.gitlab-ci.yml`ファイルを変更する必要があります。具体的には、`Automatic package upgrades`というコメントで始まるセクションは、GitLab Self-Managedインスタンスでは機能しません。`include`はGitLab.comプロジェクトを参照しているためです。このコメントより下のすべてを削除すると、パイプラインは成功します。

### メイン`helmfile.yml`ファイル {#the-main-helmfileyml-file}

このテンプレートには、[Helmfile](https://github.com/helmfile/helmfile)が含まれており、[Helm v3](https://helm.sh/)でクラスターアプリケーションを管理するために使用できます。

このファイルには、各アプリケーションの他のHelmファイルへのパスのリストがあります。これらはすべてデフォルトでコメントアウトされているため、クラスターで使用するアプリケーションのパスをコメント解除する必要があります。

デフォルトでは、これらのサブパスの各`helmfile.yaml`には、属性`installed: true`があります。つまり、クラスターとHelmリリースの状態に応じて、Helmfileはパイプラインが実行されるたびにアプリケーションをインストールまたは更新しようとします。この属性を`installed: false`に変更すると、Helmfileはこのアプリケーションをクラスターからアンインストールしようとします。Helmfileの動作方法については、[こちらをご覧ください](https://helmfile.readthedocs.io/en/latest/)。

### 組み込みアプリケーション {#built-in-applications}

このテンプレートには、`applications`ディレクトリがあり、`helmfile.yaml`がテンプレート内の各アプリケーション用に構成されています。

[組み込みのサポート対象アプリケーション](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/master/applications)は次のとおりです:

- [証明書マネージャー](../infrastructure/clusters/manage/management_project_applications/certmanager.md)
- [GitLab Runner](../infrastructure/clusters/manage/management_project_applications/runner.md)
- [Ingress](../infrastructure/clusters/manage/management_project_applications/ingress.md)
- [Vault](../infrastructure/clusters/manage/management_project_applications/vault.md)

各アプリケーションには、`applications/{app}/values.yaml`ファイルがあります。GitLab Runnerの場合、ファイルは`applications/{app}/values.yaml.gotmpl`です。

このファイルでは、アプリのHelmチャートのデフォルト値を定義できます。一部のアプリには、デフォルトがすでに定義されています。
