---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セカンダリサイトのGeoプロキシ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 個別のURLを持つセカンダリサイトに対するHTTPプロキシは、GitLab 14.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/346112)されました（`geo_secondary_proxy_separate_urls`という[フラグを使用](../../feature_flags/_index.md)）。デフォルトでは無効になっています。
- [GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/346112)で有効になったのはGitLab 15.1です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。`geo_secondary_proxy_separate_urls`機能フラグは、将来のリリースで非推奨となり、削除される予定です。読み取り専用のGeoセカンダリサイトのサポートは、[issue 366810](https://gitlab.com/gitlab-org/gitlab/-/issues/366810)で提案されています。

{{< /alert >}}

セカンダリサイトは、完全な読み取り/書き込み可能なGitLabインスタンスとして動作します。セカンダリサイトは、すべての操作をプライマリサイトに透過的にプロキシしますが、[いくつかの重要な例外](#features-accelerated-by-secondary-geo-sites)があります。

この動作により、以下のようなユースケースが実現します:

- すべてのGeoサイトを単一のURLの背後に配置することで、ユーザーがどのサイトにアクセスしても、一貫性、シームレスさ、包括的なエクスペリエンスを提供できます。ユーザーは複数のGitLab URLを使い分ける必要はありません。
- 書き込みアクセス制御を気にすることなく、地理的にトラフィックをロードバランシングします。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[セカンダリサイトのGeoプロキシ](https://www.youtube.com/watch?v=TALLy7__Na8)を参照してください。
<!-- Video published on 2022-01-26 -->

既知の問題については、[Geoドキュメントのプロキシ関連アイテム](../_index.md#known-issues)を参照してください。

## Geoサイトの統一されたURLを設定する {#set-up-a-unified-url-for-geo-sites}

セカンダリサイトは、読み取り/書き込みのGitLabインスタンスとして透過的に機能します。したがって、単一の外部URLを使用して、リクエストがプライマリGeoサイトまたはセカンダリGeoサイトのいずれかに到達するようにできます。これにより、ユーザーがどのサイトにアクセスしても、一貫性、シームレスさ、包括的なエクスペリエンスを提供できます。ユーザーは、複数のURLを使い分けたり、複数のサイトの概念を意識したりする必要はありません。

次の方法で、トラフィックをGeoサイトにルーティングできます:

- Geoロケーション対応ドメインネームシステム。プライマリまたはセカンダリに関係なく、最も近いGeoサイトにトラフィックをルーティングします。例については、[ロケーション対応ドメインネームシステムの構成](#configure-location-aware-dns)に従ってください。
- ラウンドロビンドメインネームシステム。
- ロードバランサー。認証の失敗やサイトを跨ぐリクエストエラーを回避するには、スティッキーセッションを使用する必要があります。ドメインネームシステムルーティングは本質的にスティッキーであるため、この注意点はありません。

### ロケーション対応ドメインネームシステムの構成 {#configure-location-aware-dns}

プライマリまたはセカンダリに関係なく、最も近いGeoサイトにトラフィックをルーティングするには、この例に従ってください。

#### 前提要件 {#prerequisites}

この例では、`gitlab.example.com`サブドメインネームシステムを作成し、リクエストを自動的に誘導します:

- ヨーロッパから**セカンダリ**サイトへ。
- 他のすべてのロケーションから**プライマリ**サイトへ。

この例では、以下が必要です:

- 動作するGeoの**プライマリ**サイトと**セカンダリ**サイト。[Geo設定手順](../setup/_index.md)を参照してください。
- ドメインを管理するドメインネームシステムゾーン。以下の手順では、[AWS Route53](https://aws.amazon.com/route53/)および[GCP cloudドメインネームシステム](https://cloud.google.com/dns/)を使用していますが、[Cloudflare](https://www.cloudflare.com/)などの他のサービスも使用できます。

#### AWS Route53 {#aws-route53}

この例では、Route53 Hosted Zoneを使用して、Route53設定用のドメインを管理します。

Route53 Hosted Zoneでは、トラフィックポリシーエディタを使用して、さまざまなルーティング設定をセットアップできます。トラフィックポリシーエディタを作成するには、次の手順に従います:

1. [Route53ダッシュボード](https://console.aws.amazon.com/route53/home)に移動し、**Traffic policies**を選択します。
1. **Create traffic policy**（Traffic policyの作成）を選択します。
1. **Policy Name**フィールドに`Single Git Host`と入力し、**次へ**を選択します。
1. **DNS type**を`A: IP Address in IPv4 format`のままにします。
1. **Connect to**を選択し、**Geolocation rule**を選択します。
1. 最初の**ロケーション**:
   1. `Default`のままにします。
   1. **Connect to**を選択し、**New endpoint**を選択します。
   1. **種類**`value`を選択し、`<your **primary** IP address>`を入力します。
1. 2番目の**ロケーション**:
   1. `Europe`を選択します。
   1. **Connect to**を選択し、**New endpoint**を選択します。
   1. **種類**`value`を選択し、`<your **secondary** IP address>`を入力します。

   ![異なるIPアドレスを持つエンドポイントにそれぞれ接続された2つのロケーション（デフォルトとヨーロッパ）を示すRoute53トラフィックポリシーエディタ](img/single_url_add_traffic_policy_endpoints_v14_5.png)

1. **Create traffic policy**（Traffic policyの作成）を選択します。
1. **Policy record DNS name**に`gitlab`と入力します。

   ![トラフィックポリシーエディタ、バージョン、ホストゾーン、ドメインネームシステム設定フィールドを含むドメインネームシステムポリシーエディタレコードを作成するためのWebフォーム](img/single_url_create_policy_records_with_traffic_policy_v14_5.png)

1. **Create policy records**（ポリシーレコードの作成）を選択します。

`gitlab.example.com`のような単一ホストが正常にセットアップされました。これにより、ジオロケーションによってGeoサイトにトラフィックが分散されます。

#### GCP {#gcp}

この例では、ドメインを管理するGCP Cloudドメインネームシステムゾーンを作成します。

Geoベースのレコードセットを作成する場合、トラフィックのソースがポリシーエディタ項目と正確に一致しない場合、GCPはソースリージョンに最も近い一致を適用します。Geoベースのレコードセットを作成するには、次の手順に従います:

1. **Network Services**（ネットワークサービス） > **Cloud DNS**（Cloudドメインネームシステム）を選択します。
1. ドメイン用に設定されたゾーンを選択します。
1. **Add Record Set**（レコードセットの追加）を選択します。
1. ロケーション対応パブリックURLのドメインネームシステム名を入力します（例：`gitlab.example.com`）。
1. **Routing Policy**（ルーティングポリシーエディタ）を選択します: **Geo-Based**（Geoベース）。
1. **Add Managed RRData**（管理対象RRDataの追加）を選択します。
   1. **Source Region**（ソースリージョン）：**us-central1**を選択します。
   1. `<**primary** IP address>`を入力します。
   1. **完了**を選択します。
1. **Add Managed RRData**（管理対象RRDataの追加）を選択します。
   1. **Source Region**（ソースリージョン）：**europe-west1**を選択します。
   1. `<**secondary** IP address>`を入力します。
   1. **完了**を選択します。
1. **作成**を選択します。

`gitlab.example.com`のような単一ホストが正常にセットアップされました。これにより、ロケーション対応URLを使用してトラフィックがGeoサイトに分散されます。

### 各サイトで同じ外部URLを使用するように設定する {#configure-each-site-to-use-the-same-external-url}

単一のURLからすべてのGeoサイトへのルーティングをセットアップした後、サイトが異なるURLを使用している場合は、次の手順に従います:

1. 各GitLabサイトで、Rails（Puma、Sidekiq、Log-Cursor）を実行している**each**（各）ノードにSSHで接続し、`external_url`を単一URLに設定します:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. 変更を有効にするため、更新されたノードを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. セカンダリGeoサイトで設定された新しい外部URLに合わせて、プライマリデータベースにこの変更を反映させる必要があります。

   **プライマリ**サイトのGeo管理ページで、セカンダリプロキシを使用している各Geoセカンダリを編集し、`URL`フィールドを単一のURLに設定します。プライマリサイトもこのURLを使用していることを確認してください。

   サイトが相互に通信できるように、[`Internal URL`フィールドがサイトごとに一意であることを確認してください](../../geo_sites.md#set-up-the-internal-urls)。

Kubernetesでは、[プライマリサイトの場合と同じように、`global.hosts.domain`の下で同じドメインを使用](https://docs.gitlab.com/charts/advanced/geo/)できます。

## セカンダリGeoサイトの個別のURLをセットアップする {#set-up-a-separate-url-for-a-secondary-geo-site}

サイトごとに異なる外部URLを使用できます。これを使用して、特定のサイトを特定のユーザーセットに提供できます。あるいは、どのサイトを使用するかをユーザーが制御できるようにすることもできますが、選択の意味を理解する必要があります。

{{< alert type="note" >}}

GitLabは複数の外部URLをサポートしていません。[issue 21319](https://gitlab.com/gitlab-org/gitlab/-/issues/21319)を参照してください。固有の問題は、リクエストによってトリガーされなかったメールの送信など、サイトがHTTPリクエストのコンテキスト外で絶対URLを生成する必要がある場合が多いことです。

{{< /alert >}}

### プライマリサイトとは異なる外部URLにセカンダリGeoサイトを設定する {#configure-a-secondary-geo-site-to-a-different-external-url-than-the-primary-site}

セカンダリサイトがプライマリサイトと同じ外部URLを使用しているが、別のURLを使用するように変更する場合は、次の手順に従います:

1. セカンダリサイトで、Rails（Puma、Sidekiq、Log-Cursor）を実行している**each**（各）ノードにSSHで接続し、`external_url`をセカンダリサイトに必要なURLに設定します:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. 変更を有効にするため、更新されたノードを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. セカンダリGeoサイトで設定された新しい外部URLに合わせて、プライマリデータベースにこの変更を反映させる必要があります。

   **プライマリ**サイトのGeo管理ページで、ターゲットセカンダリサイトを編集し、`URL`フィールドに必要なURLに設定します。

   サイトが相互に通信できるように、[`Internal URL`フィールドがサイトごとに一意であることを確認してください](../../geo_sites.md#set-up-the-internal-urls)。必要なURLがこのサイトに固有の場合は、`Internal URL`フィールドをクリアできます。保存時に、デフォルトで外部URLになります。

## プライマリGeoサイトがダウンした場合のセカンダリサイトの動作 {#behavior-of-secondary-sites-when-the-primary-geo-site-is-down}

Webトラフィックがプライマリにプロキシされることを考慮すると、プライマリサイトにアクセスできない場合、セカンダリサイトの動作は異なります:

- UIとAPIのトラフィックは、プロキシされるため、プライマリと同じエラーを返します（または、プライマリにまったくアクセスできない場合は失敗します）。
- アクセスされている特定のセカンダリサイトで完全に最新の状態になっているリポジトリの場合、HTTP(S)またはSSHによる認証を含め、Gitの読み取り操作は引き続き期待どおりに動作します。ただし、GitLab Runnerによって実行されるGitの読み取りは失敗します。
- セカンダリサイトにレプリケートされないリポジトリに対するGit操作は、プロキシされるため、プライマリサイトと同じエラーを返します。
- すべてのGit書き込み操作は、プロキシされるため、プライマリサイトと同じエラーを返します。

## セカンダリGeoサイトによって高速化される機能 {#features-accelerated-by-secondary-geo-sites}

セカンダリGeoサイトに送信されるほとんどのHTTPトラフィックは、プライマリGeoサイトにプロキシされます。このアーキテクチャにより、セカンダリGeoサイトは書き込みリクエストをサポートし、読み取り後の書き込みの問題を回避できます。特定の**read**（読み取り）リクエストは、レイテンシーと近くの帯域幅を向上させるために、セカンダリサイトによってローカルで処理されます。

次の表は、GeoセカンダリサイトWorkhorseプロキシを介してテストされたコンポーネントの詳細を示しています。すべてのデータ型を網羅しているわけではありません。

このコンテキストでは、高速化された読み取りとは、セカンダリサイトのコンポーネントのデータが最新であることを条件に、セカンダリサイトから提供される読み取りリクエストを指します。セカンダリサイトのデータが最新ではないと判断された場合、リクエストはプライマリサイトに転送されます。下の表にリストされていないコンポーネントに対する読み取りリクエストは、常に自動的にプライマリサイトに転送されます。

| 機能/コンポーネント                                 | 高速化された読み取り？                   | 備考 |
|:----------------------------------------------------|:-------------------------------------|-------|
| プロジェクト、Wiki、デザインリポジトリ（ウェブUIを使用） | {{< icon name="dotted-circle" >}}対象外 |       |
| プロジェクト、Wikiリポジトリ（Gitを使用）                | {{< icon name="check-circle" >}}対応 | Gitの読み取りはローカルのセカンダリから提供され、プッシュはプライマリにプロキシされます。選択的な同期、またはリポジトリがGeoセカンダリにローカルに存在しない場合は、「見つかりません」というエラーがスローされます。 |
| プロジェクト、個人スニペット（Web UIを使用）        | {{< icon name="dotted-circle" >}}対象外 |       |
| プロジェクト、個人スニペット（Gitを使用）               | {{< icon name="check-circle" >}}対応 | Gitの読み取りはローカルのセカンダリから提供され、プッシュはプライマリにプロキシされます。選択的な同期、またはリポジトリがGeoセカンダリにローカルに存在しない場合は、「見つかりません」というエラーがスローされます。 |
| グループウィキリポジトリ（Web UIを使用）            | {{< icon name="dotted-circle" >}}対象外 |       |
| グループウィキリポジトリ（Gitを使用）                   | {{< icon name="check-circle" >}}対応 | Gitの読み取りはローカルのセカンダリから提供され、プッシュはプライマリにプロキシされます。選択的な同期、またはリポジトリがGeoセカンダリにローカルに存在しない場合は、「見つかりません」というエラーがスローされます。 |
| ユーザーアップロード                                        | {{< icon name="dotted-circle" >}}対象外 |       |
| LFSオブジェクト（Web UIを使用）                      | {{< icon name="dotted-circle" >}}対象外 |       |
| LFSオブジェクト（Gitを使用）                             | {{< icon name="check-circle" >}}対応 |       |
| Pages                                               | {{< icon name="dotted-circle" >}}対象外 | ページは（アクセス制御なしで）同じURLを使用できますが、個別に設定する必要があり、プロキシされません。 |
| 高度な検索（Web UIを使用）                  | {{< icon name="dotted-circle" >}}対象外 |       |
| コンテナレジストリ                                  | {{< icon name="dotted-circle" >}}対象外 | コンテナレジストリは、ディザスターリカバリーシナリオでのみ推奨されます。セカンダリサイトのコンテナレジストリが最新でない場合、リクエストはプライマリサイトに転送されないため、読み取りリクエストは古いデータで提供されます。コンテナレジストリの高速化が計画されています。関心を示すか、GitLabの担当者に依頼するには、[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365864)に同意するかコメントしてください。 |
| 依存プロキシ                                    | {{< icon name="dotted-circle" >}}対象外 | Geoセカンダリサイトの依存プロキシへの読み取りリクエストは、常にプライマリサイトにプロキシされます。 |
| その他のすべてのデータ                                      | {{< icon name="dotted-circle" >}}対象外 | この表にリストされていないコンポーネントに対する読み取りリクエストは、常に自動的にプライマリサイトに転送されます。 |

機能の高速化をリクエストするには、[epic 8239](https://gitlab.com/groups/gitlab-org/-/epics/8239)にイシューが既に存在するかどうかを確認し、関心を示すか、GitLabの担当者に依頼するには、同意するかコメントしてください。該当するイシューが存在しない場合は、イシューを開き、epicで言及してください。

## セカンダリサイトのHTTPプロキシを無効にする {#disable-secondary-site-http-proxying}

セカンダリサイトHTTPプロキシは、統合URLを使用する場合、つまりプライマリサイトと同じ`external_url`で設定されている場合、デフォルトでセカンダリサイトで有効になります。この場合、ルーティングに応じて、同じURLでまったく異なる動作が提供されるため、プロキシを無効にしても役に立たない傾向があります。GeoセカンダリサイトでHTTPプロキシを無効にすると、サイトは読み取り専用モードで動作し、注意すべきいくつかの重要な制限があります。

### セカンダリプロキシを無効にするとどうなるか {#what-happens-if-you-disable-secondary-proxying}

プロキシ機能フラグを無効にすると、次の一般的な影響があります。

#### HTTPおよびGitリクエスト {#http-and-git-requests}

- セカンダリサイトは、プライマリサイトにHTTPリクエストをプロキシしません。代わりに、それ自体で処理するか、失敗しようとします。
- Gitリクエストは通常成功します。Gitプッシュは、プライマリサイトにリダイレクトまたはプロキシされます。
- Gitリクエスト以外に、データを書き込む可能性のあるHTTPリクエストは失敗します。読み取りリクエストは通常成功します。

| 機能/コンポーネント                                 | 成功                                 | 備考 |
|:----------------------------------------------------|:----------------------------------------|-------|
| プロジェクト、Wiki、デザインリポジトリ（Web UIを使用） | {{< icon name="dotted-circle" >}}多分 | 読み取りは、ローカルに保存されたデータから提供されます。書き込みによりエラーが発生します。 |
| プロジェクト、WikiGitリポジトリ（Gitを使用）                | {{< icon name="check-circle" >}}対応    | Gitの読み取りはローカルに保存されたデータから提供され、プッシュはプライマリにプロキシされます。リポジトリがGeoセカンダリサイトにローカルに存在しない場合（たとえば、選択的同期による除外が原因の場合）、「見つかりません」というエラーが発生します。 |
| プロジェクト、個人スニペット（ウェブUIを使用）        | {{< icon name="dotted-circle" >}}おそらく | 読み取りはローカルに保存されたデータから提供されます。書き込みによりエラーが発生します。 |
| プロジェクト、個人スニペット（Gitを使用）               | {{< icon name="check-circle" >}}対応    | Gitの読み取りはローカルに保存されたデータから提供され、プッシュはプライマリにプロキシされます。リポジトリがGeoセカンダリサイトにローカルに存在しない場合（たとえば、選択的同期による除外が原因の場合）、「見つかりません」というエラーが発生します。 |
| グループWikiリポジトリ（ウェブUIを使用）            | {{< icon name="dotted-circle" >}}おそらく | 読み取りはローカルに保存されたデータから提供されます。書き込みによりエラーが発生します。 |
| グループWikiリポジトリ（Gitを使用）                   | {{< icon name="check-circle" >}}対応    | Gitの読み取りはローカルに保存されたデータから提供され、プッシュはプライマリにプロキシされます。リポジトリがGeoセカンダリサイトにローカルに存在しない場合（たとえば、選択的同期による除外が原因の場合）、「見つかりません」というエラーが発生します。 |
| ユーザーアップロード                                        | {{< icon name="dotted-circle" >}}おそらく | アップロードファイルはローカルに保存されたデータから提供されます。セカンダリサイトでファイルをアップロードしようとすると、エラーが発生します。 |
| LFSオブジェクト（ウェブUIを使用）                      | {{< icon name="dotted-circle" >}}おそらく | 読み取りはローカルに保存されたデータから提供されます。書き込みによりエラーが発生します。 |
| LFSオブジェクト（Gitを使用）                             | {{< icon name="check-circle" >}}対応    | LFSオブジェクトはローカルに保存されたデータから提供され、プッシュはプライマリにプロキシされます。LFSオブジェクトがGeoセカンダリサイトにローカルに存在しない場合（たとえば、選択的同期による除外が原因の場合）、「見つかりません」というエラーが発生します。 |
| Pages                                               | {{< icon name="dotted-circle" >}}おそらく | ページは、（アクセス制御なしで）同じURLを使用できますが、個別に構成する必要があり、プロキシされません。 |
| 高度な検索（ウェブUIを使用）                  | {{< icon name="dotted-circle" >}}対象外    |       |
| コンテナレジストリ                                  | {{< icon name="dotted-circle" >}}対象外    | コンテナレジストリは、ディザスターリカバリーシナリオにのみ推奨されます。セカンダリサイトのコンテナレジストリが最新でない場合、プライマリサイトにリクエストが転送されないため、読み取りリクエストには古いデータが提供されます。コンテナレジストリの高速化が計画されています。関心を示すか、GitLabの担当者に代行を依頼するには、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/365864)に同意するまたはコメントしてください。 |
| 依存プロキシ                                    | {{< icon name="dotted-circle" >}}対象外    |       |
| その他すべてのデータ                                      | {{< icon name="dotted-circle" >}}おそらく | 読み取りはローカルに保存されたデータから提供されます。書き込みによりエラーが発生します。 |

環境変数を使用する代わりに、機能フラグを使用する必要があります。`GEO_SECONDARY_PROXY`

URLが統合されていなくても、GitLab 15.1では、セカンダリサイトでHTTPプロキシがデフォルトで有効になっています。

#### 利用規約への同意 {#terms-of-service-acceptance}

プロキシが無効になっている場合、セカンダリサイトのみにアクセスするユーザーは、利用規約またはその他の法的契約に適切に同意できません。これにより、次のイシューが発生します:

- **No record of acceptance**（同意の記録なし）: 従業員がセカンダリサイトにのみログインする場合、利用規約への同意は、セカンダリサイトプロキシが無効になっている場合は、（利用規約への同意を含む）書き込み操作がプロキシされないため、プライマリデータベースに記録されません。たとえ利用規約メッセージが表示されたとしてもです。
- **Legal compliance concerns**（法的コンプライアンスに関する懸念）: 従業員がセカンダリサイトのみのアクセスパターンでGitLabサービスを使用している場合、利用規約への同意の検証可能な記録がないため、組織は適切な法的保護を欠いている可能性があります。

利用規約に適切に同意するには、回避策として、プライマリサイトに少なくとも1回はアクセスする必要があります。プライマリで同意されると、この情報は通常のGeo同期を介してセカンダリサイトにレプリケートされます。

{{< alert type="note" >}}この制限は、コンプライアンスまたは法的目的で、利用規約の文書化された同意を必要とする組織に影響します。ユーザーが最初の利用規約に同意できるように、プライマリサイトへのアクセスを確保してください。{{< /alert >}}

### すべてのセカンダリサイトでプロキシを無効にする {#disable-proxy-on-all-secondary-sites}

すべてのセカンダリサイトでプロキシを無効にする必要がある場合は、機能フラグを無効にするのが最も簡単です:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. プライマリGeoサイトでPumaまたはSidekiqを実行しているノードにSSHで接続し、次を実行します:

   ```shell
   sudo gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. セカンダリサイトのPumaを実行しているすべてのノードで、Pumaを再起動します:

   ```shell
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. プライマリGeoサイトで、Toolboxポッドでこのコマンドを実行します:

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. セカンダリサイトでWebserviceポッドを再起動します:

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

{{< /tab >}}

{{< /tabs >}}

変更を元に戻して、セカンダリサイトのプロキシを再度有効にするには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. プライマリGeoサイトでPumaまたはSidekiqを実行しているノードにSSHで接続し、次を実行します:

   ```shell
   sudo gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. セカンダリサイトのPumaを実行しているすべてのノードで、Pumaを再起動します:

   ```shell
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. プライマリGeoサイトで、Toolboxポッドでこのコマンドを実行します:

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. セカンダリサイトでWebserviceポッドを再起動します:

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

{{< /tab >}}

{{< /tabs >}}

### サイトごとにセカンダリサイトのHTTPプロキシを無効にする {#disable-secondary-site-http-proxying-per-site}

複数のセカンダリサイトがある場合は、次の手順に従って、各セカンダリサイトで個別にHTTPプロキシを無効にできます:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. セカンダリサイト上の（ユーザートラフィックを直接提供する）各アプリケーションノードにSSHで接続し、次の環境変数を追加します:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_workhorse['env'] = {
     "GEO_SECONDARY_PROXY" => "0"
   }
   ```

1. 変更を有効にするため、更新されたノードを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

`--set gitlab.webservice.extraEnv.GEO_SECONDARY_PROXY="0"`を使用するか、valuesファイルで以下を指定できます:

```yaml
gitlab:
  webservice:
    extraEnv:
      GEO_SECONDARY_PROXY: "0"
```

{{< /tab >}}

{{< /tabs >}}

### セカンダリサイトのGitプロキシを無効にする {#disable-secondary-site-git-proxying}

次の転送を無効にすることはできません:

- SSH経由のGitプッシュ
- Gitrepositoryがセカンダリサイトで最新ではない場合のSSH経由のGitプル
- HTTP経由のGitプッシュ
- Gitrepositoryがセカンダリサイトで最新ではない場合のHTTP経由のGitプル
