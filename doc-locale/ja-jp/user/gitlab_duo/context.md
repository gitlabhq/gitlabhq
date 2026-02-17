---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoのコンテキスト認識
---

使用しているGitLab Duoの機能と使用場所に応じて、GitLab Duoが意思決定を行い、提案を行うのに役立つさまざまな情報が利用可能です。

情報は、以下の状況で利用可能です:

- 常時。
- お客様の場所に基づく（移動するとコンテキストが変化します）。
- 明示的に参照される場合。たとえば、URL、ID、またはパスで情報を記述する場合。

## GitLab Duo Chat {#gitlab-duo-chat}

{{< history >}}

- GitLab 18.6で現在のページタイトルとURLが[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209186)されました。

{{< /history >}}

次のコンテキストは、GitLab Duo Chatで利用できます。

### 常に利用可能 {#always-available}

- GitLabドキュメント。
- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- カーソルの前後のコードを含め、表示または編集しているファイルの内容。
- GitLab UIでチャットを使用する場合、現在のページタイトルとURL。
- `/refactor`、`/fix`、および`/tests`スラッシュコマンドは、最新の[リポジトリX-Rayレポート](../project/repository/code_suggestions/repository_xray.md)にアクセスできます。

### 場所に基づく {#based-on-location}

これらのリソースのいずれかを開いている場合、GitLab Duoはそれらについて認識します。

- ファイル（`/include`コマンドでインポートされたもの）
- ファイル内で選択されたコード
- イシュー（GitLab Duo Enterpriseのみ）
- エピック（GitLab Duo Enterpriseのみ）
- [その他の作業アイテムタイプ](../work_items/_index.md#work-item-types)（GitLab Duo Enterpriseのみ）

{{< alert type="note" >}}

IDEでは、既知の形式に一致するシークレットと機密情報値は、GitLab Duo Chatに送信される前に秘匿化されます。

{{< /alert >}}

マージリクエストにいる場合、UIでは、GitLab Duoは次のことも認識します:

- マージリクエスト自体（GitLab Duo Enterpriseのみ）。
- マージリクエスト内のコミット（GitLab Duo Enterpriseのみ）。
- マージリクエストパイプラインのCI/CDジョブ（GitLab Duo Enterpriseのみ）。

### 明示的に参照される場合 {#when-referenced-explicitly}

場所に基づいて利用可能なすべてのリソースは、IDまたはURLで明示的に参照する場合にも利用できます。

## ソフトウェア開発フロー {#software-development-flow}

次のコンテキストは、GitLab Duo Agent Platformのソフトウェア開発フローで使用できます。

### 常に利用可能 {#always-available-1}

- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- Gitで追跡されているプロジェクト全体とすべてのファイル。
- GitLabの[検索API](../../api/search.md)。これは、関連するイシューまたはマージリクエストを検索するために使用されます。

### 場所に基づく {#based-on-location-1}

- IDEで開いているファイル（コンテキストに使用したくない場合は、ファイルを閉じてください）。

### 明示的に参照される場合 {#when-referenced-explicitly-1}

- ファイル
- エピック
- イシュー
- マージリクエスト
- マージリクエストのパイプライン

## コード提案 {#code-suggestions}

次のコンテキストは、コード提案で利用できます。

### 常に利用可能 {#always-available-2}

- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- カーソルの前後のコンテンツを含め、表示または編集しているファイルの名前、拡張子、およびコンテンツ。

### 場所に基づく {#based-on-location-2}

- IDEのタブで開いているファイル。オプションですが、デフォルトでオンになっています。
  - これらのファイルは、プロジェクトの標準とプラクティスに関する情報をGitLab Duoに提供します。
  - コンテキストに使用したくない場合は、ファイルを閉じてください。
  - コード補完は、すべての[サポートされている言語](../project/repository/code_suggestions/supported_extensions.md#supported-languages-by-ide)を認識します。
  - コード生成は、次の言語のファイルのみを認識します: Go、Java、JavaScript、Kotlin、Python、Ruby、Rust、TypeScript（`.ts`および`.tsx`ファイル）、Vue、YAML。
- 表示または編集しているファイルにインポートされたファイル。オプションですが、デフォルトでオフになっています。
  - これらのファイルは、ファイルのクラスとメソッドに関する情報をGitLab Duoに提供します。
- エディタで選択されたコード。
- [リポジトリX-Rayファイル](../project/repository/code_suggestions/repository_xray.md)。

{{< alert type="note" >}}

既知の形式に一致するシークレットと機密情報値は、コード生成に使用される前に秘匿化されます。これは、`/include`を使用して追加されたファイルに適用されます。

{{< /alert >}}

#### コード提案がコンテキストに使用するものを変更する {#change-what-code-suggestions-uses-for-context}

コード提案が他のファイルをコンテキストとして使用するかどうかを変更できます。

##### 開いているファイルをコンテキストとして使用する {#using-open-files-as-context}

{{< history >}}

- GitLab 17.1で`advanced_context_resolver`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464767)されました。デフォルトでは無効になっています。
- GitLab 17.1で`code_suggestions_context`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。デフォルトでは無効になっています。
- VS Code用GitLab Workflow 4.20.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/276)されました。
- JetBrains用GitLab Duo 2.7.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/462)されました。
- 2024年7月16日にGitLab Neovimプラグインに[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/merge_requests/152)されました。
- GitLab 17.2のGitLab.comおよびGitLab 17.4のGitLab Self-Managedで、`advanced_context_resolver`と`code_suggestions_context`の機能フラグが有効になりました。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)。機能フラグ`code_suggestions_context`は削除されました。

{{< /history >}}

デフォルトでは、コード提案は、提案を行う際にIDEで開いているファイルをコンテキストとして使用します。ただし、この設定をオフにすることができます。

前提条件: 

- GitLab 17.2以降。コード提案をサポートする以前のバージョンのGitLabでは、開いているタブのコンテンツをプロジェクト内の他のファイルよりも重視することはできません。
- サポートされているプラグイン: 
  - VS Code用GitLab Workflow拡張機能6.2.2以降。
  - JetBrains IDE用GitLabプラグイン3.6.5以降。
  - Neovim用GitLabプラグイン1.1.0以降。
  - Visual Studio用GitLab拡張機能0.51.0以降。

コンテキストとして使用されている開いているファイルを変更するには、次のようにします:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. 上部のバーで、**Code** > **Settings** > **Extensions**に移動します。
1. リストでGitLabワークフローを検索し、歯車アイコンを選択します。
1. **Settings**を選択します。
1. **User**設定で、`open tabs`を検索します。
1. **GitLab** > **コード提案の下: Open Tabs Context**にある、**Use the contents of open tabs as context**を選択またはクリアします。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. IDEの上部のメニューバーに移動し、**Settings**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。
1. **Additional languages**で、**Send open tabs as context**を選択またはクリアします。
1. **Apply**または**Save**を選択します。

{{< /tab >}}

{{< /tabs >}}

##### インポートされたファイルをコンテキストとして使用する {#using-imported-files-as-context}

{{< history >}}

- GitLab 17.9で`code_suggestions_include_context_imports`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514124)されました。デフォルトでは無効になっています。
- GitLab 17.11の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/514124)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

IDEでインポートしたファイルを使用して、コードプロジェクトに関するコンテキストを提供します。インポートされたファイルコンテキストは、`.js`、`.jsx`、`.ts`、`.tsx`、および`.vue`ファイルタイプを含む、JavaScriptおよびTypeScriptファイルでサポートされています。

## GitLab Duoからコンテキストを除外する {#exclude-context-from-gitlab-duo}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo ProまたはEnterprise

{{< /details >}} {{< history >}}

- GitLab 18.2で`use_duo_context_exclusion`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17124)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータに移行しました。
- GitLab 18.5でデフォルトで有効になりました。

{{< /history >}}

GitLab Duoのコンテキストとして除外するプロジェクトコンテンツを制御できます。パスワードや設定ファイルなどの機密情報を保護するには、この機能を使用します。

コンテンツを除外すると、[GitLab Duo Chat (Classic)](../gitlab_duo_chat/_index.md)を除くすべてのGitLab Duo機能は、この情報をコンテキストとして除外します。

### GitLab Duoコンテキスト除外を管理する {#manage-gitlab-duo-context-exclusions}

GitLab Duoが除外するコンテンツを指定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**の**GitLab Duoコンテキスト除外**セクションで、**除外の管理**を選択します。
1. GitLab Duoコンテキストから除外するプロジェクトファイルとディレクトリを指定し、**除外を保存**を選択します。
1. オプション。既存の除外を削除するには、該当する除外の**削除**（{{< icon name="remove" >}}）を選択します。
1. **変更を保存**を選択します。
