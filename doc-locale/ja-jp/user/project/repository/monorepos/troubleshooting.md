---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: トラブルシューティングモノレポのパフォーマンス
---

モノレポのパフォーマンス問題について、これらの提案を確認してください。

## `git clone`または`git fetch`中の遅延 {#slowness-during-git-clone-or-git-fetch}

クローンとフェッチにおける遅延の主な原因がいくつかあります。

### 高いCPU使用率 {#high-cpu-utilization}

GitalyノードのCPU使用率が高い場合、[特定の値をフィルタリングして](observability.md#cpu-and-memory)クローンによって消費されるCPU量をチェックすることもできます。

特に、`command.cpu_time_ms`フィールドは、クローンとフェッチによってどれくらいのCPUが消費されているかを示します。

ほとんどの場合、サーバー負荷の大部分は、クローンとフェッチ中に開始される`git-pack-objects`プロセスから生成されます。モノレポは非常に頻繁に使用され、CI/CDシステムは多くのクローンおよびフェッチコマンドをサーバーに送信します。

高いCPU使用率は、パフォーマンス低下の一般的な原因です。以下の相互排他的ではない原因が考えられます:

- [Gitalyが処理するにはクローンが多すぎる](#cause-too-many-large-clones)。
- [Gitalyクラスター (Praefect) における読み取り分散の不備](#cause-poor-read-distribution)。

#### 原因: 大規模なクローンが多すぎる {#cause-too-many-large-clones}

Gitalyが処理するには、大規模なクローンが多すぎる可能性があります。Gitalyは、いくつかの要因により対応が困難になることがあります:

- リポジトリのサイズ。
- クローンとフェッチの量。
- CPU容量の不足。

Gitalyが多数の大規模なクローンを処理できるようにするには、以下のような最適化戦略によってGitalyサーバーへの負荷を軽減する必要があるかもしれません:

- `git-pack-objects`の作業を減らすには、[パックオブジェクトキャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)をオンにします。
- CI/CD設定で[Git戦略](_index.md#use-git-fetch-in-cicd-operations)を`clone`から`fetch`または`none`に変更します。
- テストで必要な場合を除き、[タグのフェッチを停止します](_index.md#change-git-fetch-behavior-with-flags)。
- 可能な限り[シャロークローンを使用](_index.md#use-shallow-clones-and-filters-in-cicd-processes)します。

もう1つの選択肢は、GitalyサーバーのCPU容量を増やすことです。

#### 原因: 読み取り分散の不備 {#cause-poor-read-distribution}

Gitalyクラスター (Praefect) における読み取り分散が不十分な場合があります。

ほとんどの読み取りトラフィックがクラスター全体に分散されずにプライマリGitalyノードに向かっているかどうかを観察するには、[読み取り分散Prometheusメトリクス](observability.md#read-distribution)を使用します。

セカンダリGitalyノードが多くのトラフィックを受信していない場合、セカンダリノードが永続的に同期が取れていない可能性があります。この問題はモノレポで悪化します。

モノレポは、大規模で頻繁に使用される傾向があります。これは2つの影響をもたらします。まず、モノレポには頻繁にプッシュされ、多くのCIジョブが実行されています。ブランチの削除などの書き込み操作が、セカンダリノードへのプロキシ呼び出しを失敗させることがあります。これにより、Gitalyクラスター (Praefect) でレプリケーションジョブがトリガーされ、セカンダリノードはいずれ追いつきます。

レプリケーションジョブは、本質的にセカンダリノードからプライマリノードへの`git fetch`であり、モノレポは非常に大規模であるため、このフェッチには長い時間がかかることがあります。

前のレプリケーションジョブが完了する前に次の呼び出しが失敗し、これが継続的に発生する場合、モノレポのセカンダリが常に遅れている状態になる可能性があります。これにより、すべてのトラフィックがプライマリノードに送られます。

これらの失敗したプロキシ書き込みの1つの理由は、Git `$GIT_DIR/packed-refs`ファイルに関する既知の問題です。ファイルをロックしてファイル内のエントリを削除する必要がありますが、これにより競合状態が発生し、同時削除が発生した場合に削除が失敗する可能性があります。

GitLabのエンジニアは、参照削除をバッチ処理する軽減策を開発しました。

GitLabが参照削除をバッチ処理できるように、以下の[機能フラグ](../../../../administration/feature_flags/_index.md)をオンにします。これらの機能フラグを有効にするためにダウンタイムは必要ありません。

- `merge_request_cleanup_ref_worker_async`
- `pipeline_cleanup_ref_worker_async`
- `pipeline_delete_gitaly_refs_in_batches`
- `merge_request_delete_gitaly_refs_in_batches`

[エピック4220](https://gitlab.com/groups/gitlab-org/-/epics/4220)は、GitLabにreftableサポートを追加することを提案しており、これは長期的なソリューションと見なされています。
