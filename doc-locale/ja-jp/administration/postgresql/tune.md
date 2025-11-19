---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PostgreSQLを調整する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

PostgreSQLを調整する必要がある場合:

- 他のGitLabコンポーネントが再構成されたり、データベースに影響を与える方法でスケールアップされたりした場合。
- GitLab環境のパフォーマンスが低下している。
- GitLabが[外部PostgreSQLサービス](external.md)を使用している。

GitLabに必要な[必要なPostgreSQL設定](../../install/requirements.md#postgresql-settings)と組み合わせて、この情報を使用してください。

## データベース接続を計画する {#plan-your-database-connections}

{{< alert type="note" >}}

GitLabのバージョン16.0以降では、`main`テーブルと`ci`テーブル用に[2組のデータベース接続](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)を使用します。これにより、同じPostgreSQLデータベースが両方のテーブルセットを提供している場合でも、接続の使用量が2倍になります。

{{< /alert >}}

GitLabは、複数のコンポーネントからのデータベース接続を使用します。適切な接続計画により、データベース接続の枯渇やパフォーマンスの問題を防ぐことができます。

各GitLabコンポーネントは、その設定に基づいてデータベース接続を使用します。SidekiqとPumaは、初期化時にPostgreSQLへのプール接続を確立します。プール内の接続数は、接続スパイクが発生した場合、または需要が一時的に増加した場合に後で増加する可能性があります:

- 環境変数`DB_POOL_HEADROOM`を使用して、データベースプールのヘッドルームを構成します。
- PostgreSQLを調整する際は、プールのヘッドルームを計画しますが、変更はしないでください。より多くの容量を利用できる場合、GitLabデプロイはより高い要求に対応します。SidekiqまたはPumaのワーカーをさらにデプロイします。

### Puma {#puma}

```plaintext
Puma connections = puma['worker_processes'] × (puma['max_threads'] + DB_POOL_HEADROOM)
```

デフォルトでは次のようになります:

- `puma['worker_processes']`は仮想CPUコア数に基づいています。
- `puma['max_threads']`は`4`に等しい。
- `DB_POOL_HEADROOM`は`10`に等しい。

ワーカーごとの計算: 各Pumaワーカーは、4つのスレッド + 10のヘッドルームを使用し、合計14の接続になります。

8つの仮想CPUを想定したデフォルト計算: 8ワーカー × ワーカーあたり14接続で、合計112のPuma接続になります。

### Sidekiq {#sidekiq}

```plaintext
Sidekiq connections = Number of Sidekiq processes × (sidekiq['concurrency'] + 1 + DB_POOL_HEADROOM)
```

デフォルトでは次のようになります:

- Sidekiqプロセスの数は`1`です。
- `sidekiq['concurrency']`は`20`に等しい。
- `DB_POOL_HEADROOM`は`10`に等しい。

デフォルト計算: 1つのSidekiqプロセス × (20並行処理 + 1 + 10ヘッドルーム) で、合計31のSidekiq接続になります。

### Geoログカーソル(Geoインストールのみ) {#geo-log-cursor-geo-installations-only}

[Geoログカーソル](../../development/geo.md#geo-log-cursor-daemon)デーモンは、セカンダリサイト内のすべてのGitLab Railsノードで実行されます。

```plaintext
Geo log cursor connections = 1 + DB_POOL_HEADROOM
```

デフォルト計算: 1 + 10ヘッドルームで、合計11のGeo接続になります。

### 総接続要件 {#total-connection-requirements}

単一ノードインストールの場合:

```plaintext
Total connections = 2 × (Puma + Sidekiq + Geo)
```

マルチノードインストールの場合、各コンポーネントを実行しているノードの数を掛けます:

```plaintext
Total connections = 2 × ((Puma × Rails nodes) + (Sidekiq × Sidekiq nodes) + (Geo × secondary Rails nodes))
```

2を掛けることは、GitLab 16.0以降の[デュアルデータベース接続](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)を考慮に入れています。

Geoインストールの場合:

- プライマリサイト: `Geo = 0`を使用してください。Geoログカーソルは、プライマリサイトでは実行されません。
- セカンダリサイト: 1つのセカンダリサイトのGeoログカーソルのデータベース接続を計算し、同じ計算をすべてのセカンダリサイトに適用します。
- 各Geoサイトは独自のデータベースに接続するため、複数のGeoサイト間で接続を合計する必要はありません。
- `max_connections`を、プライマリPostgreSQLデータベースとすべてのレプリカデータベースの両方で同じ値に設定し、すべてのGeoサイトで最も高い接続要件を使用します。

### 例 {#examples}

#### 単一ノードインストール {#single-node-installation}

この例は、[20 RPS (1秒あたりのリクエスト数) または1000ユーザー](../reference_architectures/1k_users.md)のGitLabリファレンスアーキテクチャに基づいています:

| コンポーネント | ノード | 設定             | コンポーネントごとの接続数 | コンポーネントの合計、デュアルデータベース |
|-----------|-------|---------------------------|---------------------------|---------------------------------|
| Puma      | 1     | 8ワーカー、各4スレッド | ワーカーあたり14             | 224                             |
| Sidekiq   | 1     | 1プロセス、20並行処理 | プロセスあたり31            | 62                              |
| 合計     |       |                           |                           | 286                             |

#### マルチノードインストール {#multi-node-installation}

この例は、[40 RPS (1秒あたりのリクエスト数) または2000ユーザー](../reference_architectures/2k_users.md)のGitLabリファレンスアーキテクチャに基づいています:

| コンポーネント | ノード | 設定                      | コンポーネントごとの接続数 | コンポーネントの合計、デュアルデータベース |
|-----------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma      | 2     | ノードあたり8ワーカー、各4スレッド | ワーカーあたり14             | 448                            |
| Sidekiq   | 1     | 4プロセス、各20並行処理   | プロセスあたり31            | 248                            |
| 合計     |       |                                    |                           | 696                            |

#### Geoを使用した単一ノードインストール {#single-node-installation-with-geo}

この例は、[20 RPS (1秒あたりのリクエスト数) または1000ユーザー](../reference_architectures/1k_users.md)のGitLabリファレンスアーキテクチャに基づいています。

| Geoサイトごとのコンポーネント                | ノード | 設定             | コンポーネントごとの接続数 | コンポーネントの合計、デュアルデータベース |
|---------------------------------------|-------|---------------------------|---------------------------|--------------------------------|
| Puma                                  | 1     | 8ワーカー、各4スレッド | ワーカーあたり14             | 224                            |
| Sidekiq                               | 1     | 1プロセス、20並行処理 | プロセスあたり31            | 62                             |
| Geoログカーソル(セカンダリサイトのみ) | 1     | 1プロセス                 | プロセスあたり11            | 22                             |
| 合計                                 |       |                           |                           | 308                            |

#### Geoを使用したマルチノードインストール {#multi-node-installation-with-geo}

この例は、[40 RPS (1秒あたりのリクエスト数) または2000ユーザー](../reference_architectures/2k_users.md)のGitLabリファレンスアーキテクチャに基づいています:

| Geoサイトごとのコンポーネント                | ノード | 設定                      | コンポーネントごとの接続数 | コンポーネントの合計、デュアルデータベース |
|---------------------------------------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma                                  | 2     | ノードあたり8ワーカー、各4スレッド | ワーカーあたり14             | 448                            |
| Sidekiq                               | 1     | 4プロセス、各20並行処理   | プロセスあたり31            | 248                            |
| Geoログカーソル(セカンダリサイトのみ) | 2     | Railsノードごとに1つのプロセス           | プロセスあたり11            | 44                             |
| 合計                                 |       |                                    |                           | 740                            |
