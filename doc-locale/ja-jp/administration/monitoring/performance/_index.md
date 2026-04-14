---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: GitLabパフォーマンスモニタリング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabパフォーマンスモニタリングを使用して、パフォーマンスのボトルネックがユーザーに影響を与える前に検出します。レスポンス時間の遅延やメモリの問題が発生した場合、SQLクエリ、Ruby処理、およびシステムリソースに関する詳細なメトリクスを通じて、その正確な原因を特定できます。

パフォーマンスモニタリングを実装する管理者は、インスタンス全体の問題に発展する前に、潜在的な問題に対する即時アラートを受け取ることができます。トランザクション時間、クエリ実行パフォーマンス、およびメモリ使用量を追跡することで、組織にとって最適なGitLabパフォーマンスを維持できます。

GitLabパフォーマンスモニタリングの設定方法の詳細については、以下を参照してください:

- [Prometheusドキュメント](../prometheus/_index.md)。
- [Grafana設定](grafana_configuration.md)。
- [パフォーマンスバー](performance_bar.md)。

2種類のメトリクスが収集されます:

1. トランザクション固有のメトリクス。
1. サンプリングされたメトリクス。

## トランザクションメトリクス {#transaction-metrics}

トランザクションメトリクスは、単一のトランザクションに関連付けることができるメトリクスです。これには、トランザクション期間、実行されたSQLクエリのタイミング、HAMLビューのレンダリングに費やされた時間などの統計が含まれます。これらのメトリクスは、処理されたすべてのRackリクエストとSidekiqジョブに対して収集されます。

## サンプリングされたメトリクス {#sampled-metrics}

サンプリングされたメトリクスは、単一のトランザクションに関連付けることができないメトリクスです。例としては、ガベージコレクションの統計情報や、保持されているRubyオブジェクトが挙げられます。これらのメトリクスは、定期的な間隔で収集されます。この間隔は2つの部分で構成されています:

1. ユーザー定義の間隔。
1. 間隔にランダムに生成されたオフセットが追加され、同じオフセットは連続して2回使用できません。

実際の間隔は、定義された間隔の半分から間隔の半分を超えるまでのどこかにすることができます。たとえば、ユーザー定義の間隔が15秒の場合、実際の間隔は7.5から22.5の間のどこかになります。この間隔は、一度生成されてプロセスのライフタイム全体で再利用されるのではなく、サンプリング実行ごとに再生成されます。

ユーザー定義の間隔は、環境変数によって指定できます。以下の環境変数が認識されます:

- `RUBY_SAMPLER_INTERVAL_SECONDS`
- `DATABASE_SAMPLER_INTERVAL_SECONDS`
- `ACTION_CABLE_SAMPLER_INTERVAL_SECONDS`
- `PUMA_SAMPLER_INTERVAL_SECONDS`
- `THREADS_SAMPLER_INTERVAL_SECONDS`
- `GLOBAL_SEARCH_SAMPLER_INTERVAL_SECONDS`
