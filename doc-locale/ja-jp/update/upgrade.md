---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインスタンスをアップグレードする
description: すべてのインストール方法に関するアップグレードの手順。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

新しい機能とバグの修正を利用するために、GitLabインスタンスをアップグレードします。

アップグレードする前に、[アップグレード前に必要な情報](plan_your_upgrade.md)を確認してください。

## GitLabをアップグレードする {#upgrade-gitlab}

GitLabをアップグレードするには:

1. 開始バージョンで利用可能な場合は、アップグレード中に[メンテナンスモードを有効にする](../administration/maintenance_mode/_index.md)ことを検討してください。
1. [実行中のCI/CDパイプラインとジョブ](#cicd-pipelines-and-jobs-during-upgrades)を一時停止します。
1. [インストール方法に応じたアップグレード手順](#upgrade-based-on-installation-method)に従います。
1. GitLabインスタンスにRunnerが関連付けられている場合は、現在のGitLabバージョンに合わせてアップグレードします。この手順により、[GitLabバージョンとの互換性](https://docs.gitlab.com/runner/#gitlab-runner-versions)が確保されます。
1. メンテナンスモードを有効にしていた場合は、[メンテナンスモードを無効にします](../administration/maintenance_mode/_index.md#disable-maintenance-mode)。
1. [実行中のCI/CDパイプラインとジョブ](#cicd-pipelines-and-jobs-during-upgrades)の一時停止を解除します。
1. [アップグレードヘルスチェック](plan_your_upgrade.md#run-upgrade-health-checks)を実行します。

## インストール方法に応じてアップグレードする {#upgrade-based-on-installation-method}

GitLabのアップグレード方法は、インストール方法とGitLabのバージョンに応じて、複数の公式な方法から選択できます:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

GitLabのアップグレードの一環として、[Linuxパッケージのアップグレードガイド](package/_index.md)には、Linuxパッケージインスタンスをアップグレードするための特定の手順が含まれています。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

GitLabは、Helmを使用してKubernetesクラスターにデプロイできます。本番環境へのデプロイの場合、構成は、[クラウドネイティブハイブリッド](../administration/reference_architectures/_index.md#cloud-native-hybrid)ガイドに従います。この方式では、クラウドネイティブなGitLabのステートレスコンポーネントはGitLab Helmチャートを使用してKubernetesで実行され、ステートフルコンポーネントはLinuxパッケージを使用してコンピューティング仮想マシン（VM）にデプロイされます。

チャートバージョンからGitLabバージョンへの[バージョンマッピング](https://docs.gitlab.com/charts/installation/version_mappings.html)を使用して、[アップグレードパス](upgrade_paths.md)を決定します。

[ダウンタイムを伴うマルチノードアップグレード](with_downtime.md)の手順に従って、クラウドネイティブハイブリッドセットアップでアップグレードを実行します。

完全なクラウドネイティブ方式のデプロイは、本番環境では[サポートされていません](../administration/reference_architectures/_index.md#stateful-components-in-kubernetes)。ただし、そのような環境をアップグレードする方法の手順は、[別のドキュメント](https://docs.gitlab.com/charts/installation/upgrade.html)に記載されています。

{{< /tab >}}

{{< tab title="Docker" >}}

GitLabは、GitLab Community EditionとGitLab Enterprise Editionの両方に対して公式のDockerイメージを提供しており、それらはLinuxパッケージをベースにしています。[Docker](../install/docker/_index.md)を使用したGitLabのインストール方法を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

- [ソースからCommunity EditionとEnterprise Editionをアップグレードする](upgrading_from_source.md): ソースからCommunity EditionとEnterprise Editionをアップグレードするためのガイドライン。
- [パッチバージョン](patch_versions.md)ガイドには、15.2.0から15.2.1などのパッチバージョンに必要な手順が含まれており、GitLab Community EditionとGitLab Enterprise Editionの両方に適用されます。

以前は、アップグレード手順に個別のドキュメントを使用していましたが、単一のドキュメントを使用するように切り替えました。以前のアップグレードガイドラインは、Gitリポジトリで引き続き参照できます:

- [GitLab Community Editionの旧アップグレードガイドライン](https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update)
- [GitLab Enterprise Editionの旧アップグレードガイドライン](https://gitlab.com/gitlab-org/gitlab/-/tree/11-8-stable-ee/doc/update)

{{< /tab >}}

{{< /tabs >}}

## アップグレード中のCI/CDパイプラインとジョブ {#cicd-pipelines-and-jobs-during-upgrades}

GitLab Runnerがジョブを処理している間にGitLabインスタンスをアップグレードすると、トレース更新が失敗します。GitLabがオンラインに戻ると、トレース更新は自動修復されるはずです。ただし、エラーによっては、GitLab Runnerは再試行するか、最終的にジョブの処理を終了します。

アーティファクトについては、GitLab Runnerはアップロードを3回試み、その後ジョブは最終的に失敗します。

上記の2つのシナリオに対処するには、アップグレード前に次の手順を行うことをおすすめします:

1. メンテナンスを計画します。
1. Runnerを一時停止するか、`/etc/gitlab/gitlab.rb`に次を追加して新しいジョブの開始をブロックします:

   ```ruby
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

   以下を使用してGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. すべてのジョブが完了するまで待ちます。
1. GitLabをアップグレードします。
1. GitLabバージョンと同じバージョンに[GitLab Runner](https://docs.gitlab.com/runner/install/)をアップグレードします。両方のバージョンは[同じである必要があります](https://docs.gitlab.com/runner/#gitlab-runner-versions)。
1. Runnerの一時停止を解除し、先ほどの`/etc/gitlab/gitlab.rb`の変更を元にリバートして、新しいジョブの開始ブロックを解除します。

## エディション間でアップグレードする {#upgrading-between-editions}

GitLabには次の2つのエディションがあります: MITライセンスのGitLab [Community Edition](https://about.gitlab.com/features/#community)と、GitLab Community EditionをベースにビルドされたGitLab [Enterprise Edition](https://about.gitlab.com/features/#enterprise)です。GitLab Enterprise Editionは、主に100人以上のユーザーがいる組織を対象とした追加機能を含みます。

次のセクションでは、GitLab Editionを変更するのに役立ついくつかのガイドを紹介します。

## サポートを利用する {#getting-support}

問題が発生した場合:

- エラーをコピーし、後で分析するためにログを収集し、最後に動作していたバージョンに[ロールバック](plan_your_upgrade.md#rollback-plan)します。データの収集には次のツールが役立ちます:
  - [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos): LinuxパッケージまたはDockerを使用してGitLabをインストールした場合。
  - [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/): Helm Chartを使用してGitLabをインストールした場合。

サポート:

- [GitLabサポートにお問い合わせください](https://support.gitlab.com/hc/en-us)。担当のカスタマーサクセスマネージャーがいる場合は、そちらにもお問い合わせください。
- [問題の状態が対象となる](https://about.gitlab.com/support/#definitions-of-support-impact) 、かつ[プランに緊急サポートが含まれている](https://about.gitlab.com/support/#priority-support)場合は、緊急チケットを作成してください。

## 関連トピック {#related-topics}

- [PostgreSQL拡張機能を管理する](../install/postgresql_extensions.md)
