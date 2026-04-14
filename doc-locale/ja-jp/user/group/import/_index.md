---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ダイレクト転送を使用してGitLabデータを移行する
description: "直接接続を使用してGitLabデータを移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.6の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/339941)。
- GitLab 15.8で`bulk_import_enabled`の新しいアプリケーション設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383268)されました。`bulk_import`機能フラグは削除されました。
- 機能フラグ`bulk_import_projects`は、GitLab 15.10で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/339941)されました。

{{< /history >}}

GitLabグループは、以下のように移行できます。

- GitLab Self-ManagedおよびGitLab DedicatedからGitLab.comへ
- GitLab.comからGitLab Self-ManagedおよびGitLab Dedicatedへ
- あるGitLab Self-ManagedまたはGitLab Dedicatedインスタンスから別のインスタンスへ
- 同じGitLabインスタンス上

直接転送による移行では、グループの新しいコピーが作成されます。グループをコピーする代わりに移動する場合は、グループが同じGitLabインスタンスにあれば、[グループを転送](../manage.md#transfer-a-group)できます。グループの転送は、移行と比べてより高速かつ完全なオプションです。

グループは、次の2つの方法で移行できます。

- 直接転送による方法（推奨）
- [エクスポートファイルをアップロード](../../project/settings/import_export.md)する方法

GitLab.comからGitLab Self-ManagedまたはGitLab Dedicatedインスタンスに移行する場合、管理者はインスタンス上にユーザーを作成できます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、デフォルトで[グループ項目の移行](migrated_items.md#migrated-group-items)は利用できません。管理者は、[アプリケーション設定で有効にする](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)ことで、この機能を利用できるようになります。

直接転送によるグループの移行では、グループがある場所から別の場所にコピーされます。次のことができます: 

- 一度に多くのグループをコピーする。
- GitLab UIで、トップレベルグループを以下にコピーする。
  - 別のトップレベルグループ。
  - 既存のトップレベルグループのサブグループ。
  - GitLab.comを含む別のGitLabインスタンス。
- [グループおよびプロジェクトのダイレクト転送による移行API](../../../api/bulk_imports.md)で、トップレベルグループとサブグループをこれらの場所にコピーします。
- プロジェクトの有無にかかわらずグループをコピーします。プロジェクトを含むグループのコピーは、GitLab.comでデフォルトで利用可能です。

すべてのグループおよびプロジェクトリソースがコピーされるわけではありません。コピーされるリソースのリストを以下に示します。

- [移行されるグループ項目](migrated_items.md#migrated-group-items)。
- [移行されるプロジェクト項目](migrated_items.md#migrated-project-items)。

移行を開始した後、移行元インスタンスでインポート対象のグループまたはプロジェクトを変更しないでください。これらの変更が移行先インスタンスにコピーされない可能性があります。

ダイレクト転送による移行について、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/284495)でフィードバックをお寄せください。

## 特定のプロジェクトを移行する {#migrating-specific-projects}

GitLab UIで直接転送を使用してグループを移行すると、グループ内のすべてのプロジェクトが移行されます。直接転送を使用してグループ内の特定のプロジェクトのみを移行する場合は、[API](../../../api/bulk_imports.md#start-a-group-or-project-migration)を使用する必要があります。

## 既知の問題 {#known-issues}

- [イシュー406685](https://gitlab.com/gitlab-org/gitlab/-/issues/406685)のため、ファイル名が255文字を超えるファイルは移行されません。
- GitLab 16.1および以前では、[スケジュールされたスキャン実行ポリシー](../../application_security/policies/scan_execution_policies.md)とダイレクト転送を併用しないでください。
- GitLab 16.9以前では、[イシュー438422](https://gitlab.com/gitlab-org/gitlab/-/issues/438422)のため、`DiffNote::NoteDiffFileCreationError`エラーが表示されることがあります。このエラーが発生すると、マージリクエストの差分に関するノートの差分が表示されませんが、ノートとマージリクエストは引き続きインポートされます。
- ソースインスタンスからマッピングされる場合、共有メンバーシップが移行先にすでに存在しない限り、共有メンバーは移行先で直接メンバーとしてマッピングされます。つまり、ソースインスタンスのトップレベルグループを移行先のトップレベルグループにインポートすると、ソースのトップレベルグループに必要な共有メンバーシップ階層の詳細が含まれていても、常にプロジェクト内の直接メンバーにマッピングされるということです。共有メンバーシップの完全なマッピングのサポートは、[イシュー458345](https://gitlab.com/gitlab-org/gitlab/-/issues/458345)で提案されています。
- GitLab 17.0、17.1、17.2では、インポートされたエピックと作業アイテムは、元の作成者ではなく、インポートするユーザーにマッピングされます。
- ダイレクト転送は、異なるソースグループからのグループやプロジェクトを単一の宛先グループに統合することをサポートしていません。グループまたはプロジェクトを統合するには、移行前にソースインスタンスで再構築するか、[プレースホルダーユーザーの再割り当てが完了した後](../../import/mapping.md#completing-the-reassignment)に宛先インスタンスで再構築します。[イシュー589460](https://gitlab.com/gitlab-org/gitlab/-/work_items/589460)を参照してください。

## 移行期間を見積もる {#estimating-migration-duration}

直接転送で移行期間を見積もるのは困難です。次の要因が移行期間に影響を与えるためです。

- ソースおよび移行先GitLabインスタンスで使用可能なハードウェアおよびデータベースリソース。ソースおよび移行先インスタンス上のリソースが多いほど、移行期間が短くなる可能性があります。理由は次のとおりです。
  - ソースインスタンスがAPIリクエストを受信し、エクスポートするエンティティを抽出してシリアル化するため。
  - 移行先インスタンスがジョブを実行し、そのデータベースにエンティティを作成するため。
- エクスポートするデータの複雑さとサイズ。たとえば、それぞれに1000件のマージリクエストがある2つの異なるプロジェクトを移行するとします。一方のプロジェクトのマージリクエストに添付ファイル、コメント、その他のアイテムが多数含まれている場合、2つのプロジェクトの移行にかかる時間が大きく異なる可能性があります。したがって、プロジェクトの移行にかかる時間を見積もる際に、プロジェクトのマージリクエストの数はあまり参考になりません。

移行を確実に予測するための正確な手立てはありません。ただし、プロジェクトリレーションをインポートする各パイプラインワーカーの平均時間を見ることで、プロジェクトのインポートにかかる時間を把握しやすくなります。

| プロジェクトリソースの種類       | レコードのインポートにかかる平均時間（秒） |
|:----------------------------|:---------------------------------------------|
| 空のプロジェクト               | 2.4                                          |
| リポジトリ                  | 20                                           |
| プロジェクト属性          | 1.5                                          |
| メンバー                     | 0.2                                          |
| ラベル                      | 0.1                                          |
| マイルストーン                  | 0.07                                         |
| バッジ                      | 0.1                                          |
| イシュー                      | 0.1                                          |
| スニペット                    | 0.05                                         |
| スニペットリポジトリ        | 0.5                                          |
| ボード                      | 0.1                                          |
| マージリクエスト              | 1                                            |
| 外部プルリクエスト      | 0.5                                          |
| 保護ブランチ          | 0.1                                          |
| プロジェクト機能             | 0.3                                          |
| コンテナ有効期限ポリシー | 0.3                                          |
| サービスデスクの設定        | 0.3                                          |
| リリース                    | 0.1                                          |
| CIパイプライン                | 0.2                                          |
| コミットノート                | 0.05                                         |
| Wiki                        | 10                                           |
| アップロード                     | 0.5                                          |
| LFSオブジェクト                 | 0.5                                          |
| デザイン                      | 0.1                                          |
| Auto DevOps                 | 0.1                                          |
| パイプラインスケジュール          | 0.5                                          |
| 参照                  | 5                                            |
| プッシュルール                   | 0.1                                          |

移行期間を予測するのは困難ですが、以下のことが観察されています:

- 100個のプロジェクト（19.9k件のイシュー、83k件のマージリクエスト、100k+件のパイプライン）を8時間で移行。
- 1926個のプロジェクト（22k件のイシュー、160k件のマージリクエスト、110万件のパイプライン）を34時間で移行。

大規模なプロジェクトを移行する際にタイムアウトや移行期間に関する問題が発生した場合は、[移行期間の短縮](troubleshooting.md#migrations-are-slow-or-timing-out)を試してください。

## 制限 {#limits}

デフォルトの制限については、[ダイレクト転送による移行の制限](../../../administration/instance_limits.md#direct-transfer-migration)を参照してください。

次のAPIを使用して、最大リレーションサイズ制限をテストできます。

- [グループリレーションエクスポートAPI](../../../api/group_relations_export.md)
- [プロジェクトリレーションエクスポートAPI](../../../api/project_relations_export.md)

いずれかのAPIが最大リレーションサイズ制限を超えるファイルを生成すると、直接転送によるグループの移行は失敗します。

## 表示レベルのルール {#visibility-rules}

移行後は次のようになります。

- プライベートグループとプロジェクトは、プライベートのままです。
- 内部のグループとプロジェクトは次の通りです。
  - 内部の表示レベルが[制限](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)されていない限りは、内部グループにコピーされた場合、内部のままです。その場合、グループとプロジェクトはプライベートに変わります。
  - プライベートグループにコピーされると、プライベートに変わります。
- パブリックとなっているグループとプロジェクトは次の通りです。
  - パブリックの表示レベルが[制限](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)されていない限りは、パブリックグループにコピーされた場合、パブリックのままです。その場合、グループとプロジェクトは内部になります。
  - 内部の表示レベルが[制限](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)されていない限りは、内部グループにコピーされた場合、内部に変わります。その場合、グループとプロジェクトはプライベートに変わります。
  - プライベートグループにコピーされると、プライベートに変わります。

ソースインスタンスでプライベートネットワークを使用してコンテンツを一般公開から隠している場合は、移行先インスタンスでも同様の設定にするか、プライベートグループにインポートするようにしてください。

## 直接転送プロセスで移行する {#migration-by-direct-transfer-process}

[直接転送を使用してグループとプロジェクトを移行する](direct_transfer_migrations.md)を参照してください。
