---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: インスタンスの昇格後のバージョンの追いつき、機能の有効化、ライセンスの適用。
title: 移行後のアクティビティ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedインスタンスがプライマリサイトに昇格すると、複数の機能がお客様と調整済みの一連のスケジュールされたアクティビティで有効化されます。これらのアクティビティは、インスタンスがGeoセカンダリサイトである間は実行できないか、または移行が成功したことを確認するまで意図的に保留されるため、昇格の前ではなく後に発生します。

GitLabは、お客様自身が行うライセンスの追加を除き、これらのアクティビティをすべて実行します。各アクティビティは、カットオーバー後の検証に合格し、インスタンスがカットオーバーに起因する未解決の問題なしにユーザーにサービスを提供できるようになってからのみ開始されます。Professional Servicesの移行チームが、スケジュールをお客様と調整します。

## バージョンの追いつき {#version-catch-up}

アップグレードは、本番前のカットオーバーから本番カットオーバーまでの間、凍結されます。この凍結により、両方の環境が同一のバージョンに保たれるため、テストした内容がそのまま実際の環境になります。

この凍結の影響で、インスタンスが昇格すると、GitLab Dedicatedフリートの他のインスタンスより1バージョン遅れた状態で実行されます。GitLab Dedicatedは、現在のGitLabリリースに対して1つ前のマイナーバージョン（N-1）を実行します。詳細については、[バージョニングモデル](../releases.md#versioning-model)を参照してください。

追いつき作業は、意図的かつ順序立てて行われます。インスタンスは、1回の大きなジャンプではなく、複数のメンテナンスウィンドウにわたって、途中のバージョンを経てアップグレードされます。これらのアップグレードはそれぞれ[ゼロダウンタイムアップグレード](../maintenance.md#zero-downtime-upgrades)であるため、追いつき作業によってユーザーに繰り返し停止が発生することはありません。

アップグレードパスには、必須の中間バージョンが含まれる場合があります。パスに含まれるバージョンを確認するには、[アップグレードパスツール](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/)を使用してください。

追いつきが完了すると、GitLabは毎週のメンテナンスウィンドウを再度有効にします。それ以降、インスタンスは他のGitLab Dedicatedインスタンスと同様に、標準の月次リリースケイデンスに従います。詳細については、[メンテナンスウィンドウ](../maintenance.md#maintenance-windows)および[リリースロールアウトスケジュール](../releases.md#release-rollout-schedule)を参照してください。

GitLab Dedicatedのバージョンスケジュールを追跡するには、[GitLab Dedicated情報ポータル](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/)を使用してください。

> [!note]
> 追いつき期間中、インスタンスは他のGitLab Dedicatedインスタンスよりも古いバージョンで実行される場合があります。この違いは想定内であり、一時的なものです。

## 高度な検索 {#advanced-search}

高度な検索はGitLab Dedicatedで完全にサポートされており、GitLabが検索インフラストラクチャをプロビジョニングおよび管理します。

Geoは高度な検索インデックスをレプリケートしないため、インスタンスがGeoセカンダリサイトである間はインデックスを構築できません。そのため、GitLabは昇格後、お客様と調整した時期に高度な検索を有効化し、その時点でコンテンツのインデックスを作成します。移行元インスタンスの既存の検索クラスターは移行されません。インデックス作成中も、基本検索は引き続き利用できます。

詳細については、[高度な検索](../../../integration/advanced_search/elasticsearch.md)を参照してください。

## 高度な分析 {#advanced-analytics}

高度な分析機能はClickHouse Cloudによってサポートされています。これらの機能は、インスタンスが昇格した時点では有効になっていません。GitLabは、カットオーバー後の別のスケジュールされたステップでこれらを有効化します。

ClickHouse Cloudはサポートされているリージョンでのみ利用できるため、利用可否はプライマリリージョンによって異なります。詳細については、[ClickHouse Cloudのリージョン](../create_instance/data_residency_high_availability.md#clickhouse-cloud)を参照してください。

このインテグレーションが提供する内容については、[ClickHouse](../../../integration/clickhouse.md)を参照してください。

## ディザスターリカバリー用のGeoセカンダリサイト {#geo-secondary-site-for-disaster-recovery}

移行中は、GitLab Dedicatedインスタンスは単一サイトとして実行されます。インスタンス自体が移行元インスタンスのGeoセカンダリサイトとして機能しているため、セカンダリリージョンは設定されません。そのため、移行中は標準のGitLab Dedicated Geoディザスターリカバリートポロジーは構成されていません。

移行が完了すると、GitLabがセカンダリサイトを追加します。セカンダリサイトの追加は意図的なステップです。追加後は、以前のレプリケーション構成に戻すことができなくなるためです。セカンダリサイトが追加された後、インスタンスは他のGitLab Dedicatedインスタンスと同じディザスターリカバリー態勢を備えます。

詳細については、[ディザスターリカバリーのためのGeoレプリケーション](../disaster_recovery.md#geo-replication)を参照してください。

> [!note]
> 移行中を含め、常に自動バックアップが実施されています。詳細については、[自動バックアップ](../disaster_recovery.md#automated-backups)を参照してください。

## RunnerとCI/CD {#runners-and-cicd}

Runnerの登録レコードはデータベースに保存されており、データベースは移行されるため、既存のRunnerは保持されます。

独自のドメインを維持する場合、インスタンスのホスト名は変更されず、Runnerは設定変更なしでGitLab Dedicatedに再接続します。GitLabが提供するドメインに移行する場合は、Runnerの設定でインスタンスのURLを更新してください。

非常に古いGitLabバージョンのRunnerでは、再接続に遅延が発生する場合があります。カットオーバーを円滑に進めるため、移行ウィンドウの前に、自己管理のRunnerを最新バージョンに更新してください。

詳細については、[フェイルオーバー中のRunnerの接続性](../../geo/disaster_recovery/planned_failover.md#runner-connectivity-during-failover)を参照してください。

GitLabが管理するRunnerについては、[ホストされているRunner](../hosted_runners.md)を参照してください。

## インテグレーションと認証 {#integrations-and-authentication}

インテグレーション、Webhook、送信接続は、本番前の[テスト期間](process.md#testing-period)中に検証されます。本番カットオーバー後、本番インスタンスに対して同じインテグレーションを確認してください。

以下の項目を確認してください:

- シングルサインオン
- 内部ターゲットへのWebhookの配信
- メールの配信
- RunnerおよびKubernetesクラスターからのコンテナレジストリへのアクセス
- 送信AWS PrivateLink経由でプライベートターゲットに到達するインテグレーション
- インスタンスを呼び出す外部SaaSサービス。許可リストを使用している場合、IP許可リストの例外が必要です

Kubernetes向けGitLabエージェントは、新しいKubernetes向けGitLabエージェントサーバー（KAS）のURLに対して再登録する必要があります。

## GitLab Dedicatedライセンスの追加 {#add-your-gitlab-dedicated-license}

カットオーバー後にGitLab Dedicatedライセンスを追加する必要があります。

移行中、GitLabはライセンス情報をデータベースの他の部分とともにレプリケートするため、データベースにはGitLab Self-Managedインスタンスのライセンスが含まれています。そのライセンスは、GitLab Dedicatedサブスクリプションを対象としていません。

ライセンスの担当者はGitLab Dedicatedのアクティベーションコードを受け取り、昇格したインスタンスでそれを有効化する必要があります。詳細については、[ライセンスキーの追加](../../license_file.md#add-license-in-the-admin-area)を参照してください。

アクティベーションコードを受け取っていない場合、またはアクティベーションが失敗する場合は、GitLabのアカウントチームにお問い合わせください。

## 関連トピック {#related-topics}

- [GitLab DedicatedへのGeo移行](_index.md)
- [Geo移行の要件](requirements.md)
- [Geo移行プロセス](process.md)
