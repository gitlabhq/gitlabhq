---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリのストレージを削減する
description: GitLabコンテナレジストリのモニタリングとストレージ使用量を削減するためのヒント。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナレジストリは、レジストリの使用状況を管理しないと、時間の経過とともにサイズが大きくなる場合があります。たとえば、多数のイメージまたはタグを追加すると、次のようになります:

- 利用可能なタグまたはイメージのリストの取得が遅くなる。
- サーバーで大量のストレージ容量を消費する。

不要なイメージとタグを削除し、コンテナレジストリの使用状況を自動的に管理するように[コンテナレジストリのクリーンアップポリシー](#cleanup-policy)を設定することをおすすめします。

## コンテナレジストリの使用状況を表示する {#view-container-registry-usage}

{{< details >}}

- プラン: Free、Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/5523)されました

{{< /history >}}

コンテナレジストリのリポジトリのストレージ使用量データを表示します。

### プロジェクトの場合 {#for-a-project}

前提要件:

- GitLab Self-Managedインスタンスの場合、管理者は[コンテナレジストリメタデータデータベースを有効にする](../../../administration/packages/container_registry_metadata_database.md)必要があります。
- 少なくともプロジェクトのメンテナーロールまたはネームスペースのオーナーロールが必要です。

プロジェクトのストレージ使用量を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 次のいずれかを実行します:
   - 合計ストレージ使用量を表示するには、**設定** > **使用量クォータ**を選択します。**ネームスペースの実体**で、**Container Registry**（コンテナレジストリ）を選択して、個別のリポジトリを表示します。
   - リポジトリごとのストレージ使用量を直接表示するには、**デプロイ** > **Container Registry**（Container Registry）を選択します。

次の方法も使用できます:

- [プロジェクトAPI](../../../api/projects.md#get-a-single-project)を使用して、プロジェクトのコンテナレジストリの合計ストレージを取得します。
- [レジストリAPI](../../../api/container_registry.md#get-details-of-a-single-repository)を使用して、特定のリポジトリのサイズデータを取得します。

### グループの場合 {#for-a-group}

前提要件:

- GitLab Self-Managedインスタンスの場合、管理者は[コンテナレジストリメタデータデータベースを有効にする](../../../administration/packages/container_registry_metadata_database.md)必要があります。
- グループのオーナーロールが必要です。

グループのストレージ使用量を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. **ストレージ**タブを選択します。

[グループAPI](../../../api/groups.md#list-all-groups)を使用して、グループ内のすべてのプロジェクトのコンテナレジストリの合計ストレージを取得することもできます。

### ストレージデータの更新 {#storage-data-updates}

メタデータデータベースが有効になった後:

- 新しいコンテナイメージの場合、サイズデータはプッシュ後すぐに利用可能になります。
- 既存のコンテナイメージの場合、サイズデータはバックグラウンドで計算され、最大24時間かかる場合があります。

ストレージデータの更新は次のタイミングで行われます:

- コンテナイメージをプッシュまたは削除した後すぐ。
- 次の場合はリアルタイムで更新されます:
  - UIでリポジトリイメージタグを表示するとき。
  - コンテナレジストリAPIを使用して、[単一のリポジトリの詳細を取得](../../../api/container_registry.md#get-details-of-a-single-repository)するとき。
- プロジェクトのコンテナリポジトリでタグをプッシュまたは削除したとき。
- グループの場合は5分ごと。

{{< alert type="note" >}}

GitLab Self-Managedインスタンスの場合、管理者がメタデータデータベースを有効にすると、ストレージデータが利用可能になります。GitLab.comでは、メタデータデータベースはデフォルトで有効になっています。

{{< /alert >}}

## コンテナレジストリの使用量の計算方法 {#how-container-registry-usage-is-calculated}

コンテナレジストリに保存されているイメージレイヤーは、ルートネームスペースレベルで重複排除されます。

イメージは次の場合に1回のみカウントされます:

- 同じリポジトリ内で同じイメージに複数回タグ付けする場合
- 同じルートネームスペース下の個別のリポジトリで同じイメージにタグ付けする場合

イメージレイヤーは次の場合に1回のみカウントされます:

- 同じコンテナリポジトリ、プロジェクト、またはグループ内の複数のイメージでイメージレイヤーを共有する場合
- 異なるリポジトリ間でイメージレイヤーを共有する場合

タグ付けされたイメージによって参照されるレイヤーのみが考慮されます。タグ付けされていないイメージと、これらのイメージによって排他的に参照されるレイヤーは、[オンラインガベージコレクション](delete_container_registry_images.md#garbage-collection)の対象となります。タグ付けされていないイメージレイヤーは、24時間以内に参照されないままの場合、24時間後に自動的に削除されます。

イメージレイヤーは、元の（通常は圧縮された）形式でストレージバックエンドに保存されます。つまり、特定のイメージレイヤーに対して測定されたサイズは、対応する[イメージマニフェスト](https://github.com/opencontainers/image-spec/blob/main/manifest.md#example-image-manifest)に表示されるサイズと一致するはずです。

ネームスペースの使用量は、ネームスペース下の任意のコンテナリポジトリからタグがプッシュまたは削除されてから数分後に更新されます。

### 遅延更新 {#delayed-refresh}

非常に大規模なネームスペース（約1％のネームスペース）の場合、リアルタイムでコンテナレジストリの使用量を最大限の精度で計算することはできません。これらのネームスペースのメンテナーが使用量を確認できるようにするために、遅延フォールバックメカニズムが用意されています。詳細については、[エピック9413](https://gitlab.com/groups/gitlab-org/-/epics/9413)を参照してください。

ネームスペースの使用量を正確に計算できない場合、GitLabは遅延測定方法にフォールバックします。遅延測定方法では、表示される使用量サイズはネームスペース内のすべての一意のイメージレイヤーの合計です。タグ付けされていないイメージレイヤーは無視されません。このため、タグを削除しても、表示される使用量サイズは大幅に変化しない場合があります。サイズの値は次の場合にのみ変化します:

- 自動[ガベージコレクションプロセス](delete_container_registry_images.md#garbage-collection)が実行され、タグ付けされていないイメージレイヤーが削除された場合。ユーザーがタグを削除すると、ガベージコレクションの実行が24時間後に開始されるようにスケジュールされます。その実行中に、以前にタグ付けされたイメージが分析され、それらのレイヤーは他のタグ付けされたイメージによって参照されていない場合、削除されます。レイヤーが削除されると、ネームスペースの使用量が更新されます。
- ネームスペースのレジストリ使用量が、GitLabが最大限の精度で測定できるくらい十分に低くなった場合。ネームスペースの使用量が低くなると、測定は自動的に遅延測定から正確な使用量測定に切り替わります。どの測定方法が使用されているかをUIで確認することはできませんが、[イシュー386468](https://gitlab.com/gitlab-org/gitlab/-/issues/386468)でこれを改善する予定です。

## クリーンアップポリシー {#cleanup-policy}

{{< history >}}

- GitLab 15.0で、[必要な権限](https://gitlab.com/gitlab-org/gitlab/-/issues/350682)がデベロッパーからメンテナーに変更されました。

{{< /history >}}

クリーンアップポリシーは、コンテナレジストリからタグを削除するために使用できるスケジュールされたジョブです。このポリシーが定義されているプロジェクトでは、正規表現パターンに一致するタグは削除されます。基盤となるレイヤーとイメージは残ります。

タグに関連付けられていない基盤となるレイヤーとイメージを削除するために、管理者は`-m`スイッチを指定して[ガベージコレクション](../../../administration/packages/container_registry.md#removing-untagged-manifests-and-unreferenced-layers)を使用できます。

### クリーンアップポリシーを有効にする {#enable-the-cleanup-policy}

{{< alert type="warning" >}}

パフォーマンス上の理由から、有効になっているクリーンアップポリシーは、コンテナイメージがない、GitLab.com上のプロジェクトに対して自動的に無効になります。

{{< /alert >}}

### クリーンアップポリシーの仕組み {#how-the-cleanup-policy-works}

クリーンアップポリシーは、コンテナレジストリ内のすべてのタグを収集し、削除するタグのみが残るまでタグを除外します。

クリーンアップポリシーは、タグ名に基づいてイメージを検索します。フルパスの一致のサポートは、イシュー[281071](https://gitlab.com/gitlab-org/gitlab/-/issues/281071)で追跡されます。

クリーンアップポリシー:

1. リスト内の特定のリポジトリを対象にすべてのタグを収集します。
1. `latest`タグを除外します。
1. `name_regex`（期限切れにするタグ）を評価し、一致しない名前を除外します。
1. `name_regex_keep`値（保持するタグ）に一致するタグを除外します。
1. マニフェストがないタグ（UIのオプションの一部ではない）を除外します。
1. 残りのタグを`created_date`で並べ替えます。
1. `keep_n`値（保持するタグの数）に基づいて、N個のタグを除外します。
1. `older_than`値（有効期限の間隔）よりも新しいタグを除外します。
1. [保護タグ](protected_container_tags.md)を除外します。
1. [イミュータブルタグ](immutable_container_tags.md)を除外する。
1. リストに残っているタグをコンテナレジストリから削除します。

{{< alert type="warning" >}}

GitLab.comでは、クリーンアップポリシーの実行時間が制限されています。ポリシーの実行後も、一部のタグがコンテナレジストリに残る場合があります。次回ポリシーを実行するときに、残りのタグが対象として含まれます。すべてのタグを削除するには、複数回実行する必要がある場合があります。

{{< /alert >}}

{{< alert type="warning" >}}

GitLab Self-Managedインスタンスは、[Docker Registry HTTP API V2](https://distribution.github.io/distribution/spec/api/)仕様に準拠するサードパーティのコンテナレジストリをサポートしています。ただし、この仕様にはタグ削除操作は含まれていません。したがって、GitLabは、サードパーティのコンテナレジストリとやり取りするときに、タグを削除するための回避策を使用します。詳細については、イシュー[15737](https://gitlab.com/gitlab-org/gitlab/-/issues/15737)を参照してください。実装のバリエーションが考えられるため、この回避策は、すべてのサードパーティレジストリで同じ予測可能な方法で動作することが保証されているわけではありません。GitLabコンテナレジストリを使用する場合は、特別なタグ削除操作が実装されているため、この回避策は必要ありません。この場合、クリーンアップポリシーは一貫性があり、予測可能であると考えることができます。{{< /alert >}}

#### クリーンアップポリシーのワークフローの例 {#example-cleanup-policy-workflow}

クリーンアップポリシーの保持ルールと削除ルール間の相互作用は複雑になる可能性があります。たとえば、次のクリーンアップポリシー設定が指定されたプロジェクトの場合:

- **Keep the most recent**（最新のものを保持）: イメージ名ごとに1つのタグ。
- **Keep tags matching**（一致するタグを保持）: `production-.*`
- **Remove tags older than**（次の期間より古いタグを削除）: 7日。
- **Remove tags matching**（一致するタグを削除）: `.*`。

また、次のタグを含むコンテナリポジトリ:

- `latest`、2時間前に公開。
- `production-v44`、3日前に公開。
- `production-v43`、6日前に公開。
- `production-v42`、11日前に公開。
- `dev-v44`、2日前に公開。
- `dev-v43`、5日前に公開。
- `dev-v42`、10日前に公開。
- `v44`、昨日公開。
- `v43`、12日前に公開。
- `v42`、20日前に公開。

この例では、次のクリーンアップ実行で削除されるタグは、`dev-v42`、`v43`、`v42`です。ルールは、次の優先順位で適用されると解釈できます:

1. 保持ルールが最も優先されます。タグがいずれかのルールに一致する場合、タグを保持する必要があります。
   - `latest`タグは常に保持されるため、`latest`タグは保持する必要があります。
   - `production-v44`、`production-v43`、`production-v42`タグは、**Keep tags matching**（一致するタグを保持）ルールに一致するため、保持する必要があります。
   - `v44`タグは、最新のもので、**Keep the most recent**（最新のものを保持）ルールに一致するため、保持する必要があります。
1. 削除ルールの優先順位は低く、タグはすべてのルールに一致する場合にのみ削除されます。保持ルールに一致しないタグ（`dev-44`、`dev-v43`、`dev-v42`、`v43`、`v42`）の場合:
   - `dev-44`と`dev-43`は、**Remove tags older than**（次の期間より古いタグを削除）と一致しないため、保持されます。
   - `dev-v42`、`v43`、`v42`は、**Remove tags older than**（次の期間より古いタグを削除）と**Remove tags matching**（一致するタグを削除）の両方のルールと一致するため、これらの3つのタグは削除できます。

### クリーンアップポリシーを作成する {#create-a-cleanup-policy}

[API](#use-the-cleanup-policy-api)またはUIでクリーンアップポリシーを作成できます。

UIでクリーンアップポリシーを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **コンテナレジストリ**を展開します。
1. **コンテナレジストリのクリーンアップポリシー**で、**クリーンアップルールの設定**を選択します。
1. フィールドに入力します:

   | フィールド                      | 説明 |
   |----------------------------|-------------|
   | **Toggle**（切替）                 | ポリシーのオン/オフを切り替えます。 |
   | **Run cleanup**（クリーンアップの実行）            | ポリシーの実行頻度。 |
   | **Keep the most recent**（最新のものを保持）   | イメージごとに常に保持するタグの数。 |
   | **Keep tags matching**（一致するタグを保持）     | 保持するタグを決定する正規表現パターン。`latest`タグは常に保持されます。すべてのタグについて、`.*`を使用します。その他の[正規表現パターンの例](#regex-pattern-examples)を参照してください。 |
   | **Remove tags older than**（次の期間より古いタグを削除） | X日より古いタグのみを削除します。 |
   | **Remove tags matching**（一致するタグを削除）   | 削除するタグを決定する正規表現パターン。この値を空白にすることはできません。すべてのタグについて、`.*`を使用します。その他の[正規表現パターンの例](#regex-pattern-examples)を参照してください。 |

   {{< alert type="note" >}}

   保持および削除の正規表現パターンは両方とも自動的に`\A`アンカーと`\Z`アンカーで囲まれるため、これらのアンカーを含める必要はありません。ただし、正規表現パターンを選択およびテストするときは、このことを考慮してください。

   {{< /alert >}}

1. **保存**を選択します。

ポリシーは、選択したスケジュール間隔で実行されます。

{{< alert type="note" >}}

ポリシーを編集してもう一度**保存**を選択すると、間隔がリセットされます。

{{< /alert >}}

### 正規表現パターンの例 {#regex-pattern-examples}

クリーンアップポリシーは、UIとAPIの両方で、保持または削除するタグを決定するために正規表現パターンを使用します。

GitLabは、クリーンアップポリシーの正規表現に[RE2構文](https://github.com/google/re2/wiki/Syntax)を使用します。

使用できる正規表現パターンの例を次に示します:

- すべてのタグに一致:

  ```plaintext
  .*
  ```

  このパターンは、有効期限の正規表現のデフォルト値です。

- `v`で始まるタグに一致:

  ```plaintext
  v.+
  ```

- `main`という名前のタグのみに一致:

  ```plaintext
  main
  ```

- `release`という名前であるか、またはそれで始まるタグに一致:

  ```plaintext
  release.*
  ```

- `v`で始まるタグ、`main`という名前のタグ、または`release`で始まるタグに一致:

  ```plaintext
  (?:v.+|main|release.*)
  ```

### リソースを節約するためにクリーンアップ制限を設定する {#set-cleanup-limits-to-conserve-resources}

{{< history >}}

- 機能フラグ`container_registry_expiration_policies_throttling`は、GitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84996)されました。

{{< /history >}}

クリーンアップポリシーは、バックグラウンドプロセスとして実行されます。このプロセスは複雑で、削除するタグの数によっては、プロセスの完了に時間がかかる場合があります。

次のアプリケーション設定を使用して、サーバーリソースの不足を防ぐことができます:

- `container_registry_expiration_policies_worker_capacity`: 同時に実行されるクリーンアップワーカーの最大数。この値は、`0`以上である必要があります。小さい数から始めて、バックグラウンドワーカーが使用するリソースをモニタリングした後で増やすことをおすすめします。すべてのワーカーを削除してクリーンアップポリシーを実行しないようにするには、これを`0`に設定します。デフォルト値は`4`です。
- `container_registry_delete_tags_service_timeout`: クリーンアッププロセスがタグのバッチを削除するのにかかる最大時間（秒単位）。デフォルト値は`250`です。
- `container_registry_cleanup_tags_service_max_list_size`: 1回の実行で削除できるタグの最大数。それ以上のタグは別の実行で削除する必要があります。小さい数から始めて、コンテナイメージが適切に削除されることを確認した後で増やすことをおすすめします。デフォルト値は`200`です。
- `container_registry_expiration_policies_caching`: ポリシーの実行中に、タグ作成のタイムスタンプのキャッシュを有効または無効にします。キャッシュされたタイムスタンプは、Redisに保存されます。デフォルトでは有効になっています。

GitLab Self-Managedインスタンスの場合、これらの設定は[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)で更新できます:

```ruby
ApplicationSetting.last.update(container_registry_expiration_policies_worker_capacity: 3)
```

これらの設定は[**管理者**エリア](../../../administration/admin_area.md)でも利用できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **Container Registry**（コンテナレジストリ）を展開します。

### クリーンアップポリシーAPIを使用する {#use-the-cleanup-policy-api}

GitLab APIを使用して、クリーンアップポリシーを設定、更新、無効にできます。

例:

- すべてのタグを選択し、イメージごとに少なくとも1つのタグを保持し、14日より古いタグをクリーンアップし、月に1回実行し、`main`という名前のイメージを保持し、ポリシーを有効にします:

  ```shell
  curl --fail-with-body --request PUT --header 'Content-Type: application/json;charset=UTF-8'
       --header "PRIVATE-TOKEN: <your_access_token>" \
       --data-binary '{"container_expiration_policy_attributes":{"cadence":"1month","enabled":true,"keep_n":1,"older_than":"14d","name_regex":".*","name_regex_keep":".*-main"}}' \
       "https://gitlab.example.com/api/v4/projects/2"
  ```

APIを使用する場合の`cadence`の有効な値は次のとおりです:

- `1d`（毎日）
- `7d`（毎週）
- `14d`（2週間ごと）
- `1month`（毎月）
- `3month`（四半期ごと）

APIを使用する場合の`keep_n`（イメージ名ごとに保持されるタグの数）の有効な値は次のとおりです:

- `1`
- `5`
- `10`
- `25`
- `50`
- `100`

APIを使用する場合の`older_than`（タグが自動的に削除されるまでの日数）の有効な値は次のとおりです:

- `7d`
- `14d`
- `30d`
- `90d`

詳細については、: [プロジェクトAPIを編集する](../../../api/projects.md#edit-a-project)方法に関するAPIドキュメントを参照してください。

### 外部コンテナレジストリで使用する {#use-with-external-container-registries}

[外部コンテナレジストリ](../../../administration/packages/container_registry.md#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint)を使用する場合、プロジェクトでクリーンアップポリシーを実行すると、パフォーマンス上のリスクが生じる可能性があります。数千個のタグを削除するポリシーをプロジェクトで実行すると、GitLabのバックグラウンドジョブがバックアップされるか、完全に失敗する可能性があります。

## コンテナレジストリのその他のストレージ削減オプション {#more-container-registry-storage-reduction-options}

プロジェクトで使用されるコンテナレジストリのストレージを削減するために使用できるその他のオプションを次に示します:

- [GitLab UI](delete_container_registry_images.md#use-the-gitlab-ui)を使用して、個別のイメージタグまたはすべてのタグを含むリポジトリ全体を削除します。
- APIを使用して[個別のイメージタグを削除](../../../api/container_registry.md#delete-a-registry-repository-tag)します。
- APIを使用して、[すべてのタグを含むコンテナレジストリリポジトリ全体を削除](../../../api/container_registry.md#delete-registry-repository)します。
- APIを使用して、[レジストリリポジトリタグを一括削除](../../../api/container_registry.md#delete-registry-repository-tags-in-bulk)します。

## トラブルシューティング {#troubleshooting}

### ストレージサイズを入手できない {#storage-size-is-not-available}

コンテナレジストリのストレージサイズ情報を確認できない場合:

1. [メタデータデータベースが適切に設定されている](../../../administration/packages/container_registry_metadata_database.md)ことを管理者に確認してもらいます。
1. レジストリストレージのバックエンドが正しく設定され、アクセス可能であることを確認します。
1. ストレージ関連のエラーについて、レジストリログを確認します:

   ```shell
   sudo gitlab-ctl tail registry
   ```

### `Something went wrong while updating the cleanup policy.` {#something-went-wrong-while-updating-the-cleanup-policy}

このエラーメッセージが表示された場合は、正規表現パターンが有効であることを確認してください。

`Golang`フレーバーを使用して、[regex101正規表現テスター](https://regex101.com/)でテストできます。いくつかの一般的な[正規表現パターンの例](#regex-pattern-examples)を確認してください。

### クリーンアップポリシーがタグを削除しない {#the-cleanup-policy-doesnt-delete-any-tags}

これにはさまざまな理由が考えられます:

- GitLab Self-Managedを使用していて、コンテナリポジトリに1,000個以上のタグがある場合は、[コンテナレジストリのトークンの有効期限切れの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/288814)が発生し、ログに`error authorizing context: invalid token`と記録される可能性があります。

  これを修正するために、次の2つの回避策を使用できます:

  - [クリーンアップポリシーの制限を設定](reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)します。これにより、クリーンアップの実行時間が制限され、期限切れのトークンエラーが回避されます。

  - コンテナレジストリの認証トークンの[有効期限の遅延を延長](../../../administration/packages/container_registry.md#increase-token-duration)します。デフォルトは5分です。

または、削除するタグのリストを生成し、そのリストを使用してタグを削除することもできます。リストを作成してタグを削除するには:

1. 次のShellスクリプトを実行します。`for`ループの直前のコマンドは、ループの開始時に`list_o_tags.out`が必ず再初期化されるようにします。このコマンドを実行すると、すべてのタグの名前が`list_o_tags.out`ファイルに書き込まれます:

   ```shell
   # Get a list of all tags in a certain container repository while considering [pagination](../../../api/rest/_index.md#pagination)
   echo -n "" > list_o_tags.out; for i in {1..N}; do curl --fail-with-body --header 'PRIVATE-TOKEN: <PAT>' "https://gitlab.example.com/api/v4/projects/<Project_id>/registry/repositories/<container_repo_id>/tags?per_page=100&page=${i}" | jq '.[].name' | sed 's:^.\(.*\).$:\1:' >> list_o_tags.out; done
   ```

   Railsコンソールにアクセスできる場合は、次のコマンドを入力して、日付で制限されたタグのリストを取得できます:

   ```shell
   output = File.open( "/tmp/list_o_tags.out","w" )
   Project.find(<Project_id>).container_repositories.find(<container_repo_id>).tags.each do |tag|
     output << tag.name + "\n" if tag.created_at < 1.month.ago
   end;nil
   output.close
   ```

   この一連のコマンドは、`created_at`日付が1か月よりも古いすべてのタグをリストした`/tmp/list_o_tags.out`ファイルを作成します。

1. 保持するタグを`list_o_tags.out`ファイルから削除します。たとえば、`sed`を使用してファイルを解析し、タグを削除できます。

   {{< tabs >}}

   {{< tab title="Linux" >}}

   ```shell
   # Remove the `latest` tag from the file
   sed -i '/latest/d' list_o_tags.out

   # Remove the first N tags from the file
   sed -i '1,Nd' list_o_tags.out

   # Remove the tags starting with `Av` from the file
   sed -i '/^Av/d' list_o_tags.out

   # Remove the tags ending with `_v3` from the file
   sed -i '/_v3$/d' list_o_tags.out
   ```

   {{< /tab >}}

   {{< tab title="macOS" >}}

   ```shell
   # Remove the `latest` tag from the file
   sed -i .bak '/latest/d' list_o_tags.out

   # Remove the first N tags from the file
   sed -i .bak '1,Nd' list_o_tags.out

   # Remove the tags starting with `Av` from the file
   sed -i .bak '/^Av/d' list_o_tags.out

   # Remove the tags ending with `_v3` from the file
   sed -i .bak '/_v3$/d' list_o_tags.out
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. `list_o_tags.out`ファイルを再確認して、削除するタグのみが含まれていることを確認します。

1. 次のShellスクリプトを実行して、`list_o_tags.out`ファイル内のタグを削除します:

   ```shell
   # loop over list_o_tags.out to delete a single tag at a time
   while read -r LINE || [[ -n $LINE ]]; do echo ${LINE}; curl --fail-with-body --request DELETE --header 'PRIVATE-TOKEN: <PAT>' "https://gitlab.example.com/api/v4/projects/<Project_id>/registry/repositories/<container_repo_id>/tags/${LINE}"; sleep 0.1; echo; done < list_o_tags.out > delete.logs
   ```
