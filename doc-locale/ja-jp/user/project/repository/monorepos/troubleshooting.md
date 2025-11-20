---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: モノレポのパフォーマンスのトラブルシューティング
---

モノレポに関するパフォーマンスの問題について、これらの提案を確認してください。

## `git clone`または`git fetch`の実行速度が遅い {#slowness-during-git-clone-or-git-fetch}

クローンとフェッチの速度が低下する主な原因がいくつかあります。

### CPU使用率が高い {#high-cpu-utilization}

GitalyノードのCPU使用率が高い場合は、[特定の値をフィルタリング](observability.md#cpu-and-memory)して、クローンで使用されているCPUの量を確認することもできます。

特に、`command.cpu_time_ms`フィールドは、クローンとフェッチによってどれだけのCPUが使用されているかを示すことができます。

ほとんどの場合、サーバーの負荷の大部分は`git-pack-objects`プロセスから生成され、これはクローンとフェッチ中に開始されます。モノレポは非常にビジー状態であることが多く、CI/CDシステムは多くのクローンおよびフェッチコマンドをサーバーに送信します。

CPU使用率が高いと、パフォーマンスが低下する一般的な原因となります。相互に排他的でない以下の原因が考えられます:

- [Gitalyが処理するにはクローンが多すぎる](#cause-too-many-large-clones)。
- [Gitalyクラスター (Praefect) での読み取り分散が不十分](#cause-poor-read-distribution)。

#### 原因: 大規模なクローンが多すぎる {#cause-too-many-large-clones}

Gitalyが処理するには、大規模なクローンが多すぎる可能性があります。Gitalyは、いくつかの要因により、対応に苦慮する可能性があります:

- リポジトリのサイズ。
- クローンとフェッチのボリューム。
- CPU容量の不足。

Gitalyが多数の大型クローンを処理できるようにするために、次のような最適化戦略を通じて、Gitalyサーバーの負荷を軽減する必要がある場合があります:

- [pack-objects-cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)をオンにして、`git-pack-objects`が行う必要のある作業を減らします。
- CI/CD設定の[Git戦略](_index.md#use-git-fetch-in-cicd-operations)を`clone`から`fetch`または`none`に変更します。
- テストで必要な場合を除き、[タグ付けのフェッチを停止](_index.md#change-git-fetch-behavior-with-flags)します。
- 可能な限り[シャロークローンを使用](_index.md#use-shallow-clones-and-filters-in-cicd-processes)してください。

もう1つのオプションは、GitalyサーバーのCPU容量を増やすことです。

#### 原因: 読み取り分散の不具合 {#cause-poor-read-distribution}

Gitalyクラスター（Praefect）での読み取り分散が不十分である可能性があります。

ほとんどの読み取りトラフィックがクラスター全体に分散される代わりに、プライマリGitalyノードに送信されているかどうかを確認するには、[読み取り分散Prometheusメトリクス](observability.md#read-distribution)を使用します。

セカンダリGitalyノードがあまりトラフィックを受信していない場合、セカンダリノードが常に同期していない可能性があります。この問題はモノレポで悪化します。

モノレポは、大規模でビジー状態であることがよくあります。これにより、2つの影響があります。まず、モノレポはプッシュされることが多く、多くのCIジョブが実行されています。ブランチの削除などの書き込み操作が、セカンダリノードへのプロキシ呼び出しに失敗する場合があります。これにより、セカンダリノードが最終的に追いつくように、Gitalyクラスター（Praefect）でレプリケーションジョブがトリガーされます。

レプリケーションジョブは基本的に、セカンダリノードからプライマリノードへの`git fetch`であり、モノレポは非常に大きいことが多いため、このフェッチには時間がかかることがあります。

前のレプリケーションジョブが完了する前に次の呼び出しが失敗し、これが繰り返し発生する場合、モノレポがセカンダリで常に遅れている状態になる可能性があります。これにより、すべてのトラフィックがプライマリノードに送信されます。

これらのプロキシされた書き込みの失敗の原因の1つは、Git `$GIT_DIR/packed-refs`ファイルに関する既知の問題です。ファイル内のエントリを削除するには、ファイルをロックする必要があります。これにより、同時削除が発生すると削除が失敗する競合状態が発生する可能性があります。

GitLabのエンジニアは、参照削除をバッチ処理しようとする軽減策を開発しました。

GitLabが参照削除をバッチ処理できるようにするには、次の[機能フラグ](../../../../administration/feature_flags/_index.md)をオンにします。これらの機能フラグを有効にするために、ダウンタイムは必要ありません。

- `merge_request_cleanup_ref_worker_async`
- `pipeline_cleanup_ref_worker_async`
- `pipeline_delete_gitaly_refs_in_batches`
- `merge_request_delete_gitaly_refs_in_batches`

[エピック4220](https://gitlab.com/groups/gitlab-org/-/epics/4220)は、長期的なソリューションと見なされている、GitLabでのreftableサポートの追加を提案しています。
