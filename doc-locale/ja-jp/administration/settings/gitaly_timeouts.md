---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitalyタイムアウトとリトライ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Gitaly](../gitaly/_index.md)は、設定可能な2種類のタイムアウトを提供します:

- GitLabのUIを使用して設定される呼び出しタイムアウト。
- Gitalyの設定ファイルを使用して設定されるネゴシエーションタイムアウト。

## 呼び出しタイムアウトの設定 {#configure-the-call-timeouts}

長時間実行されるGitalyの呼び出しが不必要にリソースを占有しないように、以下の呼び出しタイムアウトを設定します。

前提条件: 

- 管理者アクセス権。

呼び出しタイムアウトを設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **設定**を選択します。
1. **Gitalyタイムアウト**セクションを展開します。
1. 必要に応じて各タイムアウトを設定します。

### 利用可能な呼び出しタイムアウト {#available-call-timeouts}

異なるGitaly操作に対して、異なる呼び出しタイムアウトが利用可能です。

| タイムアウト | デフォルト    | 説明 |
|:--------|:-----------|:------------|
| デフォルト | 55秒 | ほとんどのGitaly呼び出しに対するタイムアウト（`git` `fetch`および`push`操作、またはSidekiqジョブには適用されません）。例えば、リポジトリがディスク上に存在するかどうかを確認する場合などです。Webリクエストで行われたGitaly呼び出しが、リクエスト全体のタイムアウトを超えないようにします。[Puma](../../install/requirements.md#puma)用に設定できる[ワーカータイムアウト](../operations/puma.md#change-the-worker-timeout)よりも短くする必要があります。Gitalyの呼び出しタイムアウトがワーカータイムアウトを超えた場合、ワーカーを終了する必要がないように、ワーカータイムアウトの残り時間が使用されます。 |
| 高速    | 10秒 | リクエストで複数回使用されることもある高速なGitaly操作のタイムアウト。例えば、リポジトリがディスク上に存在するかどうかを確認する場合などです。高速な操作がこのしきい値を超えると、ストレージシャードに問題がある可能性があります。フェイルファストは、GitLabインスタンスの安定性を維持するのに役立ちます。 |
| 中程度  | 30秒 | 高速であるべきGitaly操作（リクエスト内で発生する可能性あり）で、できればリクエスト内で複数回使用されない場合のタイムアウト。例えば、blobを読み込む場合などです。デフォルトと高速の間に設定されるべきタイムアウト。 |

デフォルトでは、**デフォルト**のタイムアウトを`57`秒より高く設定することはできません。詳細については、[Gitalyのデフォルトタイムアウトを57秒より高くできない](#unable-to-raise-gitaly-default-timeout-above-57-seconds)を参照してください。

## ネゴシエーションタイムアウトの設定 {#configure-the-negotiation-timeouts}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/5574)されました。

{{< /history >}}

ネゴシエーションタイムアウトを増やす必要がある場合があります:

- 特に大きなリポジトリの場合。
- これらのコマンドを並行して実行する場合。

ネゴシエーションタイムアウトは、以下に対して設定できます:

- `git-upload-pack(1)`。`git fetch`を実行すると、Gitalyノードによって呼び出されます。
- `git-upload-archive(1)`。`git archive --remote`を実行すると、Gitalyノードによって呼び出されます。

これらのタイムアウトを設定するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集します:

```ruby
gitaly['configuration'] = {
    timeout: {
        upload_pack_negotiation: '10m',      # 10 minutes
        upload_archive_negotiation: '20m',   # 20 minutes
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集します:

```toml
[timeout]
upload_pack_negotiation = "10m"
upload_archive_negotiation = "20m"
```

{{< /tab >}}

{{< /tabs >}}

値には、Goにおける[`ParseDuration`](https://pkg.go.dev/time#ParseDuration)の形式を使用します。

これらのタイムアウトは、リモートGit操作の[ネゴシエーションフェーズ](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation)のみに影響し、転送全体には影響しません。

## Gitalyクライアントのリトライ {#gitaly-client-retries}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/work_items/811)されました。

{{< /history >}}

Gitalyが一時的に利用できなくなることがあります。例えば、GitLabのアップグレード中などです。特にKubernetes上のGitalyでは、ポッドの起動と再起動に数秒かかる場合があります。

GitLabが一時的に利用できない場合にクライアントにエラーを返すのを防ぐため、Gitalyクライアントのリトライを設定します。Gitalyクライアントのリトライが設定されており、Gitalyが利用できない場合、Rails (GitLabアプリケーション)、Workhorse、GitLab ShellなどのGitalyクライアントは、指数関数的なバックオフ方式でリクエストをリトライします。

2つのパラメータを設定できます:

- `max_attempts`: 2から5の間の最大リトライ試行回数。
- `max_backoff`: クライアントがリトライを停止するまでの最大時間。値は、`1.4s`または`10s`のような期間文字列である必要があります。

バックオフ乗数は`2`に設定され、初期バックオフは2つのパラメータから導出されます。

### 設定ガイドライン {#configuration-guidelines}

適切な設定は、GitLabインスタンスの設定と、そのようなイベントが発生した際にGitalyが利用できない期間によって異なります:

- Kubernetes上では、Gitalyポッドの起動には、クラウドプロバイダーによって約10～12秒かかる場合があります。この時間には、ポッドにボリュームがアタッチおよびマウントされるまでの時間が含まれます。
- Linuxパッケージインスタンスの場合、Gitalyの再起動はプロセス再起動であるため、Gitalyははるかに速く再起動する可能性があります。

また、Gitalyはグレースフルシャットダウンタイムアウトを設定できることも念頭に置いてください。Gitalyがシャットダウンしている間、新しいリクエストは拒否されますが、gRPCサーバーは以下のいずれかになるまで進行中のリクエストを処理し続けます:

- すべて処理されます。
- シャットダウンタイムアウトが経過します。

このグレースフルシャットダウンタイムアウトは、新しいリクエストに対してGitalyが利用できない期間に影響を与える可能性があります。

クライアントリトライを`max_backoff`で設定する必要があります。これは、グレースフルシャットダウンと（再）起動時間の合計以上です。

### クライアントリトライの設定 {#configure-client-retries}

以下の設定は、Rails (GitLabアプリケーション)、Workhorse、およびGitLab Shellに適用され、同じ設定がすべてのクライアントに適用されます。

提供される値は例であり、ガイドラインとして扱わないでください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

これらの設定で`gitlab.rb`ファイルを更新します:

```ruby
gitlab_rails['gitaly_client_max_attempts'] = 5
gitlab_rails['gitaly_client_max_backoff'] = '1.4s'
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

これらの設定で`values.yml`ファイルを更新します:

```yaml
global:
  gitaly:
    client:
      maxAttempts: 5
      maxBackoff: '1.4s'
```

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

Gitalyタイムアウトで作業する際に、以下の問題に遭遇する可能性があります。

### Gitalyのデフォルトタイムアウトを57秒より高くできない {#unable-to-raise-gitaly-default-timeout-above-57-seconds}

> [!warning]
> 必要な場合にのみこれらの値を上げてください。ワーカータイムアウトが高いほど、低速または停止したリクエストがPumaワーカーをより長く保持し、インスタンスの容量を削減します。Gitalyの**デフォルト**タイムアウトを上げる一般的な理由としては、低速なストレージ上の非常に大きなリポジトリ、高コストな差分または比較ビュー、または劣化したGitalyクラスターノードなどが挙げられます。インポート、ミラー、またはハウスキーピングなどのバックグラウンド作業の場合、この上限に制約されないSidekiqへのオフロードを推奨します。

デフォルトでは、[**デフォルト**のタイムアウト](#available-call-timeouts)を`57`秒より高くすることはできません。タイムアウトを高く設定しようとすると、以下の検証エラーが発生します:

```plaintext
Gitaly timeout default must be less than or equal to 57
```

この制限は、相互作用する3つのタイムアウトによって課せられます:

- `puma['worker_timeout']`: ワーカーごとのPumaタイムアウト。デフォルトは`60`秒です。詳細については、[ワーカータイムアウトの変更](../operations/puma.md#change-the-worker-timeout)を参照してください。
- `gitlab_rails['max_request_duration_seconds']`#GitLabアプリケーション設定。Gitaly**デフォルト**タイムアウトを制限します。デフォルトは`(worker_timeout * 0.95).ceil` = `57`秒です。この設定は、`puma['worker_timeout']`より厳密に小さい必要があります。
- `GITLAB_RAILS_RACK_TIMEOUT`: `Rack::Timeout`ミドルウェア`service_timeout`。デフォルトは`60`秒です。このタイムアウトは他の2つとは独立しており、他の設定にかかわらず、この値でリクエストを終了します。

Gitalyの**デフォルト**タイムアウトを57秒より高くするには、3つの値をすべて一緒に上げる必要があります。例えば、Gitalyの**デフォルト**タイムアウトを`110`秒にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   puma['worker_timeout'] = 120
   gitlab_rails['max_request_duration_seconds'] = 114
   gitlab_rails['env'] = {
     'GITLAB_RAILS_RACK_TIMEOUT' => 120
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **設定**を選択します。
1. **Gitalyタイムアウト**を展開します。
1. **デフォルトのタイムアウト**を新しい希望する値に設定します（最大`max_request_duration_seconds`）。

   小さなヘッドルームを残しておくことを推奨します。組み込みのデフォルトでは5%のギャップ（`max_request_duration_seconds = (worker_timeout * 0.95).ceil`）を使用しているため、Pumaがワーカータイムアウトに達する前にRailsリクエストの期限がトリガーされます。

   `GITLAB_RAILS_RACK_TIMEOUT`自体はGitalyの上限を上げません。`Settings.gitlab.max_request_duration_seconds`はアプリケーション設定検証ツールが参照するものであり、`gitlab_rails['max_request_duration_seconds']`によって設定されます。ただし、`GITLAB_RAILS_RACK_TIMEOUT`を`60`のデフォルトのままにしておくと、Rackミドルウェアは、完了する前に、長時間のGitaly呼び出しを含む60秒を超えるすべてのリクエストを終了させます。
