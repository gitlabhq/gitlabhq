---
stage: Security
group: Security Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabが生成するセキュリティテレメトリと、GitLab.com、GitLab Self-Managed、GitLab Dedicatedでの収集方法について説明します。
title: セキュリティテレメトリー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

セキュリティテレメトリとは、セキュリティインシデントを検出して調査するためにGitLabから収集するデータです。

GitLabセキュリティオペレーションチームは、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスの管理者、およびGitLab.comのネームスペースのオーナー向けに、これらの推奨事項を作成しました。これらを使用して、GitLabが生成するセキュリティテレメトリの種類、それぞれが示す情報、および提供形態とサブスクリプションのプランで収集できる内容を理解してください。これらは、組織が定義するログ記録およびモニタリングのプロセスを補完するものであり、それらに代わるものではありません。

検出が発生した場合は、[セキュリティインシデントへの対応](responding_to_security_incidents.md)に従って、インシデントを封じ込めて修正してください。

> [!warning]
> これらの提案や推奨事項は、自己責任で使用してください。利用可能なテレメトリは、提供形態、サブスクリプションのプラン、および設定によって異なります。

## セキュリティテレメトリの種類 {#kinds-of-security-telemetry}

GitLabは、2種類の主なセキュリティテレメトリを生成します。それぞれ異なる質問に答え、異なる方法で収集されるため、可能な限り両方を使用してください。

[監査イベント](../user/compliance/audit_events.md): ユーザーのサインイン、権限の変更、トークンの作成、設定の変更など、セキュリティに関連するアクションが発生したときにGitLabが発行する構造化されたイベントです。各イベントは、誰が実行したか、何が影響を受けたか、どのIPアドレスから、いつ実行されたかを記録します。監査イベントは「GitLabでユーザーが何を行ったか」という質問に答えます。GitLabは数百種類の[監査イベントタイプ](../user/compliance/audit_event_types.md)を定義しています。

[アプリケーションログ](../administration/logs/_index.md): GitLab Railsアプリケーションと周辺コンポーネントによって書き込まれるログファイルです: Workhorse、Gitaly、GitLab Shell、Sidekiq。これらは、すべてのHTTPリクエスト、Git操作、バックグラウンドジョブを記録します。この活動の多くは、失敗したリクエストやブロックされたリクエスト、監査対象外のエンドポイントへのリクエスト、リクエストの正確なパラメータ、GitLabがそれを処理するために実行した内部ステップなど、監査イベントにはなりません。アプリケーションログは「GitLab内部で何が起こったか」という質問に答えるものであり、GitLab自体に対する悪用の試みを検出するための唯一の情報源です。

これら2つに加えて、CI/CDジョブログや認証情報インベントリなど、いくつかのGitLab機能は独自にセキュリティ関連のデータを記録します。詳細については、[その他のセキュリティデータのソース](#other-sources-of-security-data)を参照してください。

## 提供形態とプランで収集できる内容 {#what-you-can-collect-on-your-offering-and-tier}

次の表は、各提供形態において、セキュリティテレメトリを収集する各方法に必要な最小のプランを示しています。GitLab DedicatedはUltimateでのみ利用可能であるため、この表のすべての項目はGitLab Dedicatedで利用できます。

| 収集方法 | GitLab.com | GitLab Self-Managed | GitLab Dedicated |
|-------------------|------------|---------------------|------------------|
| GitLabで監査イベントを表示する、またはAPIで取得する | Premium | Premium | はい |
| セキュリティ情報およびイベント管理（SIEM）システムまたはその他の宛先に監査イベントをストリーミングする | Ultimate | Ultimate | はい |
| アプリケーションログを収集する | 利用不可。GitLabがこれらのログを運用し、保持します。 | すべてのプラン | はい |

実際には、これは次のことを意味します:

- Freeでは、自分自身のサインインイベントの確認やCI/CDジョブログのレビューは可能ですが、グループ、プロジェクト、インスタンスの監査イベントは表示できません。GitLab Self-Managedでは、それでもアプリケーションログを収集できます。これには`audit_json.log`に書き込まれる少数の監査イベントが含まれます。
- Premiumでは、GitLabで監査イベントを表示および検索したり、APIで取得したりできますが、ストリーミングはできません。GitLab内部で何が起こっているかを把握できないわけではありませんが、検出と長期保持はお客様の責任で行う必要があります。
- Ultimateでは、ほぼリアルタイムでSIEMに監査イベントをストリーミングでき、GitLabには決して表示されないストリーミング専用イベントを受信できます。

## 監査イベントの表示 {#view-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

PremiumおよびUltimateでは、設定を行わなくても監査イベントを表示できます:

- GitLab UIの[グループ、プロジェクト、インスタンスレベル](../administration/compliance/audit_event_reports.md)で表示できます。インスタンスレベルの監査イベントは、GitLab Self-ManagedおよびGitLab Dedicatedで利用できます。
- [監査イベントAPI](../api/audit_events.md)を使用すると、UIと同じイベントが返されます。

Freeでは、表示できる唯一の監査イベントは、ユーザープロファイルの**認証ログ**にある自分自身の[サインインイベント](../user/compliance/audit_events.md#sign-in-audit-events)のみです。

監査イベントの表示は、スポットチェックや、事後に特定のユーザーやプロジェクトを調査するには十分です。検出には、いくつかの理由から十分ではありません:

- 各クエリは30日間のウィンドウに制限されており、UIではイベントの詳細を検索できません。
- 一部のイベントタイプは[ストリーミング専用](#streaming-only-events)であり、GitLabには決して表示されません。
- イベントに対してアラートを設定したり、他のデータと関連付けたり、保持期間を制御したりすることはできません。

監査イベントをストリーミングできない場合は、スケジュールに従ってAPIから取得し、ログプラットフォームに読み込むことができます。これにより、遅延が発生し、ストリーミング専用イベントは含まれないものの、検索可能なコピーと検出の基盤を得ることができます。

## 監査イベントのストリーミング {#stream-audit-events}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

監査イベントのストリーミングは、監査イベントが発生するとすぐに、管理下にある宛先にすべての監査イベントを送信するため、SIEMは完全な、ほぼリアルタイムの記録を保持します。ストリーミングは、すべての提供形態で監査イベントを収集するための推奨方法であり、ストリーミング専用イベントを受信する唯一の方法です。

### ストリーミング専用イベント {#streaming-only-events}

一部の監査イベントタイプはストリーミング専用です。これらはGitLabに保存されず、ストリーミング先を設定している場合にのみ受信できます。それらの多くは機密データへの読み取りアクセスを記録するため、検出に特に役立ちます。例:

| ストリーミング専用イベント | 示される情報 |
|----------------------|-------------------|
| `repository_git_operation` | 誰がリポジトリをクローン、フェッチ、またはプッシュしたか |
| `repository_file_accessed_api`および`repository_file_accessed_web` | 誰がAPIまたはWeb UIを通じてファイルを読み取ったか |
| `job_artifact_downloaded` | 誰がCI/CDジョブアーティファクトをダウンロードしたか |
| `variable_viewed_api`および`variable_viewed_graphql` | 誰がCI/CD変数を読み取ったか |
| `personal_access_token_used_from_unseen_ip` | これまで見られなかったIPアドレスからトークンが使用された |
| `user_authenticated_using_job_token` | CI/CDジョブトークンが認証に使用された |

これは完全なリストではありません。すべてのストリーミング専用イベントについては、[利用可能な監査イベントタイプ](../user/compliance/audit_event_types.md#available-audit-event-types)のリストにある**データベースに保存**列を参照してください。

### ストリーミングの設定 {#set-up-streaming}

ストリーミングを設定する場所は、提供形態によって異なります:

| 提供形態 | 設定する担当者 | スコープ | 詳細情報 |
|----------|-------------------|-------|------------------|
| GitLab.com | トップレベルグループのオーナー | トップレベルグループ、そのサブグループ、そのプロジェクト | [トップレベルグループの監査イベントストリーミング](../user/compliance/audit_event_streaming.md) |
| GitLab Self-ManagedおよびGitLab Dedicated | 管理者 | インスタンス全体。組織内のさまざまな宛先に対して、トップレベルグループごとに設定することもできます。 | [インスタンスの監査イベントストリーミング](../administration/compliance/audit_event_streaming.md) |

ストリーミングは、HTTPエンドポイント、Google Cloud Logging、Amazon S3の3つの宛先タイプをサポートします。複数の宛先を追加し、[イベントタイプごとに各宛先をフィルタリング](../user/compliance/audit_event_streaming.md#update-event-filters)できます。

受信側を設計する際は、以下を考慮してください:

- 時折重複した配信が発生することを想定し、イベントの`id`で重複排除してください。
- GitLab.comでは、宛先側で[GitLab.com IP範囲](../user/gitlab_com/_index.md#ip-range)からのトラフィックを許可してください。
- 宛先は機密情報として扱ってください。ストリーミングされるイベントには、完全なイベントの詳細が含まれます。
- 多数の宛先を計画している場合は、[宛先の上限](../administration/instance_limits.md#audit-events-streaming-destination-limits)を確認してください。

## アプリケーションログの収集 {#collect-application-logs}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

監査イベントは、アクションが発生したことを示します。アプリケーションログは、その方法を示します。これらは、監査イベントが要約するリクエストレベルの詳細を提供し、失敗したリクエスト、レート制限されたリクエスト、監査対象外のエンドポイントへのリクエスト、各リクエストの完全なパラメータなど、監査イベントがまったく存在しない、セキュリティに関連する大量の活動を記録します。アプリケーションログを収集できる場合は、収集してください。

### セキュリティに関連するログ {#security-relevant-logs}

次のログは、セキュリティモニタリングに最も関連性があります。パスは、Linuxパッケージインストールでは`/var/log/gitlab/`からの相対パスです。[ログシステム](../administration/logs/_index.md#accessing-logs-on-helm-chart-installations)のドキュメントでは、Helmチャートインストールで同じログを見つける場所について説明しています。

| ログ | 記録される内容 | 検出に使用する内容 |
|-----|-----------------|------------------|
| [`gitlab-rails/production_json.log`](../administration/logs/_index.md#production_jsonlog) | Webアプリケーションによって処理されるすべてのリクエスト: ユーザー、IP、パス、ステータス、パラメータ。 | 不審なサインインフロー、設定の変更、Webエンドポイントに対する悪用の試み。 |
| [`gitlab-rails/api_json.log`](../administration/logs/_index.md#api_jsonlog) | すべてのREST APIリクエスト: ユーザー、IP、ルート、ステータス、パラメータ。 | トークンの悪用、APIを介した大量のデータアクセス、侵害されたアカウントによる自動化。 |
| [`gitlab-rails/graphql_json.log`](../administration/logs/_index.md#graphql_jsonlog) | GraphQLクエリとその複雑さ。 | GraphQLを通じた列挙と大量のデータアクセス。 |
| [`gitlab-rails/auth_json.log`](../administration/logs/_index.md#auth_jsonlog) | レート制限および保護されたパスのルールによってブロックされたリクエスト。 | ブルートフォースおよびクレデンシャルスタッフィング。 |
| [`gitlab-rails/audit_json.log`](../administration/logs/_index.md#audit_jsonlog) | ファイルに書き込まれた監査イベント。 | ストリーミングできないプランを含め、監査イベントのローカルコピー。 |
| [`gitlab-rails/application_json.log`](../administration/logs/_index.md#application_jsonlog) | ユーザーの作成やプロジェクトの削除などのインスタンスイベント。 | アカウントおよびプロジェクトのライフサイクルの変更。 |
| [`gitlab-shell/gitlab-shell.log`](../administration/logs/_index.md#gitlab-shelllog) | SSH経由のGit操作: ユーザー、プロジェクト、コマンド。 | デプロイキーによるものを含む、SSH経由でのリポジトリのクローンおよびプッシュ。 |
| [`gitlab-workhorse/current`](../administration/logs/_index.md#workhorse-logs) | HTTPS経由のGitやファイルのダウンロードを含む、すべてのトラフィックのHTTPアクセスログ。 | HTTPS経由でのリポジトリのクローン、アーティファクトとエクスポートのダウンロード、Webスキャン。 |
| [`gitaly/current`](../administration/logs/_index.md#gitaly-logs) | リポジトリ操作およびGitフック。 | 異常なリポジトリアクセスパターン、フックの失敗。 |
| [`sidekiq/current`](../administration/logs/_index.md#sidekiq-logs) | バックグラウンドジョブ: インポート、エクスポート、ミラーの更新、通知。 | データの持ち出しに使用されるプロジェクトのエクスポートおよびミラー設定。 |

### ログ間でリクエストを追跡する {#follow-a-request-across-logs}

GitLabが処理するすべてのリクエストには相関IDが付与され、WorkhorseからRails、Gitaly、Sidekiqに至るまで、そのリクエストが関係するすべてのログに同じIDが表示されます。1つのログで不審なエントリを見つけた場合は、すべてのログでその相関IDを検索し、リクエスト全体を再構築してください。詳細については、[相関IDを使用して関連するログエントリを見つける](../administration/logs/tracing_correlation_id.md)を参照してください。

### アプリケーションログをプラットフォームに転送する {#ship-application-logs-to-your-platform}

GitLab Self-Managedの場合: 各ノードからログプラットフォームへ、選択したログシッパーを使用してログを転送します。GitLabはログをローカルでローテーションし、最終的には古いファイルを削除するため、ローテーションによってログが削除される前に転送してください。ローテーションを調整するには、[ログ記録の設定](https://docs.gitlab.com/omnibus/settings/logs/)を参照してください。マルチノードのデプロイでは、相関IDの検索がリクエスト全体をカバーするように、プラットフォームがすべてのノードからログを集約していることを確認してください。

GitLab Dedicatedの場合: GitLabは、AWSアカウント内のAmazon S3バケットにアプリケーションおよびインフラストラクチャのログを配信し、1年間保持します。Switchboardでログコレクターにバケットへの読み取りアクセスを許可してください。1年以上ログが必要な場合は、独自のストレージにコピーしてください。設定手順については、[GitLab Dedicatedのアプリケーションログ](../administration/dedicated/monitor.md)を参照してください。

## その他のセキュリティデータのソース {#other-sources-of-security-data}

監査イベントおよびアプリケーションログに加えて、いくつかのGitLab機能は、直接確認したり検出に取り込んだりできるセキュリティ関連のデータを記録します。それらのほとんどは、収集の設定なしでGitLab UIで利用でき、いくつかはすべてのプランで利用できます。

| データソース | 利用可否設定 | 表示内容 |
|-------------|--------------|---------------|
| [サインイン監査イベント](../user/compliance/audit_events.md#sign-in-audit-events) | すべてのプラン | ユーザープロフィールの**認証ログ**に表示される、ユーザーの成功したサインイン。Freeで利用可能な唯一の監査イベントです。 |
| [CI/CDジョブログ](../ci/jobs/job_logs.md) | すべてのプラン | 実行されたコマンド、公開されたシークレット、予期しないユーザーによって開始されたパイプライン。ストレージと保持については、[ジョブログの管理](../administration/cicd/job_logs.md)を参照してください。 |
| [ジョブトークン認証ログ](../ci/jobs/ci_job_token.md#job-token-authentication-log) | すべてのプラン | CI/CDジョブトークンを使用してプロジェクトに認証したプロジェクト。 |
| [認証情報インベントリ](../administration/credentials_inventory.md) | Ultimate | インスタンスまたはトップレベルグループに存在する、パーソナル、グループ、およびプロジェクトアクセストークン、SSHキー、GPGキーと、それらのスコープおよび有効期限。 |
| [シークレットプッシュ保護](../user/application_security/secret_detection/secret_push_protection/_index.md)および[パイプラインシークレット検出](../user/application_security/secret_detection/_index.md) | シークレットプッシュ保護: Ultimate。パイプラインのシークレット検出: 全プラン。 | ユーザーがプッシュしようとした、またはリポジトリにコミットされたシークレット。 |

<!-- Keep this table in sync with the detection data sources table on detecting_security_incidents.md. -->

## 次の手順 {#next-steps}

テレメトリがSIEMまたはログプラットフォームに到達した後:

- 監視する信号を決定し、TLDR検出ルールをデプロイするには、[検出機能の構築](detecting_security_incidents.md#build-a-detection-capability)を参照してください。
- 検出が依存するイベントタイプ、特にストリーミング専用のものが、プラットフォームに到達していることを確認してください。ストリーミングではなくAPIで監査イベントを収集している場合は、受信していないイベントに依存する検出がないか確認してください。
- 調査とコンプライアンスのニーズを満たす保持期間を定義してください。GitLabは保存された監査イベントを無期限に保持しますが、実際に検索できる内容はストリーミング先とログプラットフォームによって定義されます。

## 関連トピック {#related-topics}

- [セキュリティインシデント](security_incidents.md)
- [GitLabを保護する](_index.md)
