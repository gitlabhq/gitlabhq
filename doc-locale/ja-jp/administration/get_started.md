---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 管理の概要。
title: GitLabの管理を始める
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabの管理を始めましょう。組織とその認証を設定し、GitLabのセキュリティ対策、モニタリング、バックアップを行います。

## 認証 {#authentication}

認証は、インストールを安全に保つための最初のステップです。

- [すべてのユーザーに2要素認証（2FA）を実施](../security/two_factor_authentication.md)します。
- ユーザーに次の対策を徹底させます。
  - 強力で安全なパスワードを選択させます。可能であれば、パスワード管理システムに保存させるようにしてください。
  - すべてのユーザーに対して[2要素認証（2FA）](../user/profile/account/two_factor_authentication.md)が設定されていない場合は、各自のアカウントで有効にさせてください。ワンタイムシークレットコードは追加の防御策となり、たとえパスワードが漏洩しても不正アクセスを防げます。
  - バックアップメールアドレスを追加させてください。アカウントにアクセスできなくなった場合でも、GitLabサポートチームがより迅速に対応できるようになります。
  - リカバリーコードを保存または印刷させてください。認証デバイスにアクセスできない場合でも、これらのリカバリーコードを使用してGitLabアカウントにサインインできるようになります。
  - [SSHキー](../user/ssh.md)をプロファイルに追加させてください。SSHを使用すると、必要に応じて新しいリカバリーコードを生成できます。
  - [パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を作成させてください。2FAを使用している場合、これらのトークンを使用してGitLab APIにアクセスできます。

## プロジェクトとグループ {#projects-and-groups}

グループとプロジェクトを設定して、環境を整理します。

- [プロジェクト](../user/project/working_with_projects.md): ファイルやコードのホームを指定し、ビジネスカテゴリごとにイシューを追跡および整理します。
- [グループ](../user/group/_index.md): ユーザーまたはプロジェクトのコレクションを整理します。これらのグループを使用して、ユーザーやプロジェクトをすばやく割り当てることができます。
- [ロール](../user/permissions.md): プロジェクトとグループのユーザーアクセスと表示レベルを定義します。

<i class="fa-youtube-play" aria-hidden="true"></i>[グループとプロジェクト](https://www.youtube.com/watch?v=cqb2m41At6s)の概要をご覧ください。

はじめに:

- [プロジェクト](../user/project/_index.md)を作成します。
- [グループ](../user/group/_index.md#create-a-group)を作成します。
- グループに[メンバーを追加](../user/group/_index.md#add-users-to-a-group)します。
- [サブグループ](../user/group/subgroups/_index.md#create-a-subgroup)を作成します。
- サブグループに[メンバーを追加](../user/group/subgroups/_index.md#subgroup-membership)します。
- [外部認証コントロール](settings/external_authorization.md#configuration)を有効にします。

**その他のリソース**

- [Run multiple Agile teams](https://www.youtube.com/watch?v=VR2r1TJCDew)（複数のアジャイルチームを運用する）。
- [LDAPを使用してグループメンバーシップを同期](auth/ldap/ldap_synchronization.md#group-sync)します。
- 継承された権限でユーザーアクセスを管理します。最大20レベルのサブグループを使用して、チームとプロジェクトの両方を整理できます。
  - [継承されたメンバーシップ](../user/project/members/_index.md#membership-types)。
  - [例](../user/group/subgroups/_index.md)。

## プロジェクトをインポートする {#import-projects}

GitHub、Bitbucket、または別のGitLabインスタンスなどの外部ソースからプロジェクトをインポートする必要が生じる場合があります。多くの外部ソースからGitLabへのインポートが可能です。

- [GitLabプロジェクトに関するドキュメント](../user/project/_index.md)をご確認ください。
- [プロジェクトの移行の代替手段](../ci/ci_cd_for_external_repos/_index.md)として、[リポジトリミラーリング](../user/project/repository/mirror/_index.md)も検討してください。
- 一般的な移行パスに関するドキュメントについては、[インポートしてGitLabに移行する](../user/import/_index.md)を確認してください。
- [インポート/エクスポートAPI](../api/project_import_export.md#export-a-project)を使用して、プロジェクトのエクスポートのスケジュールを設定します。

### 一般的なプロジェクトのインポート {#popular-project-imports}

- [GitHub EnterpriseからGitLab Self-Managedへのインポート](../integration/github.md)
- [Bitbucket Server](../user/import/bitbucket_server.md)

これらのデータタイプのサポートについては、GitLabアカウントマネージャーまたはGitLabサポートに、当社の専門的な移行サービスについてお問い合わせください。

## GitLabインスタンスのセキュリティ {#gitlab-instance-security}

セキュリティは、オンボーディングプロセスにおける重要な要素です。インスタンスを保護することで、作業と組織を保護できます。

ここで挙げた内容は網羅的なものではありませんが、これらを実施することでインスタンスのセキュリティを確保するための良い第一歩となります。

- 長いrootパスワードを使用し、Vaultに保存します。
- 信頼できるSSL証明書をインストールし、更新と失効のプロセスを確立します。
- 組織のガイドラインに従って[SSHキーの制限を設定](../security/ssh_keys_restrictions.md)します。
- [新規ユーザーアカウント作成をオフにする](settings/sign_up_restrictions.md#disable-new-user-account-creation)。
- 確認メールを必須にします。
- パスワードの長さ制限を設定し、SSOまたはSAMLによるユーザー管理を設定します。
- 新規ユーザーによるアカウント作成を許可する場合は、メールドメインを制限してください。
- 2要素認証（2FA）を必須にします。
- [HTTPS経由のGitに対するパスワード認証](settings/sign_in_restrictions.md#allow-password-authentication-for-git-over-https)をオフにする。
- [不明なサインインのメール通知](settings/sign_in_restrictions.md#email-notification-for-unknown-sign-ins)を設定します。
- [ユーザーとIPレートの制限](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/#user-and-ip-rate-limits)を設定します。
- [Webhook](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/#webhooks)のローカルアクセスを制限します。
- [保護されたパスに対してレート制限](settings/protected_paths.md)を設定します。
- [セキュリティアラート](https://about.gitlab.com/company/preference-center/)の通知を受け取るようにするため、メール配信設定ページからサブスクライブしてください。
- GitLabの[ブログページ](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/)で、セキュリティのベストプラクティスについて随時確認してください。

## GitLabのパフォーマンスをモニタリングする {#monitor-gitlab-performance}

基本的なセットアップが完了したら、続いて、GitLabのモニタリングサービスを確認します。Prometheusは、GitLabの主要なパフォーマンスモニタリングツールです。他のモニタリングソリューション（Zabbix、New Relicなど）とは異なり、PrometheusはGitLabと緊密に統合されており、広範なコミュニティのサポートがあります。

- [Prometheus](monitoring/prometheus/_index.md)がキャプチャする[GitLabメトリクス](monitoring/prometheus/gitlab_metrics.md#metrics-available)をご確認ください。
- GitLabの[バンドルされたソフトウェアメトリクス](monitoring/prometheus/_index.md#bundled-software-metrics)の詳細を参照してください。
- デフォルトでは、Prometheusとそのexporterは有効になっています。ただし、[サービスを設定](monitoring/prometheus/_index.md#configuring-prometheus)する必要があります。
- [アプリケーションのパフォーマンスメトリクス](https://about.gitlab.com/blog/working-with-performance-metrics/)が重要な理由をご確認ください。
- Grafanaを統合して、パフォーマンスメトリクスに基づいた[ビジュアルダッシュボードを構築](https://youtu.be/f4R7s0An1qE)できます。

### モニタリングのコンポーネント {#components-of-monitoring}

- [Webサーバー](monitoring/prometheus/gitlab_metrics.md#puma-metrics): サーバーリクエストを処理し、他のバックエンドサービスのトランザクションを支援します。CPU、メモリ、ネットワークIOトラフィックをモニタリングして、このノードの健全性を追跡します。
- [Workhorse](monitoring/prometheus/gitlab_metrics.md#metrics-available): メインサーバーからのWebトラフィックの輻輳を軽減します。レイテンシーの急増をモニタリングして、このノードの健全性を追跡します。
- [Sidekiq](monitoring/prometheus/gitlab_metrics.md#sidekiq-metrics): GitLabのスムーズな動作を支えるバックグラウンド操作を処理します。未処理のタスクキューが長くなっていないかをモニタリングして、このノードの健全性を追跡します。

## GitLabデータをバックアップする {#back-up-your-gitlab-data}

GitLabは、データを安全に保ち復元可能にするためのバックアップ手段を提供しています。

- バックアップ戦略を決めます。
- 毎日のバックアップを作成するcronジョブの作成を検討します。
- 設定ファイルを個別にバックアップします。
- バックアップから除外するものを決めます。
- バックアップのアップロード先を決めます。
- バックアップのライフタイムを制限します。
- バックアップと復元のテストを実行します。
- バックアップを定期的に検証する方法を準備します。

### インスタンスをバックアップする {#back-up-an-instance}

バックアップ手順は、デプロイに使用したのがLinuxパッケージかHelmチャートかによって異なります。

Linuxパッケージを使用するシングルノードインストール環境をバックアップするには、1つのRakeタスクを使用できます。

[LinuxパッケージまたはHelmを使用している場合のバックアップ方法](backup_restore/_index.md)の詳細をご確認ください。このプロセスはインスタンス全体をバックアップしますが、設定ファイルはバックアップしません。設定ファイルは別途バックアップしてください。暗号化キーが暗号化されたデータと一緒に保存されないように、設定ファイルとバックアップアーカイブは別の場所に保管してください。

#### バックアップを復元する {#restore-a-backup}

バックアップは、作成されたものと全く同じバージョンおよびタイプ（Community EditionまたはEnterprise Edition）のGitLabにのみ復元することができます。

- [Linuxパッケージ（Omnibus）を使用している場合のバックアップと復元に関するドキュメント](https://docs.gitlab.com/omnibus/settings/backups)をご確認ください。
- [Helmチャートを使用している場合のバックアップと復元に関するドキュメント](https://docs.gitlab.com/charts/backup-restore/)をご確認ください。

### 代替バックアップ戦略 {#alternative-backup-strategies}

状況によっては、バックアップ用のRakeタスクが最適なソリューションではない場合があります。Rakeタスクがうまく機能しない場合に検討すべき[代替手段](backup_restore/_index.md)を次に示します。

#### ファイルシステムスナップショット {#file-system-snapshot}

GitLabサーバーに大量のGitリポジトリデータが含まれている場合、GitLabのバックアップスクリプトでは処理が遅すぎる可能性があります。特にオフサイトの場所にバックアップする場合は、さらに遅くなることがあります。

通常、Gitリポジトリデータのサイズが約200 GBに達したあたりから速度の低下が始まります。このような場合、バックアップ戦略の一部として、ファイルシステムスナップショットの使用を検討するとよいでしょう。たとえば、次のコンポーネントを使用しているGitLabサーバーを考えてみましょう。

- Linuxパッケージを使用している。
- AWS上にホストされ、`/var/opt/gitlab`にマウントされたEBSドライブでext4ファイルシステムを使用している。

このEC2インスタンスは、EBSスナップショットを取得することで、アプリケーションデータのバックアップの要件を満たしています。このバックアップには、すべてのリポジトリ、アップロード、PostgreSQLのデータが含まれます。

仮想サーバー上でGitLabを実行している場合は、GitLabサーバー全体の仮想マシン（VM）スナップショットを作成できます。仮想マシン（VM）スナップショットを作成する際は、多くの場合サーバーのシャットダウンが必要となります。

#### GitLab Geo {#gitlab-geo}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

Geoは、GitLabインスタンスのローカルの読み取り専用インスタンスを提供します。

GitLab Geoは、ローカルのGitLabノードを使用することでリモートチームの作業効率を高めるだけでなく、ディザスターリカバリーソリューションとしても使用できます。[Geoをディザスターリカバリーソリューションとして](geo/disaster_recovery/_index.md)使用する方法の詳細をご覧ください。

Geoは、データベース、Gitリポジトリ、その他のいくつかの資産をレプリケートします。[Geoがレプリケートするデータタイプ](geo/replication/datatypes.md#replicated-data-types)の詳細をご覧ください。

## GitLabサポートによる支援を受ける {#get-help-with-gitlab-support}

GitLabは、さまざまなチャンネルを通じてGitLab Self-Managedのサポートを提供します。

- 優先サポート: [PremiumおよびUltimate](https://about.gitlab.com/pricing/)のGitLab Self-Managedのお客様は優先サポートを受けることができ、プランごとに応答時間が設定されています。
- ライブアップグレード支援: 本番環境のアップグレード中に、エキスパートによる1対1のガイダンスを受けられます。**優先サポートプラン**をご契約の場合、サポートチームのメンバーとのライブセッションを予約し、画面を共有しながらサポートを受けることができます。

ヘルプを参照するには:

- GitLabドキュメントを使用し、セルフサービスで解決する。
- [GitLabフォーラム](https://forum.gitlab.com/)に参加して、コミュニティサポートを活用する。
- [サポートチケットを送信](https://support.gitlab.com/hc/en-us/requests/new)する。

## APIとレート制限 {#api-and-rate-limits}

レート制限は、サービス拒否攻撃やブルートフォース攻撃を防ぎます。ほとんどの場合、1つのIPアドレスあたりのリクエストレートを制限することで、アプリケーションやインフラストラクチャへの負荷を軽減できます。

レート制限は、アプリケーションのセキュリティ向上にもつながります。

### レート制限を設定する {#configure-rate-limits}

デフォルトのレート制限は、**管理者**エリアから変更できます。設定の詳細については、[**管理者**エリアのページ](../security/rate_limits.md#configurable-limits)を参照してください。

- [イシューのレート制限](settings/rate_limit_on_issues_creation.md)を定義して、ユーザーごとの1分あたりのイシュー作成リクエストの最大数を設定します。
- 未認証のWebリクエストに対して、[ユーザーとIPレートの制限](settings/user_and_ip_rate_limits.md)を適用します。
- [rawエンドポイントのレート制限](settings/rate_limits_on_raw_endpoints.md)を確認します。デフォルトでは、rawファイルアクセスは1分あたり300リクエストに制限されています。
- [インポート/エクスポートのレート制限](settings/import_export_rate_limits.md)には、6つのアクティブなデフォルト設定がありますのでご確認ください。

APIとレート制限の詳細については、[APIのページ](../api/rest/_index.md)を参照してください。

## GitLabのトレーニングリソース {#gitlab-training-resources}

GitLabを管理する方法について詳しく学ぶことができます。

- [GitLabフォーラム](https://forum.gitlab.com/)に参加して、優れたコミュニティメンバーと情報交換しましょう。
- [ブログ](https://about.gitlab.com/blog/)で、以下の最新情報をご確認ください。
  - リリース
  - アプリケーション
  - コントリビュート
  - ニュース
  - イベント

### 有料のGitLabトレーニング {#paid-gitlab-training}

- GitLabの教育サービス: 専門のトレーニングコースを通じて、[GitLabとDevOpsのベストプラクティス](https://about.gitlab.com/professional-services/education/)について詳しく学ぶことができます。全コースの詳細については、カタログをご確認ください。

### 無料のGitLabトレーニング {#free-gitlab-training}

- GitLabの基本: [GitとGitLabの基本](../tutorials/_index.md)に関するセルフサービスガイドをご覧ください。
- GitLab University: [GitLab University](https://university.gitlab.com/learn/dashboard)の体系化されたコースで、新しいGitLabスキルを習得できます。

### サードパーティのトレーニング {#third-party-training}

- Udemy: より手頃な価格でガイド付きのトレーニングをご希望の場合は、Udemyの[GitLab CI: Pipelines, CI/CD, and DevOps for Beginners](https://www.udemy.com/course/gitlab-ci-pipelines-ci-cd-and-devops-for-beginners/)（パイプライン、CI/CD、DevOpsに関する初心者向けのコース）をご検討ください。
- LinkedIn Learning: 低コストで受講できるガイド付きトレーニングの選択肢として、LinkedIn Learningの[GitLabによる継続的デリバリー](https://www.linkedin.com/learning/continuous-integration-and-continuous-delivery-with-gitlab?replacementOf=continuous-delivery-with-gitlab)もご覧ください。
