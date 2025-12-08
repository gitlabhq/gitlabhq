---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoサイトのアップグレード
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

Geoサイトを更新する前に、これらのセクションを注意深くお読みください。バージョン固有のアップグレード手順に従わないと、予期しないダウンタイムが発生する可能性があります。ご不明な点がございましたら、[サポートにお問い合わせください](https://about.gitlab.com/support/#contact-support)。データベースのメジャーバージョンをアップグレードするには、Geoセカンダリへの[PostgreSQLレプリケーションの再初期化](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance)が必要です。これは、Linuxパッケージと外部で管理されるデータベースの両方に適用されます。これにより、予想以上のダウンタイムが発生する可能性があります。

{{< /alert >}}

Geoサイトのアップグレードには、次の手順が必要です:

1. アップグレード元またはアップグレード先のバージョンに応じた、バージョン固有のアップグレード手順:
   - [GitLab 18アップグレードノート](../../../update/versions/gitlab_18_changes.md)
   - [GitLab 17アップグレードノート](../../../update/versions/gitlab_17_changes.md)
   - [GitLab 16アップグレードノート](../../../update/versions/gitlab_16_changes.md)
   - [GitLab 15アップグレードノート](../../../update/versions/gitlab_15_changes.md)
1. すべてのアップグレードに関する[一般的なアップグレード手順](#general-upgrade-steps)。

## 一般的なアップグレード手順 {#general-upgrade-steps}

{{< alert type="note" >}}

これらの一般的なアップグレード手順では、マルチノード構成でのダウンタイムが必要です。ダウンタイムを回避したい場合は、[ゼロダウンタイムアップグレード](../../../update/zero_downtime.md#upgrade-multi-node-geo-instances)の使用を検討してください。

{{< /alert >}}

新しいGitLabバージョンがリリースされたときにGeoサイトをアップグレードするには、**プライマリ**サイトとすべての**セカンダリ**サイトをアップグレードします:

1. オプション。[各**セカンダリ**サイトでレプリケーションを一時停止](pause_resume_replication.md)して、**セカンダリ**サイトのディザスターリカバリー（DR）機能を保護します。
1. **プライマリ**サイトの各ノードにSSHで接続します。
1. [**プライマリ**サイトでGitLabをアップグレード](../../../update/package/_index.md)。
1. **プライマリ**サイトでテストを実行します。特に、DRを保護するために手順1でレプリケーションを一時停止した場合はテストを実行します。アップグレード後のテストの詳細については、[アップグレードヘルスチェックの実行](../../../update/plan_your_upgrade.md#run-upgrade-health-checks)を参照してください。
1. プライマリサイトとセカンダリサイトの両方の`/etc/gitlab/gitlab-secrets.json`ファイルのシークレットが同じであることを確認してください。ファイルは、サイトのすべてのノードで同じである必要があります。
1. **セカンダリ**サイトの各ノードにSSHで接続します。
1. [各**セカンダリ**サイトでGitLabをアップグレード](../../../update/package/_index.md)。
1. 手順1でレプリケーションを一時停止した場合は、[各**セカンダリ**でレプリケーションを再開](../_index.md#pausing-and-resuming-replication)してください。次に、各**セカンダリ**サイトでPumaとSidekiqを再起動します。これは、以前にアップグレードされた**プライマリ**サイトからレプリケートされるようになった新しいデータベーススキーマに対して初期化されるようにするためです。

   ```shell
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

1. **プライマリ**サイトと**セカンダリ**サイトをテストし、それぞれのバージョンを確認します。

### アップグレード後のステータスを確認 {#check-status-after-upgrading}

これでアップグレードプロセスが完了したので、すべてが正しく動作しているかどうかを確認することをお勧めします:

1. プライマリサイトとセカンダリサイトのアプリケーションノードでGeo Rakeタスクを実行します。すべてが緑色になっているはずです:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. **プライマリ**サイトのGeoダッシュボードでエラーがないか確認します。
1. **プライマリ**サイトにプッシュコードしてデータレプリケーションをテストし、**セカンダリ**サイトで受信されるかどうかを確認します。

問題が発生した場合は、[Geoトラブルシューティングガイド](troubleshooting/_index.md)を参照してください。
