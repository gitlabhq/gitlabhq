---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 設計管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

設計管理を使用すると、デザインアセット（ワイヤーフレームやモックアップなど）をGitLabイシューにアップロードして、一箇所にまとめて保存できます。製品デザイナー、製品マネージャー、エンジニアは、信頼できる唯一の情報源を使用して設計に関する共同作業ができます。

設計のモックアップをチームで共有したり、視覚的なリグレッションを表示して対応したりできます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>ビデオの概要については、[設計管理](https://www.youtube.com/watch?v=CCMtCqdK_aM)を参照してください。
<!-- Video published on 2019-07-11 -->

## 前提要件 {#prerequisites}

{{< history >}}

- **Relative path**フィールドがGitLab 16.3の**Gitaly relative path**から[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416)されました。

{{< /history >}}

- [Git Large File Storage (LFS)](../../../topics/git/lfs/_index.md)を有効にする必要があります:
  - GitLab.comでは、LFSはすでに有効になっています。
  - GitLabセルフマネージドインスタンスでは、GitLab管理者が[LFSをグローバルに有効にする](../../../administration/lfs/_index.md)必要があります。
  - GitLab.comとGitLabセルフマネージドインスタンスの両方で、LFSを[プロジェクト自体に対して有効にする](../settings/_index.md#configure-project-features-and-permissions)必要があります。グローバルに有効にした場合、LFSはすべてのプロジェクトでデフォルトで有効になります。プロジェクトで無効にした場合は、再度有効にする必要があります。

  設計はLFSオブジェクトとして保存されます。画像のサムネイルは他のアップロードとして保存され、プロジェクトではなく特定の設計モデルに関連付けられています。

  GitLab管理者は、**管理者エリア** > **プロジェクト**に移動し、問題のプロジェクトを選択することで、ハッシュストレージプロジェクトの相対パスを確認できます。**Relative path**フィールドには、値に`@hashed`が含まれています。

要件が満たされていない場合は、**デザイン**セクションで通知されます。

## サポートされているファイルタイプ {#supported-file-types}

次の種類のファイルをデザインとしてアップロードできます:

- BMP
- GIF
- ICO
- JPEG
- JPG
- PNG
- TIFF
- WEBP

PDFファイルのサポートは、[イシュー32811](https://gitlab.com/gitlab-org/gitlab/-/issues/32811)で追跡されます。

## デザインを表示 {#view-a-design}

**デザイン**セクションはイシューの説明にあります。

前提要件: 

- プロジェクトのゲストロール以上が必要です。

デザインを表示するには:

1. イシューに移動します。
1. **デザイン**セクションで、表示するデザイン画像を選択します。

選択したデザインが開きます。次に、[拡大](#zoom-in-on-a-design)したり、[コメントを作成](#add-a-comment-to-a-design)したりできます。

![アップロードされたデザインモックアップを表示するGitLabイシューの「デザイン」セクション。](img/design_management_v14_10.png)

デザインを表示しているときに、他のデザインに移動できます。これを行うには、次のいずれかを実行します:

- 右上隅で、**前のデザインへ**（{{< icon name="chevron-lg-left" >}}）または**次のデザインへ**（{{< icon name="chevron-lg-right" >}}）を選択します。
- キーボードの<kbd>左</kbd>または<kbd>右</kbd>を押します。

イシュービューに戻るには、次のいずれかの操作を行います:

- 左上隅で、閉じるアイコン（{{< icon name="close" >}}）を選択します。
- キーボードの<kbd>Esc</kbd>を押します。

デザインを追加すると、緑色のアイコン（{{< icon name="plus-square" >}}）が画像のサムネイルに表示されます。現在のバージョンでデザインが[変更](#add-a-new-version-of-a-design)された場合、青色のアイコン（{{< icon name="file-modified-solid" >}}）が表示されます。

### デザインを拡大表示 {#zoom-in-on-a-design}

画像を拡大または縮小して、デザインをより詳細に調査できます:

- ズームの量を制御するには、画像の最下部にあるプラス（`+`）とマイナス（`-`）を選択します。
- ズームレベルをリセットするには、やり直しアイコン（{{< icon name="redo" >}}）を選択します。

拡大表示中に画像を移動するには、画像をドラッグします。

## イシューにデザインを追加 {#add-a-design-to-an-issue}

{{< history >}}

- 説明を編集する機能は、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388449)されました。
- イシューにデザインを追加するための最小ロールが、GitLab 16.11でデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147053)されました。
- GitLab 17.7で、イシューにデザインを追加するための最小ロールがレポーターからプランナーに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。
- アップロードするファイルの名前は255文字以下にする必要があります。

イシューにデザインを追加するには:

1. イシューに移動します。
1. 次のいずれかの操作を行います:
   - **デザインをアップロード**を選択し、ファイルブラウザから画像を選択します。一度に最大10個のファイルを選択できます。
   <!-- vale gitlab_base.SubstitutionWarning = NO -->
   - **click to upload**（クリックしてアップロード）を選択し、ファイルブラウザから画像を選択します。一度に最大10個のファイルを選択できます。
   <!-- vale gitlab_base.SubstitutionWarning = YES -->

   - ファイルブラウザからファイルをドラッグし、**デザイン**セクションのドロップゾーンにドロップします。

     ![デザインをドラッグアンドドロップしてイシューページにアップロードすると、新しいデザインがアップロードされます。](img/design_drag_and_drop_uploads_v13_2.png)

   - スクリーンショットを撮るか、ローカル画像ファイルをクリップボードにコピーし、カーソルをドロップゾーンの上に置き、<kbd>Control</kbd>または<kbd>Command</kbd>+<kbd>V</kbd>を押します。

     このように画像を貼り付ける場合は、次の点に注意してください:

     - 一度に貼り付けることができる画像は1つだけです。複数のコピーしたファイルを貼り付けると、最初のファイルのみがアップロードされます。
     - スクリーンショットを貼り付ける場合、画像は次の生成された名前のPNGファイルとして追加されます：`design_<timestamp>.png`。
     - Internet Explorerではサポートされていません。

## デザインの新しいバージョンを追加 {#add-a-new-version-of-a-design}

{{< history >}}

- デザインの新しいバージョンを追加するための最小ロールが、GitLab 16.11でデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147053)されました。
- デザインの新しいバージョンを追加するための最小ロールが、GitLab 17.7でレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

デザインに関するディスカッションが続くと、デザインの新しいバージョンをアップロードしたくなる場合があります。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

これを行うには、同じファイル名で[デザインを追加](#add-a-design-to-an-issue)します。

すべてのデザインバージョンを参照するには、**デザイン**セクションの上部にあるドロップダウンリストを使用します。**最新バージョンを表示**または**Showing version #N**（バージョン#Nを表示）のいずれかとして表示されます。

### スキップされたデザイン {#skipped-designs}

既存のアップロードされたデザインと同じファイル名で、同じ画像をアップロードすると、スキップされます。これは、デザインの新しいバージョンが作成されないことを意味します。デザインがスキップされると、警告メッセージが表示されます。

## デザインをアーカイブ {#archive-a-design}

{{< history >}}

- デザインをアーカイブするための最小ロールが、GitLab 16.11でデベロッパーからレポーターに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147053)されました。
- デザインをアーカイブするための最小ロールが、GitLab 17.7でレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

個々のデザインをアーカイブすることも、それらをいくつか選択して一度にアーカイブすることもできます。

アーカイブされたデザインが完全に失われることはありません。[以前のバージョン](#add-a-new-version-of-a-design)を参照できます。

デザインをアーカイブすると、そのURLが変更されます。デザインが最新バージョンで利用できない場合は、URL内のバージョンでのみリンクできます。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。
- デザインの最新バージョンのみをアーカイブできます。

単一のデザインをアーカイブするには:

1. デザインを選択して拡大表示します。
1. 右上隅で、**デザインをアーカイブ**（{{< icon name="archive" >}}）を選択します。
1. **デザインをアーカイブ**を選択します。

複数のデザインを一度にアーカイブするには:

1. アーカイブするデザインのチェックボックスをオンにします。
1. **選択したものをアーカイブ**を選択します。

## 設計管理のデータ永続性 {#design-management-data-persistence}

- 設計管理データは、次の場合には削除されません:
  - [プロジェクトが削除された](https://gitlab.com/gitlab-org/gitlab/-/issues/13429)。
  - [イシューが削除された](https://gitlab.com/gitlab-org/gitlab/-/issues/13427)。

### 設計管理データのレプリケート {#replicate-design-management-data}

設計管理データは[レプリケートできます](../../../administration/geo/replication/datatypes.md#replicated-data-types) 。GitLab 16.1以降では、[Geoでもレプリケートできるか検証できます](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)。

## 説明用のMarkdownおよびリッチテキストエディタ {#markdown-and-rich-text-editors-for-descriptions}

{{< history >}}

- GitLab 16.1で`content_editor_on_issues`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388449)されました。デフォルトでは無効になっています。
- GitLab 16.2の[GitLab.comおよびGitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/375172)されました。
- 機能フラグ`content_editor_on_issues`は、GitLab 16.5で削除されました。

{{< /history >}}

デザインの説明では、Markdownおよびリッチテキストエディタを使用できます。GitLab全体のコメントに使用するエディタと同じです。

## デザインの並べ替え {#reorder-designs}

デザインの順序を変更するには、デザインを新しい位置にドラッグします。

## デザインにコメントを追加 {#add-a-comment-to-a-design}

アップロードされたデザインに関する[ディスカッション](../../discussions/_index.md)を開始できます。これを行うには、次の手順に従います:

1. イシューに移動します。
1. デザインを選択します。
<!-- vale gitlab_base.SubstitutionWarning = NO -->
<!-- Disable Vale so it doesn't catch "click" -->
1. 画像を選択します。その場所にピンが作成され、ディスカッションの場所が識別されます。
<!-- vale gitlab_base.SubstitutionWarning = YES -->
1. メッセージを入力します。
1. **コメント**を選択します。

ピンの位置を調整するには、画像をドラッグします。デザインのレイアウトが変更された場合、またはピンを移動して新しいピンをその場所に追加できるようにする場合に、これを使用します。

新しいディスカッションスレッドには異なるピン番号が付けられ、それらを参照するために使用できます。

新しいディスカッションはイシューアクティビティーに出力されるため、関係するすべての人がディスカッションに参加できます。

## デザインからコメントを削除 {#delete-a-comment-from-a-design}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385100)されました。
- デザインからコメントを削除するための最小ロールが、GitLab 17.7でレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。

デザインからコメントを削除するには:

1. 削除するコメントで、**追加のアクション** {{< icon name="ellipsis_v" >}} > **コメントを削除**を選択します。
1. 確認ダイアログで、**コメントを削除**を選択します。

## デザインに関するディスカッションスレッドを解決 {#resolve-a-discussion-thread-on-a-design}

デザインの一部についてディスカッションが完了したら、ディスカッションスレッドを解決できます。

スレッドを解決済みにするか、開くには、次のいずれかの操作を行います:

- ディスカッションの最初のコメントの右上隅で、**スレッドを解決にする**または**スレッドを再オープン**（{{< icon name="check-circle" >}}）を選択します。
- 新しいコメントをスレッドに追加し、**スレッドを解決にする**チェックボックスをオンまたはオフにします。

ディスカッションスレッドを解決すると、スレッド内のメモに関連する保留中の[To-Doアイテム](../../todos.md)も完了としてマークされます。アクションをトリガーするユーザーのTo-Doアイテムのみが影響を受けます。

ディスカッションの新しいスペースを空けるために、解決されたコメントピンがデザインから消えます。解決済みのディスカッションを再確認するには、表示されているスレッドの下にある**解決済みのコメント**を展開するします。

## デザインにTo-Doアイテムを追加 {#add-a-to-do-item-for-a-design}

デザインに[To-Doアイテム](../../todos.md)を追加するには、デザインサイドバーで**To-Doアイテムを追加**を選択します。

## Markdownでデザインを参照 {#refer-to-a-design-in-markdown}

[Markdown](../../markdown.md)テキストボックスでデザインを参照できます。コメントまたは説明にデザインのrawURLを貼り付けます。次に、短い参照として表示されます。

たとえば、デザインを次のように参照する場合:

```markdown
See https://gitlab.com/gitlab-org/gitlab/-/issues/13195/designs/Group_view.png.
```

GitLabはrawURLを省略形の[参照](../../markdown.md#gitlab-specific-references)として自動的にレンダリングします:

> [\#13195[Group_view.png]](https://gitlab.com/gitlab-org/gitlab/-/issues/13195/designs/Group_view.png)を参照してください。

画像へのリンクは、コメントまたは説明に[画像を埋め込む](../../markdown.md#images)のとは異なります。この方法でデザインを埋め込むことはできません。

## デザインアクティビティー記録 {#design-activity-records}

デザインに関するユーザーアクティビティーイベント（作成、削除、アップデート）はGitLabによって追跡され、[ユーザープロファイル](../../profile/_index.md#access-your-user-profile) 、[グループ](../../group/manage.md#view-group-activity) 、および[プロジェクト](../working_with_projects.md#view-project-activity)アクティビティーページに表示されます。

## GitLab-Figmaプラグイン {#gitlab-figma-plugin}

GitLab-Figmaプラグインを使用すると、FigmaからGitLabのイシューにデザインを直接アップロードできます。

Figmaでプラグインを使用するには、[Figma Directory](https://www.figma.com/community/plugin/860845891704482356/gitlab)からインストールし、パーソナルアクセストークンを介してGitLabに接続します。

詳細については、[プラグインのドキュメント](https://gitlab.com/gitlab-org/gitlab-figma-plugin/-/wikis/home)を参照してください。

## トラブルシューティング {#troubleshooting}

設計管理を使用する場合、次の問題が発生する可能性があります。

### デザインが見つかりません {#could-not-find-design}

`Could not find design`というエラーが表示されることがあります。

この問題は、デザインが[アーカイブされた](#archive-a-design)場合に発生するため、最新バージョンでは利用できず、フォローしたリンクではバージョンが指定されていません。

デザインをアーカイブすると、そのURLが変更されます。デザインが最新バージョンで利用できない場合は、URL内のバージョンでのみリンクできます。

たとえば`https://gitlab.example.com/mygroup/myproject/-/issues/123456/designs/menu.png?version=503554`などです。`menu.png`に`https://gitlab.example.com/mygroup/myproject/-/issues/123456/designs/menu.png`でアクセスできなくなりました。

回避策は、**デザイン**セクションの上部にあるドロップダウンリストから以前のバージョンのいずれかを選択することです。**最新バージョンを表示**または**Showing version #N**（バージョン#Nを表示）のいずれかとして表示されます。

イシュー[392540](https://gitlab.com/gitlab-org/gitlab/-/issues/392540)により、この動作の改善を追跡しています。
