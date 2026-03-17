---
stage: Developer Experience
group: Performance Enablement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: パフォーマンスバー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パフォーマンスバーは、リアルタイムメトリクスをブラウザに直接表示し、ログを調べたり、個別のプロファイリングツールを実行したりすることなく、インサイトを提供します。

開発チームにとって、パフォーマンスバーは、どこに労力を集中すべきかを正確に示すことで、デバッグを簡素化します。

![パフォーマンスバー](img/performance_bar_v14_4.png)

## 利用可能な情報 {#available-information}

{{< history >}}

- RuggedコールはGitLab 16.6で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/421591)。

{{< /history >}}

左から右へ、パフォーマンスバーは以下を表示します:

- **Current Host**: ページを提供している現在のホスト。
- **Database queries**: データベースクエリにかかった時間（ミリ秒）と合計数で、`00ms / 00 (00 cached) pg`の形式で表示されます。詳細が記載されたダイアログを表示するには、選択します。各クエリについて、以下の詳細を確認できます:
  - **In a transaction**: トランザクションのコンテキストで実行された場合、クエリの下に表示されます。
  - **ロール**: [Databaseロードバランシング](../../postgresql/database_load_balancing.md)が有効な場合に表示されます。どのサーバーロールがクエリに使用されたかを表示します。「Primary」は、クエリが読み取り/書き込みプライマリサーバーに送信されたことを意味します。「Replica」は、読み取り専用レプリカに送信されたことを意味します。
  - **Configuration name**: これは、異なるGitLab機能用に設定された異なるデータベースを区別するために使用されます。表示される名前は、GitLabでデータベース接続を設定するために使用される名前と同じです。
- **Gitalyリクエスト**: [Gitaly](../../gitaly/_index.md)コールにかかった時間（ミリ秒）と合計数。詳細が記載されたダイアログを表示するには、選択します。
- **Redis呼び出し**: Redisコールにかかった時間（ミリ秒）と合計数。詳細が記載されたダイアログを表示するには、選択します。
- **Elasticsearchコール**: Elasticsearchコールにかかった時間（ミリ秒）と合計数。詳細が記載されたダイアログを表示するには、選択します。
- **External HTTP calls**: 他のシステムへの外部コールにかかった時間（ミリ秒）と合計数。詳細が記載されたダイアログを表示するには、選択します。
- ページの**Load timings**: ブラウザがロードタイミングをサポートしている場合、ミリ秒単位の値がスラッシュで区切られて表示されます。詳細が記載されたダイアログを表示するには、選択します。左から右への値:
  - **バックエンド**: ベースページの読み込みに必要な時間。
  - [**最初のコンテンツ描画**](https://developer.chrome.com/docs/lighthouse/performance/first-contentful-paint/): ユーザーに何かが表示されるまでの時間。ブラウザがこの機能をサポートしていない場合、`NaN`が表示されます。
  - [**DomContentLoaded**](https://web.dev/articles/critical-rendering-path/measure-crp)イベント。
  - ページが読み込まれた**Total number of requests**。
- **メモリ**: 選択されたリクエスト中に消費されたメモリ量と割り当てられたオブジェクト。選択すると、詳細が記載されたウィンドウが表示されます。
- **トレース**: Jaegerが統合されている場合、**トレース**は現在のリクエストの`correlation_id`を含むJaegerトレーシングページにリンクします。
- **+**: リクエストの詳細をパフォーマンスバーに追加するリンク。リクエストは、完全なURL（現在のユーザーとして認証済み）または`X-Request-Id`ヘッダーの値によって追加できます。
- **ダウンロード**: パフォーマンスバーレポートを生成するために使用されたraw JSONをダウンロードするリンク。
- **Memory Report**: 現在のURLのメモリプロファイリングレポートを生成するリンク。
- **Flamegraph**: 選択された[Stackprof mode](https://github.com/tmm1/stackprof#sampling)で現在のURLのフレームグラフを生成するリンク:
  - **ウォール**モードは、壁の時計の時間のすべての間隔をサンプリングします。間隔は`10100`マイクロ秒に設定されています。
  - **CPU**モードは、CPUアクティビティのすべての間隔をサンプリングします。間隔は`10100`マイクロ秒に設定されています。
  - **オブジェクト**モードはすべての間隔をサンプリングします。間隔は`100`アロケーションに設定されています。
- **Request Selector**: パフォーマンスバーの右側に表示される選択ボックスで、現在のページが開いている間に作成されたすべてのリクエストのこれらのメトリクスを表示できます。一意のURLごとに最初の2つのリクエストのみがキャプチャされます。
- **統計**: `GITLAB_PERFORMANCE_BAR_STATS_URL`環境変数が設定されている場合、このURLがバーに表示されます。GitLab.comでのみ使用されます。

> [!note]
> すべてのインジケーターがすべての環境で利用できるわけではありません。たとえば、メモリビューは[特定のパッチ](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/patches/ruby/2.7.4/thread-memory-allocations-2.7.patch)が適用されたRubyを実行する必要があります。[GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)を使用してGitLabをローカルで実行している場合、通常はそうではなく、メモリビューを使用できません。

## キーボードショートカット {#keyboard-shortcut}

[<kbd>p</kbd> + <kbd>b</kbd>キーボードショートカット](../../../user/shortcuts.md)を押して、パフォーマンスバーを表示し、もう一度押すと非表示にします。

非管理者がパフォーマンスバーを表示するには、[有効にする](#enable-the-performance-bar-for-non-administrators)必要があります。

## リクエスト警告 {#request-warnings}

事前定義された制限を超えるリクエストは、警告{{< icon name="warning" >}}アイコンと、メトリクスの横に説明が表示されます。この例では、Gitalyコールの期間がしきい値を超えました。

![Gitalyコールの期間がしきい値を超えました](img/performance_bar_gitaly_threshold_v12_4.png)

## 非管理者向けパフォーマンスバーを有効にする {#enable-the-performance-bar-for-non-administrators}

パフォーマンスバーは、非管理者に対してデフォルトで無効になっています。特定のグループに対して有効にするには:

1. 管理者アクセスを持つユーザーとしてサインインします。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **メトリクスとプロファイリング**を選択します。
1. **プロファイリング - パフォーマンスバー**を展開します。
1. **管理者以外のメンバーにパフォーマンスバーへのアクセスを許可する**を選択します。
1. **次のグループのメンバーにアクセスを許可する**フィールドで、パフォーマンスへのアクセスが許可されているグループの完全なパスを入力します。
1. **変更を保存**を選択します。
