---
stage: none - [facilitated functionality](https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality)
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロファイルの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

設定を更新することで、GitLabのルックアンドフィールを変更できます。

## モードを変更する {#change-the-mode}

{{< history >}}

- GitLab 13.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252)されました。
- GitLab 17.11で実験的機能から[ベータ](https://gitlab.com/gitlab-org/gitlab/-/issues/524846)に変更されました。
- GitLab 18.1で**外観**から**モード**に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/470413)されました。

{{< /history >}}

インターフェースのカラーモードをライトまたはダークに変更したり、デバイスの設定に基づいて自動的に更新したりできます。

外観を変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **モード**セクションで、オプションを選択します。
1. **変更を保存**を選択します。

<!-- When new navigation is released and feature flag `paneled_view` is removed, change **Navigation** to **Theme** -->

## ナビゲーションテーマを変更する {#change-the-navigation-theme}

{{< history >}}

- GitLab 18.1で**Color theme**（カラーテーマ）から**Navigation theme**（ナビゲーションテーマ）に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/470413)されました。
- テーマ: GitLab 18.4で、ライトインディゴ、ライトブルー、ライトグリーン、ライトレッドが[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200475)。

{{< /history >}}

GitLab UIのナビゲーションテーマを変更できます。これらの色は左側のサイドバーに表示されます。個別のナビゲーションテーマを使用すると、さまざまなGitLabインスタンスを区別しやすくなります。

ナビゲーションテーマを変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **ナビゲーション**セクションで、テーマを選択します。

## 構文ハイライトのテーマを変更する {#change-the-syntax-highlighting-theme}

{{< history >}}

- GitLab 15.1で、認証済みユーザーおよび未認証ユーザーに対する構文ハイライトのデフォルトテーマの変更が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/25129)されました。

{{< /history >}}

構文ハイライトは、コードエディタやIDEの機能です。構文ハイライターは、文字列やコメントなど、コードの各タイプに色を割り当てます。

構文ハイライトのテーマを変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **構文のハイライト表示**セクションで、テーマを選択します。
1. **変更を保存**を選択します。

更新された構文ハイライトのテーマを表示するには、プロジェクトのページを更新します。

構文ハイライトのテーマは、[アプリケーション設定APIを使用](../../api/settings.md#available-settings)してカスタマイズすることもできます。`default_syntax_highlighting_theme`と`default_dark_syntax_highlighting_theme`を使用すると、構文ハイライトの色をよりきめ細かく変更できます。

これらの手順でうまくいかない場合は、ご使用のプログラミング言語が構文ハイライターでサポートされていない可能性があります。詳細については、[Rouge Rubyライブラリ](https://github.com/rouge-ruby/rouge)のコードファイルとスニペットのガイダンスを参照してください。Web IDEのガイダンスについては、[Monaco Editor](https://microsoft.github.io/monaco-editor/)と[Monarch](https://microsoft.github.io/monaco-editor/monarch.html)を参照してください。

## 差分の表示色を変更する {#change-the-diff-colors}

差分では、2つの異なる背景色を使用して、コードのバージョン間の変更を示します。デフォルトでは、元のファイルは赤色、変更箇所は緑色で表示されます。

差分の表示色を変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **差分**セクションに移動します。
1. 色を選択するか、カラーコードを入力します。
1. **変更を保存**を選択します。

デフォルトの色に戻すには、**消去された行の色**と**追加された行の色**のテキストボックスをクリアし、**変更を保存**を選択します。

## 動作 {#behavior}

**動作**セクションを使用して、システムレイアウトとデフォルトビューの動作をカスタマイズできます。レイアウトの幅を変更したり、ホームページ、グループ、プロジェクトの概要ページのデフォルトコンテンツを選択したりできます。また、空白のレンダリング、ファイルの表示、テキストの自動化など、外観や機能をカスタマイズするオプションもあります。

### UIのレイアウトの幅を変更する {#change-the-layout-width-on-the-ui}

GitLab UIのコンテンツをページ全体に拡大表示できます。デフォルトでは、ページコンテンツの幅は1280ピクセルに設定されています。

UIのレイアウトの幅を変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **レイアウトの幅**で、**修正しました**または**可変**を選択します。
1. **変更を保存**を選択します。

### デフォルトのテキストエディタを設定する {#set-the-default-text-editor}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423104)されました。
- 新規ユーザーの[デフォルトテキストエディタの設定](https://gitlab.com/gitlab-org/gitlab/-/issues/536611)が18.2でリッチテキストエディタになりました。

{{< /history >}}

デフォルトでは、すべての新規ユーザーはコンテンツを編集する際に**リッチテキストエディタ**を使用します。GitLabでコンテンツを編集するためのデフォルトのエディタを設定できます。

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **デフォルトテキストエディタ**で、**デフォルトテキストエディターを有効にする**チェックボックスが選択されていることを確認してください。
1. デフォルトとして、**リッチテキストエディタ**または**プレーンテキストエディタ**を選択します。
1. **変更を保存**を選択します。

### ホームページを選択する {#choose-your-homepage}

{{< history >}}

- GitLab 17.9で`your_work_projects_vue`[フラグ](../../administration/feature_flags/_index.md)とともに[ホームページのオプションが変更](https://gitlab.com/groups/gitlab-org/-/epics/13066)されました。デフォルトでは無効になっています。
- GitLab 17.10で、[ホームページのオプションの変更が一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/465889)になりました。機能フラグ`your_work_projects_vue`は削除されました。
- [パーソナルホームページ](https://gitlab.com/gitlab-org/gitlab/-/issues/546151)がGitLab 18.1で[フラグ](../../administration/feature_flags/_index.md)`personal_homepage`付きで導入されました。デフォルトでは無効になっています。
- GitLab 18.4で、一部のユーザーに対して[GitLab.comでパーソナルホームページが有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/554048)。
- [Personal homepage enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/17932) GitLab 18.5でGitLab 18.5でGitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になりました。

{{< /history >}}

GitLabロゴ（{{< icon name="tanuki" >}}）を選択したときに表示されるページを制御できます。ホームページを、Personal homepage（デフォルト）、あなたがコントリビュートしたプロジェクト、あなたのグループ、あなたのアクティビティー、またはその他のコンテンツに設定できます。

表示するホームページを選択するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **ホームページ**ドロップダウンリストから、ホームページにするページを選択します。
1. **変更を保存**を選択します。

### グループの概要ページのデフォルトコンテンツをカスタマイズする {#customize-default-content-on-your-group-overview-page}

グループの概要ページのメインコンテンツを変更できます。グループの概要ページは、左側のサイドバーで**グループ**を選択したときに表示されるページです。グループの概要ページのデフォルトコンテンツを次のようにカスタマイズできます:

- 詳細ダッシュボード（デフォルト）。グループのアクティビティーとプロジェクトの概要が含まれます。
- セキュリティダッシュボード。グループのセキュリティポリシーやその他のセキュリティトピックが含まれます。

詳細については、[グループ](../group/_index.md)を参照してください。

グループの概要ページのデフォルトコンテンツを変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **グループ概要の内容**ドロップダウンリストから、オプションを選択します。
1. **変更を保存**を選択します。

### プロジェクトの概要ページのデフォルトコンテンツをカスタマイズする {#customize-default-content-on-your-project-overview-page}

プロジェクトの概要ページは、左側のサイドバーで**Project overview**（プロジェクトの概要）を選択したときに表示されるページです。メインプロジェクトの概要ページをアクティビティーページ、Readmeファイル、またはその他のコンテンツに設定できます。

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **プロジェクト概要の内容**ドロップダウンリストから、オプションを選択します。
1. **変更を保存**を選択します。

### ショートカットボタンを非表示にする {#hide-shortcut-buttons}

ショートカットボタンは、プロジェクトの概要ページのファイルリストの前に表示されます。これらのボタンは、Readmeファイルやライセンス契約など、プロジェクトに関連するコンテンツへのリンクを提供します。

プロジェクトの概要ページでショートカットボタンを非表示にするには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **プロジェクトの概要でファイルの上にショートカットボタンを表示する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### Web IDEでホワイトスペースをレンダリングする {#show-whitespace-characters-in-the-web-ide}

ホワイトスペースとは、スペースやインデントなど、テキスト内の空白文字のことです。コード内のコンテンツを構造化するために、ホワイトスペースが使用される場合があります。プログラミング言語がホワイトスペースの影響を受ける場合、Web IDEはホワイトスペースに対する変更を検出します。

Web IDEでホワイトスペースをレンダリングするには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **Web IDEでホワイトスペースをレンダリング**チェックボックスをオンにします。
1. **変更を保存**を選択します。

差分でホワイトスペースへの変更を表示できます。

Web IDEで差分を表示するには、次の手順に従います:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. **変更**タブで、ファイルを選択します。

### 差分でホワイトスペースの変更を表示する {#show-whitespace-changes-in-diffs}

差分でホワイトスペースに対する変更を表示できます。ホワイトスペースの詳細については、前のタスクを参照してください。

差分でホワイトスペースに対する変更を表示するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **空白を含めたちがいを表示する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

差分の詳細については、[差分の表示色を変更する](#change-the-diff-colors)を参照してください。

### マージリクエストで1ページに1つのファイルを表示する {#show-one-file-per-page-in-a-merge-request}

**変更**タブでは、マージリクエスト内のすべてのファイルの変更を1つのページで表示できます。あるいは、1ページに1つのファイルを表示することもできます。

**変更**タブに1ページに1つのファイルを表示するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **マージリクエストの変更タブに一度に1つのファイルを表示する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

この場合、**変更**タブ内でファイル間を移動するには、各ファイルの下にある**前ページ**または**次へ**ボタンを選択します。

### 文字の自動囲み {#auto-enclose-characters}

開始囲み文字を入力すると、対応する終了囲み文字がテキストに自動的に追加されます。たとえば、開始括弧を入力すると、終了括弧が自動的に挿入されます。この設定は、説明ボックスとコメントボックスのみで有効であり、次の文字に対して有効です: `**"`、`'`、\`\`\`、`(`、`[`、`{`、`<`、`*`、`_**`

説明ボックスとコメントボックスで文字を自動的に囲むには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **引用符または括弧を入力するときにテキスト選択を囲む**チェックボックスをオンにします。
1. **変更を保存**を選択します。

これで、説明ボックスまたはコメントボックスで、単語を入力し、それをハイライト表示して、開始囲み文字を入力できるようになります。テキストを置き換える代わりに、終了囲み文字が末尾に追加されます。

### 新しいリスト項目を自動作成する {#automate-new-list-items}

説明ボックスとコメントボックスのリストで<kbd>Enter</kbd>キーを押すことで、新しいリスト項目を作成できます。

<kbd>Enter</kbd>キーを押したときに新しいリスト項目を追加するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **新しいリスト項目を自動的に追加する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### インデントを維持 {#maintain-cursor-indentation}

<kbd>Enter</kbd>を押したときにインデントを維持します。新しい行のカーソルは、前の行と同じように自動的にインデントされた状態になります。この設定は、説明およびコメントボックスでのみ有効です。

<kbd>Enter</kbd>キーを押したときに新しいリスト項目を追加するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **Maintain cursor indentation**（カーソルのインデントを維持）チェックボックスを選択します。
1. **変更を保存**を選択します。

### タブの幅を変更する {#change-the-tab-width}

差分、blob、およびスニペットのタブのデフォルトサイズを変更できます。ただし、Web IDE、ファイルエディタ、およびMarkdownエディタは、この機能をサポートしていません。

デフォルトのタブ幅を調整するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールします。
1. **タブ幅**に値を入力します。
1. **変更を保存**を選択します。

## ローカライゼーション {#localization}

言語、カレンダーの開始日、時刻設定など、ローカライゼーション設定を変更します。

### GitLab UIで表示言語を変更する {#change-your-display-language-on-the-gitlab-ui}

GitLabのUIは複数の言語をサポートしています。

GitLab UIの言語を選択するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **ローカライズ**セクションに移動します。
1. **言語**で、使用する言語を選択します。
1. **変更を保存**を選択します。

選択した言語で表示するには、ページを更新する必要がある場合があります。

### コントリビュートカレンダーの開始日をカスタマイズする {#customize-your-contribution-calendar-start-day}

コントリビュートカレンダーを開始する曜日を選択できます。コントリビュートカレンダーには、過去1年間のプロジェクトへのコントリビュートが表示されます。このカレンダーは、各ユーザーのプロファイルで表示できます。ユーザープロファイルにアクセスするには、次の手順に従います:

- 左側のサイドバーで、自分のアバターを選択 > 名前またはユーザー名を選択します。

コントリビュートカレンダーの開始曜日を変更するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **ローカライズ**セクションに移動します。
1. **週始めの曜日**で、開始曜日を選択します。
1. **変更を保存**を選択します。

カレンダーの開始曜日を変更した後、ユーザープロファイルページを更新します。

### 相対時間の代わりに正確な時刻を表示する {#show-exact-times-instead-of-relative-times}

グループ、プロジェクトの概要ページ、およびユーザープロファイルの活動時刻の表示形式をカスタマイズします。時刻の表示形式は次のいずれかを選択できます:

- 相対形式（例: `30 minutes ago`）。
- 絶対形式（例: `September 3, 2022, 3:57 PM`）。

GitLab UIで正確な時刻を表示するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **時間設定**セクションに移動します。
1. **相対時間を使用する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### 時刻形式をカスタマイズする {#customize-time-format}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/15206)されました。

{{< /history >}}

グループ、プロジェクトの概要ページ、およびユーザープロファイルの活動時刻の表示形式をカスタマイズできます。時刻は次の形式で表示できます:

- 12時間形式。例: `2:34 PM`
- 24時間形式。例: `14:34`

システムの設定に従うこともできます。

時刻形式をカスタマイズするには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **時間設定**セクションに移動します。
1. **時間フォーマット**で、**システム**、**12-hour**（12時間）、または**24-hour**（24時間）オプションを選択します。
1. **変更を保存**を選択します。

<!--- start_remove The following content will be removed on remove_date: '2026-02-20' -->

## 非推奨：完全一致コードの検索を無効にする {#disable-exact-code-search-deprecated}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< alert type="warning" >}}

この機能はGitLab 18.3で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/554933)となり、18.6で削除される予定です。

{{< /alert >}}

{{< history >}}

- GitLab 15.9で`index_code_with_zoekt`および`search_code_with_zoekt`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)されました。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)になりました。
- 機能フラグ`index_code_with_zoekt`および`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](../../policy/development_stages_support.md#beta)版であり、予告なく変更される場合があります。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。

{{< /alert >}}

前提要件:

- [GitLab Self-Managed](../../subscriptions/self_managed/_index.md)の場合、[管理者](../../integration/zoekt/_index.md#enable-exact-code-search)が完全一致コードの検索を有効にする必要があります。

ユーザー設定で[完全一致コードの検索](../search/exact_code_search.md)を無効にするには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **完全一致コードの検索**セクションに移動します。
1. **完全一致コード検索を有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

<!--- end_remove -->

## CIジョブのJSON Web TokenにおけるユーザーID {#user-identities-in-ci-job-json-web-tokens}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387537)されました。

{{< /history >}}

CI/CDジョブは、JSON Web Tokenを生成します。これには外部IDのリストを含めることができます。個々のアカウントを取得するために個別のAPIコールを行う代わりに、1つの認証トークンでユーザーIDを確認できます。

デフォルトでは、外部IDは含まれていません。外部IDを含めるようにするには、[トークンのペイロード](../../ci/secrets/id_token_authentication.md#token-payload)を参照してください。

## フォロワーのエンゲージメントを制御する {#control-follower-engagement}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/325558)されました。

{{< /history >}}

他のGitLabユーザーをフォローしたり、フォローされたりする機能をオフにします。デフォルトでは、名前とプロファイル写真を含むユーザープロファイルは、他のユーザーの**フォロー**タブで公開されています。この設定を無効にすると、次のようになります:

- GitLabは、すべてのフォロワーとフォローされている接続を削除します。
- GitLabは、各接続のページからユーザープロファイルを自動的に削除します。

他のユーザーにフォローされたり、フォローしたりする機能を削除するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **ユーザーのフォローを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

**フォロワー**タブと**フォロー**タブにアクセスするには、次の手順に従います:

- 左側のサイドバーで、自分のアバターを選択 > 名前またはユーザー名を選択します。
- **フォロワー**または**フォロー**を選択します。

## GitLabインスタンスをサードパーティサービスと統合する {#integrate-your-gitlab-instance-with-third-party-services}

サードパーティサービスにアクセス権を付与して、GitLabエクスペリエンスを向上させることができます。

### GitLabインスタンスをGitpodと統合する {#integrate-your-gitlab-instance-with-gitpod}

GitLabブラウザから直接コードを起動および管理したい場合は、GitLabインスタンスをGitpodで設定します。Gitpodは、プロジェクトの開発環境を自動的に準備し、構築します。

Gitpodと統合するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **インテグレーション**セクションを見つけます。
1. **Gitpod統合を有効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### GitLabインスタンスをSourcegraphと統合する {#integrate-your-gitlab-instance-with-sourcegraph}

GitLabは、GitLab上のすべての公開プロジェクトに対してSourcegraph統合をサポートしています。

Sourcegraphと統合するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **インテグレーション**セクションを見つけます。
1. **コードビューでコードインテリジェンスを有効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

Sourcegraphとの統合のためにGitLabを設定するには、GitLabインスタンスの管理者である必要があります。

### 拡張機能マーケットプレースと連携する {#integrate-with-the-extension-marketplace}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で`web_ide_oauth`および`web_ide_extensions_marketplace`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352)されました。デフォルトでは無効になっています。
- `web_ide_oauth`は、GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181)になりました。
- `web_ide_extensions_marketplace`は、GitLab 17.4の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/459028)になりました。
- `web_ide_oauth`は、GitLab 17.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464)されました。
- GitLab 17.6で[ワークスペース](../workspace/_index.md)に対してデフォルトで有効になりました。ワークスペースでは、拡張機能マーケットプレースを利用するために機能フラグは必要ありません。
- GitLab 17.10で`vscode_extension_marketplace_settings`[機能フラグ](../../administration/feature_flags/_index.md)を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/508996)しました。デフォルトでは無効になっています。
- `web_ide_extensions_marketplace`はGitLab 17.11の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662)になり、`vscode_extension_marketplace_settings`は[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662)になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192659)になりました。機能フラグ`web_ide_extensions_marketplace`および`vscode_extension_marketplace_settings`は削除されました。

{{< /history >}}

VS Code拡張機能マーケットプレースを使用すると、Web IDEとワークスペースの機能を強化する拡張機能にアクセスできます。

前提要件: 

- GitLab Self-ManagedおよびGitLab Dedicatedの場合、GitLabの管理者は[拡張機能レジストリを有効にする](../../administration/settings/vscode_extension_marketplace.md#enable-the-extension-registry)必要があります。
- エンタープライズユーザーの場合、グループオーナーは、関連付けられたグループに対して[拡張機能マーケットプレースを有効にする](../enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users)必要があります。

拡張機能マーケットプレースと連携するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **インテグレーション**セクションに移動します。
1. **拡張機能マーケットプレイスを有効にする**チェックボックスをオンにします。
1. サードパーティの拡張機能の使用許諾契約で、**わかりました**を選択します。
1. **変更を保存**を選択します。
