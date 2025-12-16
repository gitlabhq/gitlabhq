---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: レプリケーションを一時停止および再開する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

レプリケーションの一時停止と再開は、GeoインストールでLinuxパッケージ管理のデータベースを使用している場合にのみサポートされます。外部データベースはサポートされていません。

プライマリサイトが壊滅的に失敗し、リカバリーできない場合は、**Do not pause replication**（レプリケーションを一時停止しないでください）。これにより、セカンダリサイトのプロモーションを成功させることを妨げる、到達不能なリカバリーターゲットが作成される可能性があります。

{{< /alert >}}

状況によっては、[アップグレード](upgrading_the_geo_sites.md)や[計画フェイルオーバー](../disaster_recovery/planned_failover.md)時など、プライマリサイトとセカンダリ間のレプリケーションを一時停止することが望ましい場合があります。

アップグレード中にセカンダリサイトでのユーザーアクティビティーを許可する場合は、[ゼロダウンタイムアップグレード](../../../update/zero_downtime.md)のためにレプリケーションを一時停止しないでください。一時停止すると、セカンダリサイトはますます最新ではない状態になります。既知の影響の1つは、ますます多くのGitフェッチがプライマリサイトにリダイレクトまたはプロキシされることです。追加の不明な影響がある可能性があります。

たとえば、別のURLを持つセカンダリサイトを一時停止すると、そのセカンダリサイトのURLでのサインインが中断される可能性があります。セカンダリサイトのURLでの新しいセッションなしで、プライマリサイトのルートURLにアクセスします。

## 一時停止と再開 {#pause-and-resume}

レプリケーションの一時停止と再開は、セカンダリサイトの特定のノードからのコマンドラインツールを介して行われます。データベースアーキテクチャに応じて、これは`postgresql`または`patroni`サービスのいずれかをターゲットにします:

- セカンダリサイトのすべてのサービスに単一ノードを使用している場合は、この単一ノードでコマンドを実行する必要があります。
- セカンダリサイトにスタンドアロンPostgreSQLノードがある場合は、このスタンドアロンPostgreSQLノードでコマンドを実行する必要があります。
- セカンダリサイトがPatroniクラスタリングを使用している場合は、これらのコマンドをセカンダリPatroniスタンバイリーダーノードで実行する必要があります。

セカンダリサイトのすべてのサービスに単一ノードを使用していない場合は、PostgreSQLまたはPatroniノードの`/etc/gitlab/gitlab.rb`に`gitlab_rails['geo_node_name'] = 'node_name'`という設定行が含まれていることを確認してください。ここで、`node_name`はアプリケーションノードの`geo_node_name`と同じです。

**To Pause: (from secondary site)**（一時停止するには：（セカンダリサイトから））

また、レプリケーションの一時停止後にPostgreSQLが再起動された場合（VMを再起動するか、`gitlab-ctl restart postgresql`でサービスを再起動することによって）、PostgreSQLは自動的にレプリケーションを再開することに注意してください。これは、アップグレード中または計画されたフェイルオーバーシナリオでは望ましくありません。

```shell
gitlab-ctl geo-replication-pause
```

**To Resume: (from secondary site)**（再開するには：（セカンダリサイトから））

```shell
gitlab-ctl geo-replication-resume
```
