---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コード提案のコンテキスト認識
---

GitLab Duoが意思決定を行い、提案を行うのに役立つさまざまな情報が利用可能です。

情報は、以下の状況で利用可能です:

- 常時。
- お客様の場所に基づく（移動するとコンテキストが変化します）。

次のコンテキストは、コード提案で利用できます。

## 常に利用可能 {#always-available}

- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- カーソルの前後のコンテンツを含め、表示または編集しているファイルの名前、拡張子、およびコンテンツ。

## 場所に基づく {#based-on-location}

- IDEのタブで開いているファイル。オプションですが、デフォルトでオンになっています。
  - 前提条件: 
    - 最適なコンテキストのウェイト付けを行うには、GitLabバージョン17.2以降が必要です。
    - サポートされているIDE拡張機能。バージョン要件については、[開いているファイルをコンテキストとして使用する](#using-open-files-as-context)を参照してください。
  - これらのファイルは、プロジェクトの標準とプラクティスに関する情報をGitLab Duoに提供します。
  - コンテキストに使用したくない場合は、ファイルを閉じてください。
  - 最近開いたファイル、または変更したファイルが、コンテキストとして優先されます。
  - コード補完は、[コード提案](../../../duo_agent_platform/code_suggestions/supported_extensions.md#supported-languages-by-ide)および[コード提案 (クラシック)](supported_extensions.md#supported-languages-by-ide)でサポートされているすべての言語を認識します。
  - コード生成は、次の言語のファイルのみを認識します: Go、Java、JavaScript、Kotlin、Python、Ruby、Rust、TypeScript（`.ts`および`.tsx`ファイル）、Vue、YAML。
- 表示または編集しているファイルにインポートされたファイル。オプションですが、デフォルトでオフになっています。
  - これらのファイルは、ファイルのクラスとメソッドに関する情報をGitLab Duoに提供します。
  - `.js`、`.jsx`、`.ts`、`.tsx`、および`.vue`のファイルタイプを含む、JavaScriptおよびTypeScriptファイルでサポートされています。
- エディタで選択されたコード。
- [コード提案](../../../duo_agent_platform/code_suggestions/repository_xray.md)または[コード提案 (クラシック)](repository_xray.md)からのリポジトリX-Rayファイル。

> [!note]
> 既知の形式に一致するシークレットおよび機密性の高い値は、コードを生成するために使用される前に削除済みになります。これは、`/include`を使用して追加されたファイルに適用されます。

IDEでコード提案がコンテキストを使用する方法の詳細については、[GitLab言語サーバーのドキュメント](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp#use-open-tabs-as-context)を参照してください。

### コード提案がコンテキストに使用するものを変更する {#change-what-code-suggestions-uses-for-context}

コード提案が他のファイルをコンテキストとして使用するかどうかを変更できます。

#### 開いているファイルをコンテキストとして使用する {#using-open-files-as-context}

{{< history >}}

- GitLab 17.1で`advanced_context_resolver`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464767)されました。デフォルトでは無効になっています。
- GitLab 17.1で`code_suggestions_context`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。デフォルトでは無効になっています。
- VS Code用GitLab Workflow 4.20.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/276)されました。
- JetBrains用GitLab Duo 2.7.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/462)されました。
- 2024年7月16日にGitLab Neovimプラグインに[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/merge_requests/152)されました。
- GitLab 17.2のGitLab.comおよびGitLab 17.4のGitLab Self-Managedで、`advanced_context_resolver`と`code_suggestions_context`の機能フラグが有効になりました。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)になりました。機能フラグ`code_suggestions_context`は削除されました。

{{< /history >}}

デフォルトでは、コード提案は、提案を行う際にIDEで開いているファイルをコンテキストとして使用します。ただし、この設定をオフにすることができます。

前提条件: 

- GitLab 17.2以降。コード提案をサポートする以前のバージョンのGitLabでは、開いているタブのコンテンツをプロジェクト内の他のファイルよりも重視することはできません。
- サポートされているプラグイン: 
  - VS Code用GitLab Workflow拡張機能6.2.2以降。
  - JetBrains IDE用GitLabプラグイン3.6.5以降。
  - Neovim用GitLabプラグイン1.1.0以降。
  - Visual Studio用GitLab拡張機能0.51.0以降。

コンテキストとして使用されている開いているファイルを変更するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. 上部のバーで、**Code** > **Settings** > **Extensions**に移動します。
1. リストでGitLabワークフローを検索し、歯車アイコンを選択します。
1. **Settings**を選択します。
1. **User**設定で、`open tabs`を検索します。
1. **GitLab** > **Duo Code Suggestions: Open Tabs Context**にある、**Use the contents of open tabs as context**を選択またはクリアします。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. IDEの上部のメニューバーに移動し、**Settings**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。
1. **Additional languages**で、**Send open tabs as context**を選択またはクリアします。
1. **Apply**または**Save**を選択します。

{{< /tab >}}

{{< /tabs >}}

#### インポートされたファイルをコンテキストとして使用する {#using-imported-files-as-context}

{{< history >}}

- GitLab 17.9で`code_suggestions_include_context_imports`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514124)されました。デフォルトでは無効になっています。
- GitLab 17.11の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/514124)になりました。
- 機能フラグ`code_suggestions_include_context_imports`は、GitLab 18.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/536129)されました。

{{< /history >}}

IDEでインポートしたファイルを使用して、コードプロジェクトに関するコンテキストを提供します。インポートされたファイルコンテキストは、`.js`、`.jsx`、`.ts`、`.tsx`、および`.vue`ファイルタイプを含む、JavaScriptおよびTypeScriptファイルでサポートされています。
