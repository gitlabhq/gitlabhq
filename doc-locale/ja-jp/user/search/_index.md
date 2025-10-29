---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabでの検索
description: 基本的な検索、高度な検索、完全一致コードの検索、検索スコープ、コミットSHA検索。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

拡大するコードベースや組織で必要なものを見つけましょう。プロジェクト全体の特定のコード、イシュー、マージリクエスト、その他のコンテンツを検索することで、時間を節約できます。ニーズに応じて、**basic search**（基本的な検索）、[**advanced search**（高度な検索）](advanced_search.md) 、[**exact code search**（完全一致コードの検索）](exact_code_search.md)の3種類の検索から選択できます。

コードの検索の場合、GitLabでは次の順序で各タイプを使用します:

- **完全一致コードの検索**: 完全一致モードと正規表現モードを使用できます。
- **高度な検索**: 完全一致コードの検索が利用できない場合に使用します。
- **Basic search**（基本的な検索）: 完全一致コードの検索と高度な検索が利用できない場合、またはデフォルト以外のブランチに対して検索する場合に使用します。このタイプは、グループ検索またはグローバル検索をサポートしていません。

## 使用可能なスコープ {#available-scopes}

スコープは、検索するデータの種類を表します。基本的な検索では、次のスコープを使用できます:

| スコープ          | グローバル<sup>1</sup>                         | グループ                                       | プロジェクト |
|----------------|:-------------------------------------------:|:-------------------------------------------:|:-------:|
| コード           | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 |
| コメント       | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 |
| コミット        | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 |
| エピック          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 |
| イシュー         | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| マージリクエスト | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| マイルストーン     | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| プロジェクト       | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 |
| ユーザー          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Wiki          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 |

**Footnotes**（補足説明）:

1. 管理者は、[グローバル検索のスコープを無効にできます](#disable-global-search-scopes)。

## 検索タイプを指定する {#specify-a-search-type}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161999)されました。

{{< /history >}}

検索タイプを指定するには、`search_type` URLパラメータを次のように設定します:

- [完全一致コードの検索](exact_code_search.md)の場合は`search_type=zoekt`
- [高度な検索](advanced_search.md)の場合は`search_type=advanced`
- 基本的な検索の場合は`search_type=basic`

`search_type`は、非推奨の`basic_search`パラメータを置き換えます。詳細については、[イシュー477333](https://gitlab.com/gitlab-org/gitlab/-/issues/477333)を参照してください。

## 検索アクセスを制限する {#restrict-search-access}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- グローバル検索を認証済みユーザーのみに制限する機能は、GitLab 13.4で`block_anonymous_global_searches`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41041)されました。デフォルトでは無効になっています。
- 未認証ユーザーに検索を許可する機能は、GitLab 16.7で`allow_anonymous_searches`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138975)されました。デフォルトでは有効になっています。
- グローバル検索を認証済みユーザーのみに制限する機能は、GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186727)になりました。機能フラグ`block_anonymous_global_searches`は削除されました。
- 未認証ユーザーに検索を許可する機能は、GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190090)になりました。機能フラグ`allow_anonymous_searches`は削除されました。

{{< /history >}}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

デフォルトでは、`/search`へのリクエストとグローバル検索は、未認証ユーザーも利用できます。

`/search`を認証済みユーザーのみに制限するには、次のいずれかを実行します:

- プロジェクトまたはグループの[表示レベルを制限](../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)します。
- **管理者**エリアでアクセスを制限します:

  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. **設定** > **検索**を選択します。
  1. **高度な検索**を展開します。
  1. **未承認ユーザーが検索の使用を許可する**チェックボックスをオフにします。
  1. **変更を保存**を選択します。

グローバル検索を認証済みユーザーのみに制限するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. **グローバル検索を承認されたユーザーだけに制限する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## グローバル検索スコープを無効にする {#disable-global-search-scopes}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179688)されました。

{{< /history >}}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

インスタンスのグローバル検索のパフォーマンスを向上させるには、1つまたは複数の検索スコープを無効にします。GitLab Self-Managedインスタンスでは、すべてのグローバル検索スコープがデフォルトで有効になっています。

1つまたは複数のグローバル検索スコープを無効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. 無効にするスコープのチェックボックスをオフにします。
1. **変更を保存**を選択します。

## グローバル検索の検証 {#global-search-validation}

{{< history >}}

- イシュー検索での部分一致のサポートは、GitLab 14.9で`issues_full_text_search`[フラグ](../../administration/feature_flags/_index.md)とともに[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71913)されました。デフォルトでは無効になっています。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124703)になりました。機能フラグ`issues_full_text_search`は削除されました。

{{< /history >}}

グローバル検索では、以下を含む検索はすべて不正なものとして無視され、ログに記録されます:

- 2文字未満の語句
- 100文字を超える語句（URL検索語句は200文字を超えることができません）
- ストップワードのみ（例: `the`、`and`、`if`）
- 不明な`scope`
- 完全に数値ではない`group_id`または`project_id`
- [Git refname](https://git-scm.com/docs/git-check-ref-format)で許可されていない特殊文字を含む`repository_ref`または`project_ref`

グローバル検索では、以下を超える検索のみにエラーフラグが付きます:

- 4,096文字
- 64語

部分一致はイシュー検索ではサポートされていません。たとえば、`play`のイシューを検索すると、クエリは`display`を含むイシューを返しません。ただし、クエリは考えられる文字列のバリエーション（例: `plays`）すべてに一致しています。

## オートコンプリート候補 {#autocomplete-suggestions}

{{< history >}}

- GitLab 17.10で、`users_search_scoped_to_authorized_namespaces_advanced_search`、`users_search_scoped_to_authorized_namespaces_basic_search`、`users_search_scoped_to_authorized_namespaces_basic_search_by_ids`という名前の[フラグ](../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/442091)。承認されたプロジェクトとグループのユーザーのみを表示します。デフォルトでは無効になっています。
- GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185577)になりました。機能フラグ`users_search_scoped_to_authorized_namespaces_advanced_search`、`users_search_scoped_to_authorized_namespaces_basic_search`、および`users_search_scoped_to_authorized_namespaces_basic_search_by_ids`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

検索ボックスに入力すると、次のオートコンプリート候補が表示されます:

- [プロジェクト](#search-for-a-project-by-full-path)とグループ
- 承認されたプロジェクトとグループのユーザー
- ヘルプページ
- プロジェクト機能（マイルストーンなど）
- 設定（ユーザー設定など）
- 最近表示したマージリクエスト
- 最近表示したイシューとエピック
- プロジェクト内のイシューの[GitLab Flavored Markdown参照](../markdown.md#gitlab-specific-references)

## すべてのGitLabで検索する {#search-in-all-gitlab}

すべてのGitLabで検索するには:

1. 左側のサイドバーで、**検索または移動先**を選択します。
1. 検索クエリを入力します。2文字以上入力する必要があります。
1. <kbd>Enter</kbd>キーを押して検索するか、リストから選択します。

結果が表示されます。結果をフィルター処理するには、左側のサイドバーでフィルターを選択します。

## プロジェクトで検索する {#search-in-a-project}

プロジェクトで検索するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **検索または移動先**を再度選択し、検索する文字列を入力します。
1. <kbd>Enter</kbd>キーを押して検索するか、リストから選択します。

結果が表示されます。結果をフィルター処理するには、左側のサイドバーでフィルターを選択します。

## フルパスでプロジェクトを検索 {#search-for-a-project-by-full-path}

{{< history >}}

- GitLab 15.9で`full_path_project_search`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108906)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114932)になりました。機能フラグ`full_path_project_search`は削除されました。

{{< /history >}}

検索ボックスに完全なパス（ネームスペースを含む）を入力して、プロジェクトを検索できます。プロジェクトのパスを入力すると、[オートコンプリート](#autocomplete-suggestions)候補が表示されます。

次に例を示します:

- `gitlab-org/gitlab`は、`gitlab-org`ネームスペース内の`gitlab`プロジェクトを検索します。
- `gitlab-org/`は、`gitlab-org`ネームスペースに属するプロジェクトのオートコンプリート候補を表示します。

## 検索結果にアーカイブされたプロジェクトを含める {#include-archived-projects-in-search-results}

{{< history >}}

- GitLab 16.1で`search_projects_hide_archived`[フラグ](../../administration/feature_flags/_index.md)とともにプロジェクト検索に[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121981)されました。デフォルトでは無効になっています。
- GitLab 16.6で、すべての検索スコープに対して[一般提供になりました](https://gitlab.com/groups/gitlab-org/-/epics/10957)。

{{< /history >}}

デフォルトでは、アーカイブされたプロジェクトは検索結果から除外されます。検索結果にアーカイブされたプロジェクトを含めるには、次の操作を行います:

1. 検索ページの左側のサイドバーで、**アーカイブを含む**チェックボックスをオンにします。
1. 左側のサイドバーで、**適用**を選択します。

## コードを検索する {#search-for-code}

プロジェクトでコードを検索するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **検索または移動先**を再度選択し、検索するコードを入力します。
1. <kbd>Enter</kbd>キーを押して検索するか、リストから選択します。

コード検索には、ファイル内の最初の結果のみが表示されます。すべてのGitLabでコードを検索するには、管理者に[高度な検索](advanced_search.md)を有効化するよう依頼してください。

### コード検索からGit blameを表示する {#view-git-blame-from-code-search}

{{< history >}}

- GitLab 14.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/327052)。

{{< /history >}}

検索結果を見つけたら、結果が見つかった行に最後に変更を加えたユーザーを表示できます。

1. コード検索結果から、行番号にカーソルを合わせます。
1. 左側で、**blameの表示**の表示を選択します。

### コード検索結果を言語別にフィルタリングする {#filter-code-search-results-by-language}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342651)されました。

{{< /history >}}

1つ以上の言語でコード検索結果をフィルタリングするには:

1. コード検索ページの左側のサイドバーで、1つ以上の言語を選択します。
1. 左側のサイドバーで、**適用**を選択します。

## コミットSHAを検索する {#search-for-a-commit-sha}

コミットSHAを検索するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 再度**検索または移動先**を選択し、検索するコミットSHAを入力します。
1. <kbd>Enter</kbd>キーを押して検索するか、リストから選択します。

単一の結果が返された場合、GitLabはコミット結果にリダイレクトし、検索結果ページに戻るオプションを提供します。

## 構文 {#syntax}

ベーシック検索は、次のオプションと完全に一致するサブストリングを使用します:

| 構文       | 説明                                     | 例 |
|--------------|-------------------------------------------------|---------|
| `filename:`  | ファイル名                                        | `filename:*spec.rb` |
| `path:`      | リポジトリの場所（完全一致または部分一致）   | `path:spec/workers/` |
| `extension:` | `.`なしのファイル拡張子（完全一致のみ） | `extension:js` |

### 例 {#examples}

<!-- markdownlint-disable MD044 -->

| クエリ                                 | 説明 |
|---------------------------------------|-------------|
| `rails -filename:gemfile.lock`        | `gemfile.lock`ファイルを除くすべてのファイルの`rails`を返します。 |
| `helper -extension:yml -extension:js` | `.yml`拡張子または`.js`拡張子のファイルを除く、すべてのファイルの`helper`を返します。 |
| `helper path:lib/git`                 | パスに`lib/git*`の付くすべてのファイル（`spec/lib/gitlab`など）の`helper`を返します。 |

<!-- markdownlint-enable MD044 -->
