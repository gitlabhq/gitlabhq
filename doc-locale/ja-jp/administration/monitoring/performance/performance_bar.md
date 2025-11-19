---
stage: Developer Experience
group: Performance Enablement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: パフォーマンスバー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パフォーマンスバーにはリアルタイムのメトリクスがブラウザに直接表示されるため、ログを調べたり、個別のプロファイリングツールを実行したりしなくても、インサイトを得ることができます。

開発チームにとって、パフォーマンスバーは、どこに力を入れるべきかを正確に示すことで、デバッグを簡素化します。

![パフォーマンスバー](img/performance_bar_v14_4.png)

## 利用可能な情報 {#available-information}

{{< history >}}

- GitLab 16.6でRugged [削除](https://gitlab.com/gitlab-org/gitlab/-/issues/421591)されました。

{{< /history >}}

パフォーマンスバーには、左から右に以下の内容が表示されます:

- **Current Host**（現在のホスト）: ページを読み込む現在のホスト。
- **Database queries**（データベースクエリ）: 時間（ミリ秒）とデータベースクエリの合計数。`00ms / 00 (00 cached) pg`形式で表示されます。詳細を表示するには、モーダルウィンドウを選択します。これを使用して、各クエリに関する次の詳細を表示できます:
  - **In a transaction**（トランザクション内）: クエリがトランザクションのコンテキストで実行された場合、クエリの下に表示されます
  - **ロール**: [ロードバランシング](../../postgresql/database_load_balancing.md)が有効になっている場合に表示されます。どのサーバーロールがクエリに使用されたかを示します。「プライマリ」は、クエリが読み取り/書き込みプライマリサーバーに送信されたことを意味します。「レプリカ」は、読み取り専用レプリカに送信されたことを意味します。
  - **Configuration name**（設定名）: これは、異なるGitLab機能用に設定された異なるデータベースを区別するために使用されます。表示される名前は、GitLabでデータベース接続を設定するために使用される名前と同じです。
- **Gitalyリクエスト**: [Gitaly](../../gitaly/_index.md)の呼び出しにかかる時間（ミリ秒）と合計数。詳細を表示するには、モーダルウィンドウを選択します。
- **Redis呼び出し**: Redis呼び出しにかかる時間（ミリ秒）と合計数。詳細を表示するには、モーダルウィンドウを選択します。
- **Elasticsearchコール**: Elasticsearch呼び出しにかかる時間（ミリ秒）と合計数。詳細を表示するには、モーダルウィンドウを選択します。
- **External HTTP calls**（外部HTTP呼び出し）: 他のシステムへの外部呼び出しにかかる時間（ミリ秒）と合計数。詳細を表示するには、モーダルウィンドウを選択します。
- ページの**Load timings**（読み込み時間）: ブラウザが読み込み時間をサポートしている場合、ミリ秒単位の複数の値がスラッシュで区切られます。詳細を表示するには、モーダルウィンドウを選択します。左から右への値:
  - **バックエンド**: ベースページが読み込むのに必要な時間。
  - [**最初のコンテンツ描画**](https://developer.chrome.com/docs/lighthouse/performance/first-contentful-paint/): 何かがユーザーに表示されるまでの時間。ブラウザがこの機能をサポートしていない場合、`NaN`が表示されます。
  - [**DomContentLoaded**](https://web.dev/articles/critical-rendering-path/measure-crp)イベント。
  - ページが読み込んだ**Total number of requests**（リクエストの合計数）。
- **メモリ**: 選択したリクエスト中に消費されたメモリ量と割り当てられたオブジェクト。詳細を表示するには、それを選択します。
- **トレース**: Jaegerが統合されている場合、**トレース**は、現在のリクエストの`correlation_id`を含むJaegerトレーシングページにリンクします。
- **+**（+）: リクエストの詳細をパフォーマンスバーに追加するためのリンク。リクエストは、その完全なURL（現在のユーザーとして認証）またはその`X-Request-Id`ヘッダーの値で追加できます。
- **ダウンロード**: パフォーマンスバーレポートの生成に使用されるraw JSONをダウンロードするためのリンク。
- **Memory Report**（メモリレポート）: 現在のURLのメモリプロファイリングレポートを生成するリンク。
- **Flamegraph**（Flamegraph）とモード: 選択した[Stackprof mode](https://github.com/tmm1/stackprof#sampling)で現在のURLのflamegraphを生成するリンク:
  - **ウォール**モードは、ウォールの時計の時間の間隔ごとにサンプルを呼び出します。間隔は`10100`マイクロ秒に設定されています。
  - **CPU**モードは、CPUアクティビティーの間隔ごとにサンプルを呼び出します。間隔は`10100`マイクロ秒に設定されています。
  - **オブジェクト**モードは、間隔ごとにサンプルを呼び出します。間隔は`100`割り当てに設定されています。
- **Request Selector**（リクエストセレクター）: 現在のページが開いている間に作成されたリクエストのこれらのメトリクスを表示できる、パフォーマンスバーの右側に表示されるセレクトボックス。一意のURLごとに最初の2つのリクエストのみがキャプチャされます。
- **統計**: `GITLAB_PERFORMANCE_BAR_STATS_URL`環境変数が設定されている場合、このURLがバーに表示されます。GitLab.comでのみ使用されます。

{{< alert type="note" >}}

すべてのインジケーターがすべての環境で使用できるわけではありません。たとえば、メモリビューでは、[特定のパッチ](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/patches/ruby/2.7.4/thread-memory-allocations-2.7.patch)を適用したRubyを実行する必要があります。[GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)を使用してGitLabをローカルで実行する場合、通常はそうではなく、メモリビューは使用できません。

{{< /alert >}}

## キーボードショートカット {#keyboard-shortcut}

[<kbd>p</kbd> + <kbd>b</kbd>キーボードショートカット](../../../user/shortcuts.md)を押して、パフォーマンスバーを表示し、もう一度押すと非表示になります。

管理者以外のメンバーがパフォーマンスバーを表示するには、[それらを有効にする](#enable-the-performance-bar-for-non-administrators)必要があります。

## リクエストの警告 {#request-warnings}

定義済みの制限を超えるリクエストは、メトリクスの横に警告{{< icon name="warning" >}}アイコンと説明を表示します。この例では、Gitaly呼び出しの継続時間がしきい値を超えています。

![Gitaly呼び出し時間がしきい値を超えました](img/performance_bar_gitaly_threshold_v12_4.png)

## 管理者以外のメンバーにパフォーマンスバーを有効にする {#enable-the-performance-bar-for-non-administrators}

パフォーマンスバーは、デフォルトでは管理者以外のメンバーに対して無効になっています。特定のグループに対して有効にするには:

1. 管理者アクセス権を持つユーザーとしてサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **メトリクスとプロファイリング**を選択します。
1. **プロファイリング - パフォーマンスバー**を展開します。
1. **管理者以外のメンバーにパフォーマンスバーへのアクセスを許可する**を選択します。
1. **次のグループのメンバーにアクセスを許可する**フィールドに、パフォーマンスバーへのアクセスを許可するグループのフルパスを入力します。
1. **変更を保存**を選択します。
