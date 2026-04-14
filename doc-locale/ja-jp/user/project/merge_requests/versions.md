---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 単一のマージリクエストに含まれるプッシュを比較するために、差分のバージョンを使用します。
title: マージリクエスト差分バージョン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストを作成する際、比較する2つのブランチを選択します。2つのブランチ間の差異は、マージリクエストで差分として表示されます。マージリクエストに接続されているブランチにコミットをプッシュするたびに、GitLabはマージリクエスト差分を新しい差分バージョンに更新します。

> [!note]
> 差分バージョンは、各コミットではなく、各プッシュで更新されます。1つのプッシュに複数のコミットが含まれる場合、新しい差分バージョンは1つだけ作成されます。

デフォルトでは、GitLabはソースブランチ (`feature`) での最新のプッシュを、ターゲットブランチの最新のコミット (多くの場合`main`) と比較します。

## 差分バージョンの比較 {#compare-diff-versions}

ブランチに複数回プッシュした場合、以前の各プッシュからの差分バージョンを比較できます。マージリクエストに多数の変更や、同じファイルに対する連続した変更が含まれている場合、より少ない数の変更を比較したいことがあります。

前提条件: 

- マージリクエストブランチには、複数のプッシュからのコミットが含まれている必要があります。同じプッシュ内の個々のコミットは、新しい差分バージョンを生成しません。

差分バージョンを比較するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **マージリクエスト**を選択します。
1. マージリクエストを選択します。
1. このマージリクエストの現在の差分バージョンを表示するには、**変更**を選択します。
1. **比較** ({{< icon name="file-tree" >}}) の横で、比較するプッシュを選択します。この例では、`main`をブランチの最新のプッシュ (最新の差分バージョン) と比較しています:

   ![Merge request versions dropdown list](img/versions_dropdown_v16_6.png)

   この例のブランチには4つのコミットがありますが、2つのコミットが同時にプッシュされたため、ブランチには3つの差分バージョンしか含まれていません。

## システムノートから差分バージョンを表示 {#view-diff-versions-from-a-system-note}

GitLabは、マージリクエストのブランチに新しい変更をプッシュするたびに、マージリクエストにシステムノートを追加します。この例では、1回のプッシュで2つのコミットが追加されています:

![Merge request versions system note](img/versions_system_note_v16_6.png)

そのコミットの差分を表示するには、コミットSHAを選択します。

詳細については、[マージリクエストでシステムノートを表示またはフィルタリングする方法](../system_notes.md#on-a-merge-request)を参照してください。

## 関連トピック {#related-topics}

- [管理者のためのマージリクエスト差分ストレージ](../../../administration/merge_request_diffs.md)
