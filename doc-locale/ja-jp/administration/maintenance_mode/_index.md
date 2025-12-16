---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabメンテナンスモード
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

メンテナンスモードを使用すると、管理者は、メンテナンスタスクの実行中に書き込み操作を最小限に抑えることができます。主な目標は、内部状態を変更するすべての外部アクションをブロックすることです。内部状態には、PostgreSQLデータベースだけでなく、特にファイル、Gitリポジトリ、コンテナレジストリが含まれます。

メンテナンスモードが有効になっている場合、新しいアクションが実行されず、内部状態の変更が最小限であるため、進行中のアクションは比較的早く完了します。その状態では、さまざまなメンテナンスタスクが容易になります。サービスを完全に停止したり、必要以上に短い時間でさらに低下させたりすることができます。たとえば、cronジョブを停止し、キューをドレインすると、かなり速くなります。

メンテナンスモードでは、内部状態を変更しないほとんどの外部アクションが許可されます。大まかに言うと、HTTP `POST`、`PUT`、`PATCH`、および`DELETE`リクエストはブロックされ、[特別なケースの処理方法](#rest-api)の詳細な概要が利用可能です。

## メンテナンスモードを有効にする {#enable-maintenance-mode}

次のいずれかの方法で、管理者としてメンテナンスモードを有効にします:

- **WEB UI**:
  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **メンテナンスモード**を展開し、**メンテナンスモードを有効にする**
を切り替えます。オプションで、バナーのメッセージを追加することもできます。
  1. **変更を保存**を選択します。

- **API**:

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=true"
  ```

## メンテナンスモードを無効にする {#disable-maintenance-mode}

次の3つのいずれかの方法で、メンテナンスモードを無効にします:

- **WEB UI**:
  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **メンテナンスモード**を展開し、**メンテナンスモードを有効にする**を切り替えます。オプションで、バナーのメッセージを追加することもできます。
  1. **変更を保存**を選択します。

- **API**:

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=false"
  ```

## メンテナンスモードでのGitLab機能の動作 {#behavior-of-gitlab-features-in-maintenance-mode}

メンテナンスモードが有効になっている場合、バナーがページの上部に表示されます。バナーは特定のメッセージでカスタマイズできます。

許可されていない書き込み操作をユーザーが実行しようとすると、エラーが表示されます。

![メンテナンスモードのバナーとエラーメッセージ](img/maintenance_mode_error_message_v17_6.png)

{{< alert type="note" >}}

場合によっては、アクションからの視覚的なフィードバックが誤解を招く可能性があります。たとえば、プロジェクトにStarを付けると、**Star付き**ボタンが**Star付き解除**アクションを示すように変わります。ただし、これはフロントエンドの更新のみであり、POSTリクエストの失敗ステータスは考慮されていません。これらの視覚的なバグは、[フォローアップイテレーションで](https://gitlab.com/gitlab-org/gitlab/-/issues/295197)修正される予定です。

{{< /alert >}}

### 管理者機能 {#administrator-functions}

システム管理者は、アプリケーション設定を編集できます。これにより、有効にした後でメンテナンスモードを無効にできます。

### 認証 {#authentication}

すべてのユーザーはGitLabインスタンスにサインインおよびサインアウトできますが、新しいユーザーを作成することはできません。

その時間に[LDAP同期](../auth/ldap/_index.md)がスケジュールされている場合、ユーザーの作成が無効になっているため、失敗します。同様に、[SAMLに基づくユーザー作成](../../integration/saml.md#configure-saml-support-in-gitlab)も失敗します。

### Gitアクション {#git-actions}

すべての読み取り専用Git操作は引き続き機能します。たとえば、`git clone`や`git pull`などです。すべての書き込み操作は、CLIおよびWeb IDEの両方で失敗し、次のエラーメッセージが表示されます。`Git push is not allowed because this GitLab instance is currently in (read-only) maintenance mode.`

Geoが有効になっている場合、プライマリとセカンダリの両方へのGitプッシュは失敗します。

### マージリクエスト、イシュー、エピック {#merge-requests-issues-epics}

前述したものを除くすべての書き込みアクションは失敗します。たとえば、ユーザーはマージリクエストまたはイシューを更新できません。

### 受信 {#incoming-email}

新しいイシューの返信、イシュー (サービスデスクの新しいイシューを含む)、[メールによる](../incoming_email.md)マージリクエストの作成は失敗します。

### 送信メール {#outgoing-email}

通知メールは引き続き届きますが、パスワードのリセットなど、データベースの書き込みを必要とするメールは届きません。

### REST API {#rest-api}

ほとんどのJSONリクエストでは、`POST`、`PUT`、`PATCH`、および`DELETE`がブロックされ、APIはエラーメッセージ`GitLab Maintenance: system is in maintenance mode`で`503`応答を返します。次のリクエストのみが許可されています:

|HTTPリクエスト | 許可されたルート |  備考 |
|:----:|:--------------------------------------:|:----:|
| `POST` | `/admin/application_settings/general` | 管理者UIでアプリケーション設定を更新できるようにする |
| `PUT`  | `/api/v4/application/settings` | APIを使用してアプリケーション設定を更新できるようにする |
| `POST` | `/users/sign_in` | ユーザーがサインインできるようにする。 |
| `POST` | `/users/sign_out`| ユーザーがサインアウトできるようにする。 |
| `POST` | `/oauth/token` | ユーザーがGeoセカンダリに初めてサインインできるようにする。 |
| `POST` | `/admin/session`、`/admin/session/destroy` | [GitLab管理者の管理者モード](https://gitlab.com/groups/gitlab-org/-/epics/2158)を許可する |
| `POST` | `/compare`で終わるパス| Gitリビジョンルート。 |
| `POST` | `.git/git-upload-pack` | Gitプル/クローンを許可する。 |
| `POST` | `/api/v4/internal` | 内部APIルート |
| `POST` | `/admin/sidekiq` | **管理者**エリアでバックグラウンドジョブの管理を許可する |
| `POST` | `/admin/geo` | 管理者UIでGeoノードを更新できるようにする |
| `POST` | `/api/v4/geo_replication`| セカンダリサイトで特定のGeo固有の管理者UIアクションを許可する |

### GraphQL API {#graphql-api}

{{< history >}}

- 許可リストの`GeoRegistriesUpdate`ミューテーションの追加は、GitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124259)。

{{< /history >}}

`POST /api/graphql`リクエストは許可されていますが、ミューテーションはエラーメッセージ`You cannot perform write operations on a read-only instance`でブロックされます。

許可されている唯一のミューテーションは、`GeoRegistriesUpdate`であり、レジストリの再同期と再検証に使用されます。

### 継続的インテグレーション {#continuous-integration}

- 新しいジョブまたはパイプラインは、スケジュールされているかどうかに関係なく開始されません。
- すでに実行中のジョブは、GitLab Runnerでの実行が終了した場合でも、GitLab UIで`running`ステータスを引き続き保持します。
- プロジェクトの制限時間を超えて`running`状態のジョブは、タイムアウトしません。
- パイプラインを開始、再試行、またはキャンセルすることはできません。新しいジョブも作成できません。
- `/admin/runners`のRunnerのステータスは更新されません。
- `gitlab-runner verify`はエラー`ERROR: Verifying runner... is removed`を返します。

メンテナンスモードが無効になると、新しいジョブが再び選択されます。メンテナンスモードを有効にする前に`running`状態にあったジョブは再開され、ログの更新が再び開始されます。

{{< alert type="note" >}}

メンテナンスモードをオフにした後、以前に`running`だったパイプラインを再起動する必要があります。

{{< /alert >}}

### デプロイ {#deployments}

パイプラインが未完了のため、デプロイは完了しません。

メンテナンスモード中は自動デプロイを無効にし、無効になっている場合は有効にする必要があります。

#### Terraformのインテグレーション {#terraform-integration}

TerraformのインテグレーションはCIパイプラインの実行に依存するため、ブロックされます。

### コンテナレジストリ {#container-registry}

`docker push`はこのエラーで失敗します：`denied: requested access to the resource is denied`、ただし`docker pull`は機能します。

### パッケージレジストリ {#package-registry}

パッケージレジストリでは、パッケージをインストールできますが、公開することはできません。

### バックグラウンドジョブ {#background-jobs}

バックグラウンドジョブ (cronジョブ、Sidekiq) は、バックグラウンドジョブが自動的に無効にならないため、そのまま実行され続けます。バックグラウンドジョブはインスタンスの内部状態を変更する可能性のある操作を実行するため、メンテナンスモードが有効になっている間は、それらの一部またはすべてを無効にすることをお勧めします。

[計画されたGeoフェイルオーバーの間](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-site)、Geoに関連するものを除くすべてのcronジョブを無効にする必要があります。

キューを監視してジョブを無効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
1. Sidekiqダッシュボードで、**Cron**を選択し、**Disable All**（すべて無効にする）を選択して、ジョブを個別にまたは一度にすべて無効にします。

### インシデント管理 {#incident-management}

[インシデント管理](../../operations/incident_management/_index.md)機能は制限されています。[アラート](../../operations/incident_management/alerts.md)と[インシデント](../../operations/incident_management/manage_incidents.md#create-an-incident)の作成は完全に一時停止されます。したがって、アラートとインシデントの通知と呼び出しは無効になります。

### 機能フラグ {#feature-flags}

- 開発機能フラグは、APIを介してオンまたはオフにすることはできませんが、Railsコンソールを介して切替できます。
- [機能フラグサービス](../../operations/feature_flags.md)は機能フラグチェックに応答しますが、機能フラグを切り替えることはできません。

### Geoセカンダリ {#geo-secondaries}

プライマリがメンテナンスモードの場合、セカンダリも自動的にメンテナンスモードになります。

メンテナンスモードを有効にする前に、レプリケーションを無効にしないことが重要です。

AdminUIを介したレプリケーション、検証、およびレジストリを再同期および再検証するための手動アクションは引き続き機能しますが、プロキシされたGitプッシュはプライマリには機能しません。

### セキュア機能 {#secure-features}

イシューの作成、またはマージリクエストの作成または承認に依存する機能は機能しません。

脆弱性レポートページから脆弱性リストをエクスポートすることはできません。

UIにエラーが表示されない場合でも、検出または脆弱性オブジェクトのステータスを変更しても機能しません。

SASTおよびシークレット検出は、アーティファクトを作成するためにCIジョブを渡すことに依存するため、開始できません。

## ユースケースの例: 計画的なフェイルオーバー {#an-example-use-case-a-planned-failover}

[計画されたフェイルオーバー](../geo/disaster_recovery/planned_failover.md)のユースケースでは、プライマリデータベース内の一部の書き込みは、すばやくレプリケートされ、数が重要ではないため、許容されます。

同じ理由で、メンテナンスモードが有効になっているときにバックグラウンドジョブを自動的にブロックしません。

結果として得られるデータベースの書き込みは許容されます。ここで、トレードオフは、より多くのサービスの低下とレプリケーションの完了との間にあります。

ただし、計画的なフェイルオーバー中に、[Geoに関連しないcronジョブを手動でオフにするようにユーザーに依頼](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-site)します。新しいデータベースの書き込みと非Geo cronジョブがない場合、新しいバックグラウンドジョブはまったく作成されないか、最小限になります。
