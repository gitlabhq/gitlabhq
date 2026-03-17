---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: あるブランチから別のブランチに単一のコミットを追加する場合は、Gitコミットをcherry-pickします。
title: 変更をcherry-pickする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitでは、*cherry-pick*とは、あるブランチから単一のコミットを取得し、別のブランチに最新のコミットとして追加することです。ソースブランチの残りのコミットは、ターゲットには追加されません。ブランチ全体の内容ではなく、単一のコミットの内容が必要な場合に、コミットをcherry-pickします。たとえば、次のような場合です。

- デフォルトブランチから以前のリリースブランチにバグ修正をバックポートする。
- フォークからアップストリームリポジトリに変更をコピーする。

GitLab UIを使用して、プロジェクトまたはプロジェクトフォークから、単一のコミットまたはマージリクエストのすべての内容をcherry-pickします。

この例では、Gitリポジトリに`develop`と`main`の2つのブランチがあります。コミット`B`は、`main`ブランチのコミット`E`の後に、`develop`ブランチからcherry-pickされます。cherry-pickの後、コミット`G`が追加されます。

<!-- Diagram reused in doc/topics/git/cherry_pick.md -->

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
    accTitle: Example of cherry-picking a commit
    accDescr: Commit B is copied from the develop branch to the main branch while leaving the original branch unchanged.

 commit id: "A"
 branch develop
 commit id:"B"
 checkout main
 commit id:"C"
 checkout develop
 commit id:"D"
 checkout main
 commit id:"E"
 cherry-pick id:"B"
 commit id:"G"
 checkout develop
 commit id:"H"
```

## cherry-pickされたコミットのシステムノートを表示する {#view-system-notes-for-cherry-picked-commits}

GitLab UIまたはAPIで[マージコミット](methods/_index.md#merge-commit)をチェリーピックすると、GitLabは関連するマージリクエストのスレッドに[システムノート](../system_notes.md)を追加します。

システムノートは、マージコミットをチェリーピックする場合にのみ作成されます。早送りマージを使用する場合、システムノートは作成されません。これは、個々のコミットのチェリーピックと、マージリクエストからのすべての変更のチェリーピックの両方に適用されます。

GitLab UIまたはAPI外でチェリーピックされたコミットもシステムノートを作成しません。

システムノートが作成されると、フォーマットは{{< icon name="cherry-pick-commit" >}} `[USER]` **picked the changes into the branch** `[BRANCHNAME]` withコミット`[SHA]` `[DATE]`:

![マージリクエストのタイムラインでのcherry-pick追跡](img/cherry_pick_mr_timeline_v15_4.png)

システムノートは、新しいコミットと既存のマージリクエストを相互リンクします。各デプロイメントの[関連付けられたマージリクエストのリスト](../../../api/deployments.md#list-all-merge-requests-associated-with-a-deployment)には、cherry-pickされたマージコミットが含まれています。

## マージリクエストからすべての変更をcherry-pickする {#cherry-pick-all-changes-from-a-merge-request}

マージリクエストがマージされた後、マージリクエストによって導入されたすべての変更をcherry-pickできます。マージリクエストは、アップストリームプロジェクトまたはダウンストリームフォークに存在します。

前提条件: 

- マージリクエストの編集、リポジトリへのコードの追加を許可するプロジェクトのロールが必要です。
- お使いのプロジェクトでは[マージコミット](methods/_index.md#merge-commit)方式を使用する必要があります。これはプロジェクトの**設定** > **マージリクエスト**で設定します。

  [GitLab 16.9以降](https://gitlab.com/gitlab-org/gitlab/-/issues/142152)では、早送りマージされたコミットは、スカッシュされている場合、またはマージリクエストに単一のコミットが含まれている場合にのみ、GitLab UIからcherry-pickできます。いつでも[個々のコミットをcherry-pick](#cherry-pick-a-single-commit)できます。

  > [!note] [システムノート](#view-system-notes-for-cherry-picked-commits)は、早送りマージ方法を使用する場合、作成されません。

これを行うには、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで**コード** > **マージリクエスト**を選択し、目的のマージリクエストを見つけてください。
1. マージリクエストレポートセクションまでスクロールし、**マージしたユーザー**レポートを見つけます。
1. レポートの右上隅で、**Cherry-pick**を選択します:

   ![マージリクエストをCherry-pick](img/cherry_pick_v15_4.png)
1. ダイアログで、cherry-pick先のプロジェクトとブランチを選択します。
1. オプション。**これらの変更で新しいマージリクエストを開始**を選択します。
1. **Cherry-pick**を選択します。

## 単一のコミットをcherry-pickする {#cherry-pick-a-single-commit}

GitLabプロジェクトの複数の場所から単一のコミットをcherry-pickできます。

マージコミットをチェリーピックすると、GitLabは関連するマージリクエストに[システムノート](#view-system-notes-for-cherry-picked-commits)を作成し、その操作を追跡します。

### プロジェクトのコミットリストから {#from-a-projects-commit-list}

プロジェクトのすべてのコミットのリストからコミットをcherry-pickするには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで**コード** > **コミット**を選択します。
1. cherry-pickするコミットの[タイトル](https://git-scm.com/docs/git-commit#_discussion)を選択します。
1. 右上隅で**オプション** > **cherry-pick**を選択します。
1. cherry-pickダイアログで、cherry-pick先のプロジェクトとブランチを選択します。
1. オプション。**これらの変更で新しいマージリクエストを開始**を選択します。
1. **Cherry-pick**を選択します。

### リポジトリのファイルビューから {#from-the-file-view-of-a-repository}

プロジェクトのGitリポジトリでファイルを表示すると、個々のファイルに影響を与える以前のコミットのリストからcherry-pickできます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで**コード** > **リポジトリ**を選択します。
1. コミットによって変更されたファイルに移動します。最後のコミットブロックで、**履歴**を選択します。
1. cherry-pickするコミットの[タイトル](https://git-scm.com/docs/git-commit#_discussion)を選択します。
1. 右上隅で**オプション** > **cherry-pick**を選択します。
1. cherry-pickダイアログで、cherry-pick先のプロジェクトとブランチを選択します。
1. オプション。**これらの変更で新しいマージリクエストを開始**を選択します。
1. **Cherry-pick**を選択します。

## 別の親コミットを選択する {#select-a-different-parent-commit}

GitLab UIでマージコミットをcherry-pickすると、メインラインは常に最初の親になります。コマンドラインを使用して、別のメインラインでcherry-pickします。詳細については、[ブランチ全体の内容をコピーする](../../../topics/git/cherry_pick.md#copy-the-contents-of-an-entire-branch)を参照してください。

## 関連トピック {#related-topics}

- [コミットAPI](../../../api/commits.md#cherry-pick-a-commit)
- [Gitでの変更のチェリーピック](../../../topics/git/cherry_pick.md)
