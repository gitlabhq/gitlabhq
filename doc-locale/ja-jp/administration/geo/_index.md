---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo
description: 地理的にGitLabを分散させます。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Geoは、広範囲にわたる分散型開発チーム向けのソリューションです。ディザスターリカバリー戦略の一環としてウォームスタンバイを提供することを目的としています。ただし、Geoはすぐに使用できるHAソリューション**ではありません**。

{{< alert type="warning" >}}

Geoは、リリースごとに大幅な変更が行われます。アップグレードはサポートされており、[ドキュメント](#upgrading-geo)も提供されていますが、インストールを行うバージョンに合ったドキュメントを必ずご使用ください。

{{< /alert >}}

適切なバージョンのドキュメントを使用しているかどうかを確認するには、[GitLab.comのGeoページ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/geo/_index.md)に移動し、**ブランチ/タグを切り替え**ドロップダウンリストから適切なリリースを選択します。たとえば、[`v15.7.6-ee`](https://gitlab.com/gitlab-org/gitlab/-/blob/v15.7.6-ee/doc/administration/geo/_index.md)などです。

単一のGitLabインスタンスから遠く離れた場所にいるチームやRunnerにとって、大規模なリポジトリのフェッチは時間がかかる場合があります。

Geoは、リモートチームに地理的に近い場所に配置できるローカルキャッシュを提供し、読み取りリクエストに対応できるようにします。これにより、大規模なリポジトリのクローン作成やフェッチにかかる時間を短縮し、開発を加速させ、リモートチームの生産性を高めることができます。

Geoセカンダリサイトは、書き込みリクエストを透過的にプライマリサイトにプロキシします。すべてのGeoサイトは、単一のGitLab URLに応答するように設定できます。したがって、ユーザーがどのサイトにアクセスしたとしても、一貫性がありシームレスで包括的なエクスペリエンスを提供できます。

Geoでは、[Geo用語集](glossary.md)に記載された定義済みの用語を使用しています。これらの用語をよく理解しておくようにしましょう。

## ユースケース {#use-cases}

Geoの実装は、いくつかのユースケースに対応しています。このセクションでは、想定されるユースケースをいくつか紹介し、それぞれの利点を説明します。

### リージョナルディザスターリカバリー {#regional-disaster-recovery}

Geoを[ディザスターリカバリー](disaster_recovery/_index.md)ソリューションとして使用すると、プライマリサイトとは異なるリージョンにウォームスタンバイセカンダリサイトを用意できます。データはセカンダリサイトに継続的に同期され、常に最新の状態に保たれます。データセンターやネットワークの停止、ハードウェアの故障などの障害が発生した場合、完全に稼働しているセカンダリサイトにフェイルオーバーすることが可能です。[計画フェイルオーバー](disaster_recovery/planned_failover.md)を使用して、ディザスターリカバリーのプロセスとインフラストラクチャをテストできます。

利点:

- 地域的な災害が発生した場合の事業継続性。
- 低い目標リカバリー時間（RTO）と目標リカバリー時点（RPO）。
- GitLab Environment Toolkit（GET）による自動化された（ただし完全に自動ではない）フェイルオーバー。
- 最小限の運用作業。人による介入なしの継続的なレプリケーションと検証により、セカンダリサイトは常に最新状態に保たれ、レプリケートされたデータが転送中や保存中に破損しないことが保証されます。

### リモートチームの迅速化 {#remote-team-acceleration}

リモートチームに地理的に近い場所にGeoセカンダリサイトを配置することで、読み取り操作を高速化するローカルキャッシュを提供します。複数のGeoセカンダリサイトを配置して、それぞれにリモートチームが必要とするプロジェクトのみを同期するように調整できます。[透過的なプロキシ](secondary_proxy/_index.md)と[統一されたURL](replication/location_aware_git_url.md)による地理的ルーティングにより、一貫性のあるシームレスなデベロッパーエクスペリエンスを実現します。

利点:

- 地理的に分散したチームのGitLabエクスペリエンスを向上させます。Geoはセカンダリサイトで完全なGitLabエクスペリエンスを提供します。1つのプライマリGitLabサイトを維持しながら、セカンダリサイトで各分散チーム向けに読み取り/書き込みアクセスと完全なUIエクスペリエンスを提供します。
- 分散したデベロッパーが大規模なリポジトリやプロジェクトをクローンおよびフェッチするのにかかる時間を、数分から数秒に短縮します。
- すべてのデベロッパーが、どこにいてもアイデアを提案したり、並行して作業したりすることが可能となります。
- プライマリサイトとセカンダリサイト間で読み取りの負荷を分散します。
- 遠隔オフィス間の低速な接続を克服し、分散チームの速度を向上させることで時間を節約します。
- 自動化されたタスク、カスタムインテグレーション、内部ワークフローの読み込み時間を短縮します。

### CI/CDトラフィックのオフロード {#cicd-traffic-offload}

[Geoセカンダリサイトからクローンを作成](secondary_proxy/runners.md)するようにCI/CD Runnerを設定できます。セカンダリサイトはRunnerのワークロードのニーズに合わせて調整でき、プライマリサイトをミラーリングする必要はありません。サポートされている読み取りリクエストは、セカンダリサイトのキャッシュされたデータで処理され、セカンダリサイトのデータが古くなっているか利用できない場合、リクエストは透過的にプライマリサイトに転送されます。

利点:

- プライマリサイトでは、トラフィックをセカンダリサイトに分散することで、CI/CDトラフィックがユーザーエクスペリエンスに与える影響を軽減できます。
- リージョン間のトラフィックを削減し、組織にとって最もコスト効率の良い場所でCI/CDコンピューティングを実行できます。データのリージョン間コピーを1つ作成し、それをセカンダリサイトに対する繰り返しの読み取りリクエストで利用できるようにします。

### 追加のユースケース {#additional-use-cases}

#### インフラストラクチャの移行 {#infrastructure-migrations}

Geoを使用して、新しいインフラストラクチャに移行できます。GitLabインスタンスを新しいサーバーまたはデータセンターに移行する場合、Geoを使用することで、旧インスタンスがユーザーへのサービス提供を継続している間に、GitLabデータを新しいインスタンスにバックグラウンドで移行できます。アクティブなGitLabデータへの変更はすべて新しいインスタンスにコピーされるため、切り替え中にデータが失われることはありません。

ただし、Geoを使用して、PostgreSQLデータベースを別のオペレーティングシステムに移行することはできません。[PostgreSQLが動作しているオペレーティングシステムをアップグレードする](../postgresql/upgrading_os.md)を参照してください。

利点:

- バックアップと復元を使用する移行方式と比べて、移行中のダウンタイムを大幅に短縮できます。切り替え時のダウンタイムウィンドウの前にアクティブなGitLabインスタンスを停止することなく、バックグラウンドでデータを新しいインスタンスにコピーします。

#### GitLab Dedicatedへの移行 {#migration-to-gitlab-dedicated}

Geoを使用して、GitLab Self-Managedから[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)に移行することもできます。GitLab Dedicatedへの移行は、インフラストラクチャの移行に似ています。

利点:

- ダウンタイムが大幅に短縮され、オンボーディングエクスペリエンスがスムーズになります。データ移行がバックグラウンドで行われている間、GitLab Self-Managedを引き続き使用できます。

## Geoでは対応できないユースケース {#what-geo-is-not-designed-to-address}

Geoは、すべてのユースケースに対応できるよう設計されているわけではありません。このセクションでは、Geoが適切なソリューションではないユースケースの例を紹介します。

### データ輸出コンプライアンスを強制する {#enforce-data-export-compliance}

Geoの[選択的同期](replication/selective_synchronization.md)機能を使用すると、セカンダリサイトに同期されるプロジェクトを制限できますが、これはリージョン間のトラフィックやストレージ要件を削減するために設計されており、輸出コンプライアンスを強制することを目的としたものではありません。プライバシー、サイバーセキュリティ、および該当する貿易管理法に関する法的義務については、ソリューションおよびドキュメントに基づいて、ご自身で継続的に判断する必要があります。ソリューションおよびドキュメントは変更される可能性があります。

### アクセス制御を提供する {#provide-access-control}

Geoの[読み取り専用セカンダリサイト](secondary_proxy/_index.md#disable-secondary-site-git-proxying)機能は、中核的な機能ではなく、将来的にサポートされない可能性があります。そのため、アクセス制御の目的でこの機能に依存しないでください。GitLabは、アクセス制御により適した、[認証および認可](../auth/_index.md)の制御機能を提供しています。

### ゼロダウンタイムアップグレードの代替手段 {#an-alternative-to-zero-downtime-upgrades}

Geoは、[ゼロダウンタイムアップグレード](../../update/zero_downtime.md)のためのソリューションではありません。Geoセカンダリサイトをアップグレードする前に、Geoプライマリサイトをアップグレードする必要があります。

### 悪意のある破損や意図しない破損から保護する {#protect-against-malicious-or-unintentional-corruption}

Geoは、プライマリサイトの破損をすべてのセカンダリサイトにレプリケートします。悪意のある破損や意図しない破損から保護するには、[バックアップ](../backup_restore/_index.md)でGeoを補完する必要があります。

### アクティブ-アクティブ型の高可用性設定 {#active-active-high-availability-configuration}

Geoは、アクティブ-パッシブ型の高可用性ソリューションとして設計されています。結果整合性の同期モデルで動作します。つまり、セカンダリサイトはプライマリサイトと緊密に同期されているわけではありません。セカンダリサイトはわずかに遅れてプライマリサイトに追従するため、災害発生時に少量のデータが失われる可能性があります。災害発生時にセカンダリサイトにフェイルオーバーするには、人的介入が必要です。ただし、[GitLab Environment Toolkit（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit)を使用してすべてのサイトをデプロイしている場合、セカンダリサイトをプライマリサイトに昇格させるプロセスの大部分はGETによって自動化されています。

## Gitalyクラスター（Praefect） {#gitaly-cluster-praefect}

Geoを[Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md)と混同しないようにご注意ください。GeoとGitaly Clusterの違いの詳細については、[Geoとの比較](../gitaly/praefect/_index.md#comparison-to-geo)を参照してください。

## Geoの仕組み {#how-geo-works}

以下は、GitLab環境におけるGeoの動作の簡単な概要です。詳細については、Geoの開発ドキュメントを参照してください。

Geoインスタンスは、データの読み取りに加えて、プロジェクトのクローン作成やフェッチにも使用できます。これにより、遠隔地との間で大規模なリポジトリの操作がはるかに高速化されます。

![Geoの概要](img/geo_overview_v11_5.png)

Geoを有効にすると、次のようになります。

- 元のインスタンスは**プライマリ**サイトと呼ばれます。
- レプリケートを行うサイトは**セカンダリ**サイトと呼ばれます。

次の点に注意してください。

- **セカンダリ**サイトは、**プライマリ**サイトと通信して、次のことを行います。
  - ログイン用のユーザーデータを取得する（API）。
  - リポジトリ、LFSオブジェクト、添付ファイルをレプリケートする（HTTPS + JWT）。
- **プライマリ**サイトは、レプリケーションの詳細を表示するために**セカンダリ**サイトと通信します。**プライマリ**サイトは、同期および検証データを取得するために**セカンダリ**サイトに対してGraphQLクエリ（API）を実行します。
- Git LFSを含め、HTTPおよびSSHを通じて**セカンダリ**サイトに直接プッシュできます。その際、セカンダリサイトはリクエストを**プライマリ**サイトにプロキシします。
- Geoを使用する場合、[既知の問題](#known-issues)がいくつか存在します。

### アーキテクチャ {#architecture}

次の図は、Geoの基盤アーキテクチャを示しています。

![Geoのアーキテクチャ](img/geo_architecture_v13_8.png)

この図の説明:

- **プライマリ**サイトと1つの**セカンダリ**サイトの詳細を示しています。
- データベースへの書き込みは、**プライマリ**サイトでのみ実行できます。**セカンダリ**サイトは、[PostgreSQLストリーミングレプリケーション](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION)を使用してデータベースの更新を受信します。
- [LDAPサーバー](#ldap)が存在する場合は、[ディザスターリカバリー](disaster_recovery/_index.md)シナリオに備えてレプリケートするよう設定する必要があります。
- **セカンダリ**サイトは、JWTによって保護された特別な認証メカニズムを使用して、**プライマリ**サイトに対してさまざまなタイプの同期を実行します。
  - リポジトリは、HTTPS経由でGitを介してクローンまたは更新されます。
  - 添付ファイル、LFSオブジェクト、およびその他のファイルは、プライベートAPIエンドポイントを通じてHTTPS経由でダウンロードされます。

Git操作を実行するユーザーの視点では、次のように動作します。

- **プライマリ**サイトは、完全な読み取り/書き込み可能なGitLabインスタンスとして動作します。
- **セカンダリ**サイトは、完全な読み取り/書き込み可能なGitLabインスタンスとして動作します。**セカンダリ**サイトは、すべての操作を**プライマリ**サイトに透過的にプロキシしますが、[いくつかの重要な例外](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites)があります。特に、セカンダリサイトが最新の状態であれば、Gitのフェッチは**セカンダリ**サイトによって処理されます。

GitLab UIを閲覧するユーザーやAPIを使用するユーザーの視点では、次のように動作します。

- **プライマリ**サイトは、完全な読み取り/書き込み可能なGitLabインスタンスとして動作します。
- **セカンダリ**サイトは、完全な読み取り/書き込み可能なGitLabインスタンスとして動作します。**セカンダリ**サイトは、すべての操作を**プライマリ**サイトに透過的にプロキシしますが、[いくつかの重要な例外](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites)があります。特に、Web UIアセットは**セカンダリ**サイトによって提供されます。

図を簡略化するために、一部の必要なコンポーネントは省略されています。

- SSH経由のGitの操作には、[`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell)が必要です。
- HTTPS経由のGitの操作には、[`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse)が必要です。

**セカンダリ**サイトには、2つの異なるPostgreSQLデータベースが必要です。

- メインGitLabデータベースからデータをストリーミングする、読み取り専用データベースインスタンス。
- **セカンダリ**サイトが内部的に使用し、レプリケートされたデータを記録するための[読み取り/書き込みデータベースインスタンス（トラッキングデータベース）](#geo-tracking-database)。

**セカンダリ**サイトでは、追加のデーモンである[Geo Log Cursor](#geo-log-cursor)も実行します。

## Geoを実行するための要件 {#requirements-for-running-geo}

Geoを実行するには、次の要件を満たす必要があります。

- OpenSSH 6.9以降をサポートするオペレーティングシステム（[データベース内の許可されたSSHキーの高速検索](../operations/fast_ssh_key_lookup.md)に必要）。次のオペレーティングシステムは、最新バージョンのOpenSSHが含まれていることが確認されています。
  - [CentOS](https://www.centos.org) 7.4以降
  - [Ubuntu](https://ubuntu.com) 16.04以降
- 可能な場合は、すべてのGeoサイトで同じバージョンのオペレーティングシステムを使用する必要があります。Geoサイト間で異なるバージョンのオペレーティングシステムを使用する場合は、データベースインデックスのサイレントな破損を防ぐため、Geoサイト間で**必ず**[OSのロケールデータの互換性を確認](replication/troubleshooting/common.md#check-os-locale-data-compatibility)してください。
- [ストリーミングレプリケーション](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION)機能を使用するGitLabリリースでは、[サポートされているPostgreSQLのバージョン](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-framework/postgresql-upgrade-cadence/)を使用する必要があります。
  - [PostgreSQLの論理レプリケーション](https://www.postgresql.org/docs/16/logical-replication.html)はサポートされていません。
- すべてのサイトで[同じPostgreSQLバージョン](setup/database.md#postgresql-replication)を実行する必要があります。
- Git 2.9以降
- LFSを使用する場合、ユーザー側ではGit-lfs 2.4.2以降が必要です。
- すべてのサイトで、完全に同じGitLabバージョンを実行する必要があります。[メジャー、マイナー、パッチバージョン](../../policy/maintenance.md#versioning)のすべてが一致していなくてはなりません。
- すべてのサイトで、同じ[リポジトリストレージ](../repository_storage_paths.md)を定義する必要があります。

さらに、GitLabの[最小要件](../../install/requirements.md)も確認し、より良いエクスペリエンスのために最新バージョンのGitLabを使用してください。

### ファイアウォールルール {#firewall-rules}

次の表に、Geoの**プライマリ**サイトと**セカンダリ**サイト間で開いておく必要がある基本的なポートを示します。フェイルオーバーを簡素化するために、ポートを双方向で解放することをおすすめします。

| 送信元サイト | 送信元ポート | 宛先サイト | 宛先ポート | プロトコル    |
|-------------|-------------|------------------|------------------|-------------|
| プライマリ     | 任意         | セカンダリ        | 80               | TCP（HTTP）  |
| プライマリ     | 任意         | セカンダリ        | 443              | TCP（HTTPS） |
| セカンダリ   | 任意         | プライマリ          | 80               | TCP（HTTP）  |
| セカンダリ   | 任意         | プライマリ          | 443              | TCP（HTTPS） |
| セカンダリ   | 任意         | プライマリ          | 5432             | TCP         |
| セカンダリ   | 任意         | プライマリ          | 5000             | TCP（HTTPS） |

GitLabで使用するポートの完全なリストについては、[パッケージのデフォルト](../package_information/defaults.md)を参照してください。

{{< alert type="warning" >}}

Geoサイト間のPostgreSQLレプリケーションでは、内部VPCピアリングなどのプライベートネットワーキング接続を使用する必要があります。PostgreSQLポートをインターネットに公開しないでください。PostgreSQLポートをインターネットに公開すると、GitLabデータベースへの完全な書き込み権限を持つ不正アクセスが発生し、GitLabインスタンス全体と関連するすべてのデータが侵害されるおそれがあります。

{{< /alert >}}

{{< alert type="note" >}}

[Webターミナル](../../ci/environments/_index.md#web-terminals-deprecated)のサポートには、ロードバランサーがWebSocket接続を正しく処理する必要があります。HTTPまたはHTTPSプロキシを使用する場合、ロードバランサーが`Connection`および`Upgrade`のホップバイホップヘッダーを通過させるように設定されている必要があります。詳細については、[Webターミナル](../integration/terminal.md)統合ガイドを参照してください。

{{< /alert >}}

{{< alert type="note" >}}

ポート443にHTTPSプロトコルを使用する場合は、ロードバランサーにSSL証明書を追加する必要があります。代わりにGitLabアプリケーションサーバーでSSLを終了する場合は、TCPプロトコルを使用します。{{< /alert >}}

{{< alert type="note" >}}

外部/内部URLに`HTTPS`のみを使用している場合は、ファイアウォールでポート80を開く必要はありません。{{< /alert >}}

#### 内部URL {#internal-url}

GeoセカンダリサイトからGeoプライマリサイトへのHTTPリクエストは、Geoプライマリサイトの内部URLを使用します。**管理者**エリアのGeoプライマリサイト設定でこれが明示的に定義されていない場合、プライマリサイトのパブリックURLが使用されます。

Geoプライマリサイトの内部URLを更新するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo > サイト**を選択します。
1. プライマリサイトで**編集**を選択します。
1. **内部URL**を変更し、**変更の保存**を選択します。

### Geoトラッキングデータベース {#geo-tracking-database}

トラッキングデータベースインスタンスは、ローカルインスタンスで何を更新する必要があるかを制御するメタデータとして使用されます。次に例を示します。

- 新しいアセットをダウンロードする。
- 新しいLFSオブジェクトをフェッチする。
- 最近更新されたリポジトリから変更をフェッチする。

レプリケートされたデータベースインスタンスは読み取り専用であるため、各**セカンダリ**サイトにはこの追加のデータベースインスタンスが必要です。

### Geo Log Cursor {#geo-log-cursor}

このデーモンは次の処理を行います。

- **プライマリ**サイトから**セカンダリ**データベースインスタンスにレプリケートされたイベントのログを読み取る。
- 実行する必要がある変更内容で、Geoトラッキングデータベースインスタンスを更新する。

トラッキングデータベースインスタンス上で何らかの項目が更新対象としてマークされると、**セカンダリ**サイト上の非同期ジョブが必要な操作を実行し、状態を更新します。

この新しいアーキテクチャにより、GitLabはサイト間の接続の問題に対して高い回復力を持つようになります。**セカンダリ**サイトが**プライマリ**サイトからどれだけ長く切断されていても、すべてのイベントを正しい順序で再生し、再び**プライマリ**サイトと同期できるようになります。

## 既知の問題 {#known-issues}

{{< alert type="warning" >}}

これらの既知の問題は、GitLabの最新バージョンのみを反映しています。古いバージョンを使用している場合は、さらに別の問題が存在する可能性があります。

{{< /alert >}}

- **セカンダリ**サイトに直接プッシュすると、セカンダリサイトが[直接処理する](https://gitlab.com/gitlab-org/gitlab/-/issues/1381)のではなく、リクエストを**プライマリ**サイトにリダイレクトする（HTTPの場合）か、またはリクエストをプライマリサイトにプロキシします（SSHの場合）。URIに認証情報が埋め込まれている場合、HTTP経由でGitを使用することはできません（例: `https://user:personal-access-token@secondary.tld`）。詳細については、[Geoサイトの使用](replication/usage.md)方法を参照してください。
- OAuthログインを行うには、**プライマリ**サイトがオンラインである必要があります。既存のセッションやGitには影響しません。**セカンダリ**サイトがプライマリとは別のOAuthプロバイダーを使用できるようにするためのサポートは、[現在計画中](https://gitlab.com/gitlab-org/gitlab/-/issues/208465)です。
- インストールでは、いくつかの手順を手動で実行する必要があり、状況によっては全体で約1時間かかる場合があります。GitLabの[リファレンスアーキテクチャ](../reference_architectures/_index.md)に基づいて、[GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit)のTerraformやAnsibleスクリプトを使用して、本番環境のGitLabインスタンスをデプロイおよび運用することを検討してください。これには、日常的なタスクの自動化も含まれます。[エピック1465](https://gitlab.com/groups/gitlab-org/-/epics/1465)では、Geoのインストールをさらに改善する提案がなされています。
- イシュー/マージリクエストのリアルタイム更新（たとえば、ロングポーリングを使用した更新）は、[HTTPプロキシが無効](secondary_proxy/_index.md#disable-secondary-site-http-proxying)になっている**セカンダリ**サイトでは機能しません。
- [選択的同期](replication/selective_synchronization.md)は、レプリケート対象となるリポジトリとファイルを制限するだけです。PostgreSQLのデータ全体は引き続きレプリケートされます。選択的同期は、コンプライアンス対応や輸出規制のユースケースに対応するように構築されたものではありません。
- [Pagesのアクセス制御](../../user/project/pages/pages_access_control.md)は、セカンダリサイトでは機能しません。詳細については、[イシュー9336](https://gitlab.com/gitlab-org/gitlab/-/issues/9336)（詳細）を参照してください。
- 複数のセカンダリサイトを持つデプロイにおける[ディザスターリカバリー](disaster_recovery/_index.md)では、プロモートされなかったすべてのセカンダリサイトで、PostgreSQLのストリーミングレプリケーションを再初期化して新しいプライマリサイトに従わせる必要があるため、ダウンタイムが発生します。
- SSH経由のGitの場合、どのサイトを閲覧してもプロジェクトのクローンURLが正しく表示されるようにするには、セカンダリサイトがプライマリサイトと同じポートを使用する必要があります。詳細については、[イシュー339262](https://gitlab.com/gitlab-org/gitlab/-/issues/339262)を参照してください。
- セカンダリサイトに対してSSH経由でGitプッシュを行う場合、1.86 GBを超えるプッシュは機能しません。このバグについては、[イシュー413109](https://gitlab.com/gitlab-org/gitlab/-/issues/413109)で追跡しています。
- バックアップは、[Geoセカンダリサイトでは実行できません](replication/troubleshooting/postgresql_replication.md#message-error-canceling-statement-due-to-conflict-with-recovery)。
- セカンダリサイトに対してSSH経由でオプション付きのGitプッシュを行うと、機能せず、接続が切断されます。詳細については、[イシュー417186](https://gitlab.com/gitlab-org/gitlab/-/issues/417186)を参照してください。
- Geoセカンダリサイトは、ほとんどの場合、パイプラインの最初のステージにおけるクローンリクエストを高速化（提供）しません。Gitの変更が大きい、帯域幅が小さい、パイプラインステージが短いといった理由により、後続のステージもセカンダリサイトから提供されるとは限りません。一般に、後続のステージに対するクローンリクエストはセカンダリサイトから提供されます。[イシュー446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176)では、この理由について説明するとともに、Runnerのクローンリクエストがセカンダリサイトから提供される可能性を高めるための機能拡張が提案されています。
- 単一のGitリポジトリに対して高頻度でプッシュが行われると、セカンダリサイトのローカルコピーが常に最新ではないという状態に陥る可能性があります。このような場合、そのリポジトリに対するすべてのGitフェッチがプライマリサイトに転送されることになります。詳細については、[イシュー455870](https://gitlab.com/gitlab-org/gitlab/-/issues/455870)を参照してください。
- [プロキシ](secondary_proxy/_index.md)機能は、PumaサービスまたはWebサービスのGitLabアプリケーションでのみ実装されているため、他のサービスではこの動作の恩恵を受けることができません。リクエストが常にプライマリサイトに送信されるようにするには、[別のURL](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site)を使用する必要があります。該当するサービスには、次のようなものがあります。
  - GitLabコンテナレジストリ - `registry.example.com`のように、[別のドメインを使用するように設定できます](../packages/container_registry.md#configure-container-registry-under-its-own-domain)。セカンダリサイトのコンテナレジストリは、ディザスターリカバリーのみを目的としています。特にプッシュ操作の場合、ユーザーをセカンダリサイトにルーティングしないでください。データがプライマリサイトに伝播されないからです。
  - GitLab Pages - [GitLab Pagesを運用するための前提要件](../pages/_index.md#prerequisites)の一部として、常に別のドメインを使用する必要があります。
- [統一されたURL](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)を使用している場合、Let's Encryptは同じドメインを通じて両方のIPアドレスに到達できなければ、証明書を生成できません。Let's Encryptが発行するTLS証明書を使用するには、ドメインをいずれかのGeoサイトに手動で割り当てて証明書を生成し、その後、その証明書を他のすべてのサイトにコピーします。
- [セカンダリサイトがプライマリサイトとは異なるURLを使用している](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site)場合、[SAMLを使用してセカンダリサイトにサインイン](replication/single_sign_on.md#saml-with-separate-url-with-proxying-enabled)するには、SAML Identity Provider（IdP）がアプリケーションに複数のコールバックURLを設定できる必要があります。
- セカンダリサイトに対してSSH経由でオプション`--depth`を指定してGitのクローンやフェッチリクエストを実行した場合、リクエスト開始時点でセカンダリサイトが最新の状態でなければ、処理が進行せず、無期限にハングします。これは、プロキシ処理中にGit SSHをGit HTTPSに変換する際に発生する問題が原因です。詳細については、[イシュー391980](https://gitlab.com/gitlab-org/gitlab/-/issues/391980)を参照してください。前述の変換処理を含まない新しいワークフローが、LinuxパッケージのGitLab Geoセカンダリサイトで使用できるようになりました。これは、機能フラグで有効にできます。詳細については、[イシュー454707のコメント](https://gitlab.com/gitlab-org/gitlab/-/issues/454707#note_2102067451)を参照してください。クラウドネイティブGitLab Geoセカンダリサイト向けの修正は、[イシュー5641](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5641)で追跡されています。
- 一部のお客様から、セカンダリサイトが最新の状態でない場合、SSH経由で`git fetch`を実行するとハングまたはタイムアウトして失敗すると報告されています。SSH経由での`git clone`リクエストには影響しません。詳細については、[イシュー454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707)を参照してください。LinuxパッケージのGitLab Geoセカンダリサイト向けには、この問題に対する修正が用意されており、機能フラグで有効にできます。詳細については、[イシュー454707のコメント](https://gitlab.com/gitlab-org/gitlab/-/issues/454707#note_2102067451)を参照してください。クラウドネイティブGitLab Geoセカンダリサイト向けの修正は、[イシュー5641](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5641)で追跡されています。
- [相対URL](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab) を[GitLab Geo](../../administration/geo/_index.md)で使用しないでください。サイト間のプロキシが中断されます。詳細については、[イシュー456427](https://gitlab.com/gitlab-org/gitlab/-/issues/456427)を参照してください。

### レプリケートされるデータタイプ {#replicated-data-types}

GitLabのすべての[データタイプ](replication/datatypes.md)と[レプリケート対象のデータタイプ](replication/datatypes.md#replicated-data-types)については、完全なリストがあります。

## インストール後の作業に関するドキュメント {#post-installation-documentation}

**セカンダリ**サイトにGitLabをインストールして初期設定を行ったら、インストール後の情報については次のドキュメントを参照してください。

### Geoをセットアップする {#setting-up-geo}

Geoの設定の詳細については、[Geoのセットアップ](setup/_index.md)を参照してください。

### Geoでオブジェクトストレージを使用する {#configuring-geo-with-object-storage}

Geoでオブジェクトストレージを使用するよう設定する方法については、[Geoとオブジェクトストレージ](replication/object_storage.md)を参照してください。

### コンテナレジストリをレプリケートする {#replicating-the-container-registry}

コンテナレジストリをレプリケートする方法の詳細については、[**セカンダリ**サイトのコンテナレジストリ](replication/container_registry.md)を参照してください。

### Geoサイトの統一されたURLを設定する {#set-up-a-unified-url-for-geo-sites}

AWS Route53やGoogle Cloud DNSを使用して、単一のロケーション認識型のURLを設定する方法の例については、[Geoサイトの統一されたURLを設定する](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)を参照してください。

### シングルサインオン（SSO） {#single-sign-on-sso}

シングルサインオン（SSO）の設定の詳細については、[Geoにおけるシングルサインオン（SSO）](replication/single_sign_on.md)を参照してください。

#### LDAP {#ldap}

LDAPの設定の詳細については、[Geoにおけるシングルサインオン（SSO）> LDAP](replication/single_sign_on.md#ldap)を参照してください。

### Geoを調整する {#tuning-geo}

Geoの調整の詳細については、[Geoの調整](replication/tuning.md)を参照してください。

### レプリケーションを一時停止および再開する {#pausing-and-resuming-replication}

詳細については、[レプリケーションの一時停止と再開](replication/pause_resume_replication.md)を参照してください。

### バックフィル {#backfill}

**セカンダリ**サイトをセットアップすると、**プライマリ**サイトから不足しているデータのレプリケートを開始します。このプロセスは**バックフィル**と呼ばれます。ブラウザで、**プライマリ**サイトの**Geoノード**ダッシュボードから、各Geoサイトの同期プロセスをモニタリングできます。

バックフィル中に発生したエラーは、バックフィルの最後に再試行するようスケジュールされます。

### Runner {#runners}

- 標準的な[Runnerフリート](https://docs.gitlab.com/runner/fleet_scaling/)のベストプラクティスに加えて、RunnerをGeoセカンダリサイトに接続するよう設定することで、ジョブの負荷を分散させることもできます。[セカンダリに対するRunnerの登録](secondary_proxy/runners.md)方法を参照してください。
- [Runner connectivity during failover](disaster_recovery/planned_failover.md#runner-connectivity-during-failover)（フェイルオーバー中のRunner接続）の処理方法も参照してください。

### Geoをアップグレードする {#upgrading-geo}

Geoサイトを最新のGitLabバージョンに更新する方法については、[Geoサイトをアップグレードする](replication/upgrading_the_geo_sites.md)を参照してください。

### セキュリティレビュー {#security-review}

Geoのセキュリティの詳細については、[Geoセキュリティレビュー](replication/security_review.md)を参照してください。

## Geoサイトを削除する {#remove-geo-site}

Geoサイトの削除の詳細については、[**セカンダリ**Geoサイトを削除する](replication/remove_geo_site.md)を参照してください。

## Geoを無効化する {#disable-geo}

Geoを無効にする方法については、[Geoを無効化する](replication/disable_geo.md)を参照してください。

## ログファイル {#log-files}

Geoは、構造化されたログメッセージを`geo.log`ファイルに保存します。

Geoのログへのアクセス方法と使用方法の詳細については、[ログシステムドキュメントのGeoのセクション](../logs/_index.md#geolog)を参照してください。

## ディザスターリカバリー {#disaster-recovery}

ディザスターリカバリーの状況でGeoを使用してデータ損失を軽減し、サービスを復元する方法の詳細については、[ディザスターリカバリー](disaster_recovery/_index.md)を参照してください。

## よくある質問 {#frequently-asked-questions}

一般的な質問への回答については、[GeoのFAQ](replication/faq.md)を参照してください。

## トラブルシューティング {#troubleshooting}

- Geoのトラブルシューティングの手順については、[Geoのトラブルシューティング](replication/troubleshooting/_index.md)を参照してください。

- ディザスタリカバリのトラブルシューティングの手順については、[Geoフェイルオーバーのトラブルシューティング](disaster_recovery/failover_troubleshooting.md)を参照してください。
