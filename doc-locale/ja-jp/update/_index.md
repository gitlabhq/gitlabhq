---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Latest version instructions.
title: GitLabをアップグレードする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

GitLabのアップグレードは比較的簡単なプロセスですが、次の要素により複雑になる可能性があります。

- 使用したインストール方法。
- 使用しているGitLabのバージョン。
- メジャーバージョンにアップグレードする場合。

可能であれば、本番環境のインスタンスを更新する前に、テスト環境でアップグレードをテストした方が良いでしょう。テスト環境は、本番環境に可能な限り近いものである必要があります。

このページ全体を読んで、各アップグレード方法に関連する情報を確認してください。

## GitLabをアップグレードする

GitLabをアップグレードするには:

1. アップグレード手順を記録するための[アップグレードプラン](plan_your_upgrade.md)を作成します。
1. [メンテナンスポリシーのドキュメント](../policy/maintenance.md)をよくお読みください。
1. スキップするバージョンの[リリース投稿](https://about.gitlab.com/releases/categories/releases/)をお読みください（特に、非推奨、削除、およびアップグレードに関する重要な注意点について）。
1. 自身に適した[アップグレードパス](upgrade_paths.md)を決定します。アップグレードパスに必須のアップグレード経由地点が含まれている場合は、現在のバージョンから対象のバージョンに移行するために、複数のアップグレードを実行する必要があるかもしれません。当てはまる場合は、[GitLab対象バージョンとのOSの互換性](../administration/package_information/supported_os.md)を確認してください。
1. [バックグラウンド移行](background_migrations.md)を確認します。すべての移行は、各アップグレードの前に完了する必要があります。バックグラウンド移行を完了させるために、メジャーリリースとマイナーリリースの間のアップグレードは間隔をあけて実行してください。
1. 最初にテスト環境でアップグレードをテストし、予定外の停止とダウンタイムのリスクを軽減するための[ロールバックプラン](plan_your_upgrade.md#rollback-plan)を立ててください。
1. 開始バージョンで利用可能な場合は、アップグレード中に[メンテナンスモードをオンにする](../administration/maintenance_mode/_index.md)ことを検討してください。
1. アップグレードする前に、GitLabの異なるバージョンの変更内容を確認して、互換性を確認してください。
   - [GitLab 17の変更点](versions/gitlab_17_changes.md)
   - [GitLab 16の変更点](versions/gitlab_16_changes.md)
   - [GitLab 15の変更点](versions/gitlab_15_changes.md)
1. [アップグレード前のチェック](#pre-upgrade-and-post-upgrade-checks)を実行します。
1. [実行中のCI/CDパイプラインとジョブ](#cicd-pipelines-and-jobs-during-upgrades)を一時停止します。
1. 当てはまる場合は、[追加機能のアップグレード手順](#upgrade-steps-for-additional-features)に従ってください。
   - [高度な検索（Elasticsearch）](#elasticsearch)。
   - [Geo](#geo)。
   - [自身のサーバーで実行しているGitaly](#external-gitaly)。
   - [Kubernetes向けGitLabエージェント](#gitlab-agent-for-kubernetes)。
1. [インストール方法に応じたアップグレード手順](#upgrade-based-on-installation-method)に従ってください。
1. GitLabインスタンスにRunnerが関連付けられている場合は、現在のGitLabバージョンに合わせてアップグレードしてください。この手順により、[GitLabバージョンとの互換性](https://docs.gitlab.com/runner/#gitlab-runner-versions)が確保されます。
1. アップグレードで問題が発生した場合は、[サポートにお問い合わせください](#getting-support)。
1. 有効にした場合は、[メンテナンスモードを無効にします](../administration/maintenance_mode/_index.md#disable-maintenance-mode)。
1. [実行中のCI/CDパイプラインとジョブ](#cicd-pipelines-and-jobs-during-upgrades)の一時停止を解除します。
1. [アップグレード後のチェック](#pre-upgrade-and-post-upgrade-checks)を実行します。

## インストール方法に応じてアップグレードする

インストール方法とGitLabのバージョンに応じて、GitLabをアップグレードするための公式な方法は複数あります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

GitLabのアップグレードの一環として、[Linuxパッケージのアップグレードガイド](package/_index.md)には、Linuxパッケージインスタンスをアップグレードするための特定の手順が含まれています。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

GitLabは、Helmを使用してKubernetesクラスターにデプロイできます。本番環境へのデプロイの場合、構成は、[クラウドネイティブハイブリッド](../administration/reference_architectures/_index.md#cloud-native-hybrid)ガイダンスに従います。クラウドネイティブGitLabのステートレスコンポーネントは、GitLab Helmチャートを使用してKubernetesで実行され、ステートフルコンポーネントは、Linuxパッケージを使用してコンピューティング仮想マシン（VM）にデプロイされます。

チャートバージョンからGitLabバージョンへの[バージョンマッピング](https://docs.gitlab.com/charts/installation/version_mappings.html)を使用して、[アップグレードパス](upgrade_paths.md)を決定します。

[ダウンタイムを伴うマルチノードアップグレード](with_downtime.md)に従って、クラウドネイティブハイブリッドの構成でアップグレードを実行します。

完全なクラウドネイティブのデプロイは、本番環境では[サポートされていません](../administration/reference_architectures/_index.md#stateful-components-in-kubernetes)。ただし、そのような環境をアップグレードする方法の手順は、[別のドキュメント](https://docs.gitlab.com/charts/installation/upgrade.html)に記載されています。

{{< /tab >}}

{{< tab title="Docker" >}}

GitLabは、CommunityエディションとEnterpriseエディションの両方に対して公式のDockerイメージを提供しており、それらはOmnibusパッケージに基づいています。[Dockerを使用したGitLabのインストール](../install/docker/_index.md)方法をご覧ください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

- [ソースからCommunityエディションおよびEnterpriseエディションをアップグレードする](upgrading_from_source.md) \- ソースからCommunityエディションおよびEnterpriseエディションをアップグレードするためのガイドライン。
- [パッチバージョン](patch_versions.md)ガイドには、15.2.0から15.2.1などのパッチバージョンに必要な手順が含まれており、CommunityエディションとEnterpriseエディションの両方に適用されます。

以前は、アップグレード手順に個別のドキュメントを使用していましたが、単一のドキュメントを使用するように切り替えました。以前のアップグレードガイドラインは、Gitリポジトリにあります。

- [Communityエディションの旧アップグレードガイドライン](https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update)
- [Enterpriseエディションの旧アップグレードガイドライン](https://gitlab.com/gitlab-org/gitlab/-/tree/11-8-stable-ee/doc/update)

{{< /tab >}}

{{< /tabs >}}

## アップグレード前およびアップグレード後のチェック

アップグレードの直前・直後に、アップグレード前およびアップグレード後のチェックを実行して、GitLabの主要コンポーネントが機能していることを確認します。

1. [一般的な設定を確認します](../administration/raketasks/maintenance.md#check-gitlab-configuration)。

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. 暗号化されたデータベースの値が[復号化できる](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)ことを確認します。

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. GitLab UIで、以下を確認します。
   - ユーザーがサインインできる。
   - プロジェクトリストが表示される。
   - プロジェクトイシューとマージリクエストにアクセスできる。
   - ユーザーがGitLabからリポジトリをクローンできる。
   - ユーザーがGitLabにコミットをプッシュできる。

1. GitLab CI/CDでは、以下を確認します。
   - Runnerがジョブを選択する。
   - Dockerイメージをレジストリからプッシュおよびプルできる。

1. Geoを使用している場合は、プライマリと各セカンダリで関連するチェックを実行します。

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Elasticsearchを使用している場合は、検索が成功したことを確認します。

問題が発生した場合は、[サポートにお問い合わせください](#getting-support)。

## アップグレード中のCI/CDパイプラインとジョブ

GitLab Runnerがジョブを処理している間にGitLabインスタンスをアップグレードすると、トレースの更新が失敗します。GitLabがオンラインに戻ると、トレースの更新は自己修復されるはずです。ただし、エラーによっては、GitLab Runnerは再試行するか、最終的にジョブの処理を終了します。

GitLab Runnerはアーティファクトのアップロードを3回試み、その後、ジョブは最終的に失敗します。

上記の2つのシナリオに対処するには、アップグレードの前に次のことを行うことをお勧めします。

1. メンテナンスを計画します。
1. `/etc/gitlab/gitlab.rb` に以下を追加して、Runnerを一時停止するか、新しいジョブが開始されないようにします。

   ```ruby
   nginx['custom_gitlab_server_config'] = "location ^~ /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

   以下を使用してGitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. すべてのジョブが完了するまで待ちます。
1. GitLabをアップグレードします。
1. GitLabバージョンと同じバージョンに[GitLab Runnerをアップグレードします](https://docs.gitlab.com/runner/install/)。両方のバージョンは[同じである必要があります](https://docs.gitlab.com/runner/#gitlab-runner-versions)。
1. 以前の`/etc/gitlab/gitlab.rb`の変更を元に戻して、Runnerの一時停止を解除し、新しいジョブを開始できるようにします。

## エディション間でアップグレードする

GitLabには次の2つのエディションがあります。MITライセンスの[Communityエディション](https://about.gitlab.com/features/#community)と、[Enterpriseエディション](https://about.gitlab.com/features/#enterprise)です。Enterpriseエディションは、Communityエディションをベースにビルドされたもので、主に100人以上のユーザーがいる組織を対象とした追加機能を含みます。

以下に、GitLabエディションの変更に役立ついくつかのガイドを示します。

### CommunityエディションからEnterpriseエディションへ

{{< alert type="note" >}}

以下のガイドは、Enterpriseエディションのサブスクライバーのみを対象としています。

{{< /alert >}}

GitLabインストールをCommunityエディションからEnterpriseエディションにアップグレードする場合は、インストール方法に応じたガイドに従ってください。

- [ソースCEからEEへのアップグレードガイド](upgrading_from_ce_to_ee.md) \- 手順はバージョンアップグレードと非常によく似ています。サーバーを停止し、コードを取得し、新しい機能の構成ファイルを更新し、ライブラリをインストールして移行を行い、initスクリプトを更新し、アプリケーションを起動してステータスを確認します。
- [LinuxパッケージCEからEEへ](package/convert_to_ee.md) \- このガイドに従って、LinuxパッケージGitLab CommunityエディションをEnterpriseエディションにアップグレードします。
- [Docker CEからEEへ](../install/docker/upgrade.md#convert-community-edition-to-enterprise-edition) \- このガイドに従って、GitLab CommunityエディションのコンテナをEnterpriseエディションのコンテナにアップグレードします。
- [Helmチャート（Kubernetes）CEからEEへ](https://docs.gitlab.com/charts/installation/deployment.html#convert-community-edition-to-enterprise-edition) \- このガイドに従って、GitLab Communityエディション HelmデプロイをEnterpriseエディションにアップグレードします。

### EnterpriseエディションからCommunityエディションへ

EnterpriseエディションのインストールをCommunityエディションにダウングレードするには、[このガイド](../downgrade_ee_to_ce/_index.md)に従って、プロセスを可能な限りスムーズにします。

## 追加機能のアップグレード手順

一部のGitLab機能には追加の手順があります。

### 外部Gitaly

アプリケーションサーバーをアップグレードする前に、Gitalyサーバーを新しいバージョンにアップグレードします。これにより、アプリケーションサーバー上のgRPCクライアントが、古いGitalyバージョンがサポートしていないRPCを送信するのを防ぎます。

### Geo

Geoを使用している場合:

- [Geoアップグレードドキュメント](../administration/geo/replication/upgrading_the_geo_sites.md)を確認します。
- Geoバージョン固有の更新手順についてお読みください。
  - [GitLab 17](versions/gitlab_17_changes.md)
  - [GitLab 16](versions/gitlab_16_changes.md)
  - [GitLab 15](versions/gitlab_15_changes.md)
- [データベースをアップグレードする](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance)場合は、Geo固有の手順を確認してください。
- _各_Geoサイト（プライマリおよび各セカンダリ）のアップグレードおよびロールバック計画を作成します。

### Kubernetes向けGitLabエージェント

KubernetesクラスターがGitLabに接続されている場合は、新しいGitLabバージョンに合わせて[Kubernetes向けGitLabエージェント](../user/clusters/agent/install/_index.md#update-the-agent-version)をアップグレードします。

### Elasticsearch

GitLabを更新する前に、[保留中の移行を確認](background_migrations.md#check-for-pending-migrations)して、高度な検索の移行が完了していることを確認します。

GitLabを更新した後、[新しいバージョンが互換性を損なう場合は、Elasticsearch](../integration/advanced_search/elasticsearch.md#version-requirements)をアップグレードする必要があるかもしれません。Elasticsearchの更新は**GitLabサポートの範囲外**です。

## サポートを利用する

問題が発生した場合:

- エラーをコピーし、後で分析するためにログを収集し、[最後に動作していたバージョンにロールバック](plan_your_upgrade.md#rollback-plan)します。次のツールを使用して、データの収集に役立てることができます。
  - [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos): LinuxパッケージまたはDockerを使用してGitLabをインストールした場合。
  - [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/): Helmチャートを使用してGitLabをインストールした場合。

サポート:

- [GitLabサポート](https://support.gitlab.com/hc/en-us)および、お持ちの場合はカスタマーサクセスマネージャーにお問い合わせください。
- [問題の状況が対象となる](https://about.gitlab.com/support/#definitions-of-support-impact)場合、および[プランに緊急サポートが含まれている](https://about.gitlab.com/support/#priority-support)場合は、緊急チケットを作成してください。

## 関連トピック

- [PostgreSQL拡張機能を管理する](../install/postgresql_extensions.md)
