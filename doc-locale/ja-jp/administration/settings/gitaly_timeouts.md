---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitalyタイムアウト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Gitaly](../gitaly/_index.md)は、設定可能なタイムアウトを2種類提供します:

- GitLabユーザーインターフェースを使用して設定された呼び出しタイムアウト。
- Gitaly設定ファイルを使用して設定されたネゴシエーションタイムアウト。

## 呼び出しタイムアウトを設定します {#configure-the-call-timeouts}

実行時間の長いGitaly呼び出しが不必要にリソースを消費しないように、以下の呼び出しタイムアウトを設定します。呼び出しタイムアウトを設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Gitalyタイムアウト**セクションを展開します。
1. 必要に応じて各タイムアウトを設定します。

### 利用可能な呼び出しタイムアウト {#available-call-timeouts}

Gitalyの操作ごとに異なる呼び出しタイムアウトを利用できます。

| タイムアウト | デフォルト    | 説明 |
|:--------|:-----------|:------------|
| デフォルト | 55秒 | ほとんどのGitaly呼び出しのタイムアウト（`git` `fetch`および`push`操作、またはSidekiqジョブには適用されません）。たとえば、リポジトリがディスク上に存在するかどうかの確認などです。これにより、ウェブリクエストで行われたGitalyの呼び出しが、リクエストタイムアウト全体を超えることがなくなります。これは、[ワーカータイムアウト](../operations/puma.md#change-the-worker-timeout)よりも短くする必要があります。これは、[Puma](../../install/requirements.md#puma)用に設定できます。Gitalyの呼び出しタイムアウトがワーカータイムアウトを超えると、ワーカーを強制終了しなくても済むように、ワーカータイムアウトの残りの時間が使用されます。 |
| Fast    | 10秒 | リクエストで使用される高速Gitaly操作のタイムアウト。複数回使用される場合もあります。たとえば、リポジトリがディスク上に存在するかどうかの確認などです。フェイルファスト操作がこのしきい値を超えると、ストレージシャードに問題が発生する可能性があります。フェイルファストは、GitLabインスタンスの安定性を維持するのに役立ちます。 |
| 中程度  | 30秒 | 高速である必要がある（リクエスト内にある可能性がある）が、リクエストで複数回使用しないことが望ましいGitaly操作のタイムアウト。たとえば、バイナリラージオブジェクトのロードなどです。デフォルトとFastの間に設定する必要があるタイムアウト。 |

## ネゴシエーションタイムアウトを設定します {#configure-the-negotiation-timeouts}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/5574)されました。

{{< /history >}}

ネゴシエーションタイムアウトの増加が必要になる場合があります:

- 特に大きなリポジトリの場合。
- これらのコマンドを並行して実行する場合。

ネゴシエーションタイムアウトは、以下に対して設定できます:

- `git-upload-pack(1)`。Gitalyノードが`git fetch`を実行すると呼び出すものです。
- `git-upload-archive(1)`。Gitalyノードが`git archive --remote`を実行すると呼び出すものです。

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

値には、Goの[`ParseDuration`](https://pkg.go.dev/time#ParseDuration)の形式を使用します。

これらのタイムアウトは、リモートGit操作の[negotiation phase](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation)にのみ影響し、転送全体には影響しません。
