---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イベントデータ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11で[enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)を切り替えます。

{{< /history >}}

## イベントレベルでの製品使用状況のデータ追跡 {#data-tracking-for-product-usage-at-event-level}

製品使用状況データ収集の変更に関する詳細は、ブログ記事[GitLab Self-ManagedおよびDedicated向けのより詳細な製品使用状況インサイト](https://about.gitlab.com/blog/2025/03/26/more-granular-product-usage-insights-for-gitlab-self-managed-and-dedicated/)をご覧ください。

### イベントデータ {#event-data}

イベントデータは、GitLabプラットフォーム内のインタラクション（またはアクション）を追跡します。これらのインタラクションまたはアクションは、CI/CDパイプラインの開始、マージリクエストのマージ、Webhookのトリガー、イシューの作成など、ユーザーが開始したものである可能性があります。アクションは、スケジュールされたパイプラインの成功など、バックグラウンドシステムの処理によって生じることもあります。イベントデータ収集の焦点は、ユーザーのアクションとそれらのアクションに関連付けられたメタデータにあります。

ユーザーIDはプライバシーを保護するために仮名化されており、GitLabは、メトリクスを個々のユーザーと再識別または関連付ける処理を行いません。イベントデータには、ソースコードや、GitLab内に保存されているその他のお客様が作成したコンテンツは含まれていません。

詳細については、以下も参照してください:

- イベントとメトリクスのリストについては、[メトリクスディクショナリ](https://metrics.gitlab.com/?status=active)をご覧ください
- [お客様の製品使用に関する情報](https://handbook.gitlab.com/handbook/legal/privacy/customer-product-usage-information/)

### イベントデータの利点 {#benefits-of-event-data}

イベントレベルのデータは、ユーザーを特定せずに、より詳細なインサイトを提供することで、Service Pingのいくつかの利点を強化します。

- プロアクティブサポート: 詳細データにより、当社のカスタマーサクセスマネージャー（CSM）とサポートチームは、より詳細な情報にアクセスでき、より一般的な集約されたメトリクスに依存するのではなく、組織固有のニーズに合わせて調整されたカスタムメトリクスをドリルダウンして作成できます。
- 対象を絞ったガイダンス: イベントレベルのデータは、機能の使用方法についてのより深い理解を提供し、最適化と改善の機会を発見するのに役立ちます。詳細データにより、GitLabの価値を最大化し、ワークフローを強化するための、より正確で実用的な推奨事項を提供できます。
- 匿名化されたベンチマークレポート: 詳細なイベントデータを使用すると、高レベルの集約されたデータだけでなく、詳細な使用パターンに焦点を当てることで、同様の組織とのより正確で関連性の高いパフォーマンス比較が可能になります。

### イベントレベルのデータ収集の有効化または無効化 {#enable-or-disable-event-level-data-collection}

{{< alert type="note" >}}

 トラッキングが有効になっている場合、製品使用状況トラッキングを有効にすると、自動的に無効になります。一度にアクティブにできるデータ収集方法は1つだけです。

{{< /alert >}}

イベントレベルのデータ収集を有効または無効にするには:

1. 管理者アクセス権を持つユーザーとしてサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **Metrics and Profiling**（メトリクスとプロファイリング）を選択します。
1. **イベントのトラッキング**を展開します。
1. 設定を有効にするには、**イベント追跡を有効にする**チェックボックスをオンにします。設定を無効にするには、チェックボックスをオフにします。
1. **変更を保存**を選択します。

### プログラムによるイベントレベルのデータ収集の有効化または無効化 {#programmatically-enabling-or-disabling-event-level-data-collection}

この設定は、初回インストール時に新しいインスタンスに対してのみ機能します。

**Omnibusインストールの場合:**

インストール中に使用状況データ収集を無効にするには、`gitlab_rails['initial_gitlab_product_usage_data']`を`false`に設定します。

**Kubernetes Operatorデプロイの場合:**

イベントレベルのデータ収集を無効にするには、`global.appConfig.initialDefaults.gitlabProductUsageData`を`false`に設定します。

**重要な注意点:**

- デフォルトの初期設定は、インストール中にのみ適用されます。これらの設定を後で変更しても効果はありません。
- インストール後にイベントデータ収集を有効または無効にするには、前のセクションで説明した管理者設定を使用します。

### イベント配信タイミング {#event-delivery-timing}

イベントは、発生後ほぼすぐにGitLabに送信されます。システムはイベントを小さなバッチで収集し、10個のイベントが収集されるとデータを送信します。このアプローチにより、効率的なネットワーキングの使用を維持しながら、ほぼリアルタイムの配信が実現します。

### ペイロードサイズと圧縮 {#payload-size-and-compression}

各イベントのサイズは約10 KB（JSON形式）です。10個のイベントのバッチは、約100 KBの非圧縮ペイロードサイズになります。送信前に、ペイロードが圧縮され、データ転送サイズを最小限に抑え、パフォーマンスを最適化します。

### イベントデータログ {#event-data-logs}

イベントレベルのトラッキングデータは、`product_usage_data.log`ファイルに記録されます。このログには、ペイロード情報とコンテキストデータを含む、追跡された製品使用状況イベントのJSON形式のエントリが含まれています。各エントリは、個別のトラッキングイベントと、送信されたすべてのデータを表します。

ログファイルは次の場所にあります:

- `/var/log/gitlab/gitlab-rails/product_usage_data.log` (Linuxパッケージインストール)
- `/home/git/gitlab/log/product_usage_data.log` (セルフコンパイルインストール)

これらのログはデータ送信に関する詳細な表示レベルを提供しますが、機能の使用状況分析ではなく、セキュリティチームによる検査専用に設計されています。ログシステムの詳細については、[ログシステムのドキュメント](../logs/_index.md#product-usage-data-log)を参照してください。
