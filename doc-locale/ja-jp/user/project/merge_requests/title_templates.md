---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: マージリクエストのタイトルテンプレートを使用して、プロジェクトの新しいマージリクエストのデフォルトタイトル形式を設定します。
title: マージリクエストのタイトルテンプレート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.11で`mr_default_title_template`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442)されました。デフォルトでは無効になっています。この機能は[ベータ版](../../../policy/development_stages_support.md#beta)です。
- GitLab 19.0で一般提供になりました。機能フラグ`mr_default_title_template`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642)されました。

{{< /history >}}

マージリクエストのタイトルテンプレートは、プロジェクトの新しいマージリクエストのデフォルトタイトルを定義します。テンプレートを使用して、チーム全体でマージリクエストの命名規則を標準化することができます。

テンプレートは、ソースブランチ名や最初のコミットメッセージのような値に展開する変数をサポートしています。ユーザーは、マージリクエストを作成する前にタイトルを編集できます。

## マージリクエストタイトルのテンプレートを設定する {#configure-a-merge-request-title-template}

前提条件: 

- プロジェクトのメンテナーロール以上が必要です。

マージリクエストのタイトルテンプレートを設定するには:

1. 左サイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **マージリクエストタイトルのテンプレート**までスクロールします。
1. 静的テキストと[サポートされている変数](#supported-variables)を使用してテンプレートを入力します。テンプレートは100文字に制限されています。
1. **変更を保存**を選択します。

テンプレートを削除してデフォルトの動作に復元するには、テンプレートフィールドをクリアし、**変更を保存**を選択します。

## サポートされている変数 {#supported-variables}

タイトルテンプレートは次の変数をサポートしています:

| 変数               | 説明                                                                                                    | 出力例 |
|------------------------|----------------------------------------------------------------------------------------------------------------|----------------|
| `%{source_branch}`     | ソースブランチの名前。                                                                                 | `my-feature-branch` |
| `%{target_branch}`     | ターゲットブランチの名前。                                                                                 | `main`         |
| `%{title_from_branch}` | 人間が読める形式に変換されたソースブランチ名。ハイフンとアンダースコアはスペースに置き換えられます。 | `My feature branch` |
| `%{first_commit_title}` | マージリクエストの最初のコミットの件名（最初の行）。                                            | `Update README.md` |
| `%{issue_id}`           | ソースブランチ名を通じてリンクされたイシューのIID（例: `123`からの`123-fix-bug`）。イシューが検出されない場合は空白。 | `123` |
| `%{issue_title}`        | ソースブランチ名を通じてリンクされたイシューのタイトル。イシューが検出されない場合は空白。                   | `Fix login bug` |

## テンプレートの例 {#template-examples}

| テンプレート                                          | 結果 |
|---------------------------------------------------|--------|
| `%{source_branch}`                                | `my-feature-branch` |
| `%{title_from_branch}`                            | `My feature branch` |
| `%{first_commit_title}`                           | `Update README.md` |
| `Draft: %{title_from_branch}`                     | `Draft: My feature branch` |
| `[%{source_branch}] %{first_commit_title}`        | `[my-feature-branch] Update README.md` |
| `Resolve %{issue_id} "%{issue_title}"`            | `Resolve 123 "Fix login bug"` |

## タイトルのテンプレート割り当て {#title-template-assignment}

マージリクエストを作成すると、GitLabは次の順序でタイトルを割り当てます:

1. タイトルを指定した場合、GitLabがそれを使用します。
1. タイトルテンプレートが設定されている場合、GitLabは展開されたテンプレートを使用します。
1. テンプレートが設定されていない場合、GitLabは[デフォルトのタイトル動作](#default-title-behavior)を使用します。

## デフォルトのタイトル動作 {#default-title-behavior}

タイトルテンプレートが設定されておらず、タイトルを指定しない場合、GitLabは次の条件を順に確認してタイトルを生成します:

1. マージリクエストに単一のコミットがある場合、そのコミットのタイトル。
1. マージリクエストに複数のコミットがある場合、複数行のコミットメッセージを持つ最初のコミットのタイトル。
1. ソースブランチ名がイシューIIDの後にハイフンが続く場合（例: `123-fix-typo`）、タイトルは`Resolve "<your_issue_title>"`になります。
1. それ以外の場合、ハイフンとアンダースコアがスペースに置き換えられたソースブランチ名。

マージリクエストにコミットがない場合、またはドラフトとしてマークした場合、GitLabはタイトルの前に`Draft:`を追加します。

## 関連トピック {#related-topics}

- [コミットメッセージテンプレート](commit_templates.md)
- [マージリクエストを作成する](creating_merge_requests.md)
