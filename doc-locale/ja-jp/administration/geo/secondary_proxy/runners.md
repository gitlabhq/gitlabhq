---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: セカンダリRunner
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.8で`geo_proxy_check_pipeline_refs`[フラグ](../../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/9779)されました。デフォルトでは無効になっています。
- GitLab 16.9で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/434041)になりました。

{{< /history >}}

[セカンダリサイトのGeoプロキシ](_index.md)を使用すると、`gitlab-runner`をセカンダリサイトに登録できます。これにより、プライマインスタンスからの負荷が軽減されます。

{{< alert type="note" >}}

パイプラインの最初のステージ中に開始されるジョブは、ほとんどの場合、GitクローンリクエストがプライマリGeoサイトに転送されます。これは、通常、これらのクローンが、セカンダリサイトによってGitデータがレプリケートおよび検証される前に発生するためです。Gitの変更が大きい、帯域幅が小さい、パイプラインステージが短いといった理由により、後続のステージもセカンダリサイトから提供されるとは限りません。ほとんどの場合、パイプラインの後続のステージでは、セカンダリサイトからGitデータが提供されます。[Issue 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176)は、最初のステージのクローンリクエストがセカンダリサイトから提供される可能性を高めるための機能強化を提案しています。

{{< /alert >}}

## ロケーションアウェアパブリックURL（Unified URL）でセカンダリrunnerを使用する {#use-secondary-runners-with-a-location-aware-public-url-unified-url}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

[ロケーションアウェアDNS](_index.md#configure-location-aware-dns)を使用すると、機能フラグを有効にすることで、追加の設定なしで動作します。セカンダリサイトと同じ場所にrunnerをインストールして登録すると、最も近いGeoサイトと自動的に通信し、セカンダリが古くなっている場合にのみプライマリにプロキシされます。

## 個別のURLでセカンダリrunnerを使用する {#use-secondary-runners-with-separate-urls}

個別のセカンダリURLを使用すると、runnerは次のようになります:

1. セカンダリ外部URLで登録されます。
1. [`clone_url`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-clone_url-works)がセカンダリインスタンスの`external_url`に設定された状態で構成されます。

## セカンダリrunnerでの計画フェイルオーバーの処理 {#handling-a-planned-failover-with-secondary-runners}

[計画フェイルオーバー](../disaster_recovery/planned_failover.md)を実行すると、セカンダリrunnerはローカルインスタンスとの通信を維持しようとします。これにより、runnerの容量が減少し、考慮する必要がある場合があります。

### ロケーションアウェアパブリックURLを使用 {#with-location-aware-public-url}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

[ロケーションアウェアDNS](_index.md#configure-location-aware-dns)を使用すると、すべてのrunnerが最も近いGeoサイトに自動的に接続します。

新しいプライマリへのフェイルオーバー時:

- 古いプライマリがまだDNSレコードにある間は、以前に古いプライマリに接続されていたrunnerは、引き続き古いプライマリからジョブを読み込むことを試みます。到達できない場合、runnerは[これを検出し](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-unhealthy_requests_limit-and-unhealthy_interval-works)、インスタンスが戻った後、一定期間リクエストを停止します。
- [複数のセカンダリノード](../disaster_recovery/_index.md#promoting-secondary-geo-replica-in-multi-secondary-configurations)がある場合、最初のフェイルオーバー後、残りのセカンダリは、新しいプライマリで[レプリケート](../disaster_recovery/_index.md#step-2-initiate-the-replication-process)されるまで異常な状態になります。それらに接続されているrunnerはチェックインできなくなり、ヘルスチェックも開始されます。
- 異常なノードをGeo DNSエントリから削除すると、runnerは次に最も近いインスタンスを選択します。アーキテクチャによっては、状態が低下しているGeoサイトに過大な負担がかかる可能性があるため、これは望ましくない場合があります。

これらの問題を軽減するために、Geoサイトが100%に戻るまで、runnerの一部を[一時停止](#pausing-runners)またはシャットダウンできます。

これらの問題を心配していない場合は、ここで何もする必要はありません。

### 個別のURLを使用 {#with-separate-urls}

- 古いプライマリをサービスに戻す場合は、オンラインに戻るまで古いプライマリrunnerを一時停止できます。これにより、ヘルスチェックの開始を防ぎます。
- 古いプライマリが戻らない場合、または一時的にrunnerの容量が減少することを避けたい場合は、プライマリrunnerが新しいプライマリに接続するように再設定する必要があります。
- 複数のセカンダリが使用されている場合、新しいプライマリにレプリケートされている間、runnerは新しいプライマリに接続するように[一時停止](#pausing-runners)、シャットダウン、または再設定する必要があります。

### runnerの一時停止 {#pausing-runners}

次のいずれかの方法を使用するには、管理者アクセス権が必要です:

- **管理者**エリアから:
  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. **設定** > **Runners**を選択します。
  1. 一時停止するrunnerを特定します。
  1. 一時停止する各runnerの横にある`pause`ボタンを選択します。
  1. フェイルオーバーが完了したら、前の手順で一時停止したrunnerの一時停止を解除します。
- [Runners API](../../../api/runners.md)を使用します:
  1. 管理者アクセス権を持つ[パーソナルアクセストークン](../../../user/profile/personal_access_tokens.md)をフェッチまたは作成します。
  1. Runnerのリストを取得します。[APIを使用して](../../../api/runners.md#list-all-runners)リストをフィルタリングできます。
  1. 一時停止するrunnerを特定し、`id`をメモします。
  1. [APIドキュメントに従って](../../../api/runners.md#pause-a-runner)、各runnerを一時停止します。
  1. フェイルオーバーが完了したら、`paused=false`を設定して、APIを使用してrunnerのリストの一時停止を解除します。
