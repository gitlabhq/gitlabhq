---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: フォークしたサンプルプロジェクトからGitLab Pagesウェブサイトを作成
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、最も人気のある[静的サイトジェネレーター（SSG）](https://gitlab.com/pages)のサンプルプロジェクトを提供しています。サンプルプロジェクトのいずれかをフォークして、CI/CDパイプラインを実行し、Pagesウェブサイトを生成できます。

GitLab Pagesをテストしたい場合、またはPagesサイトを生成するようにすでに構成されている新しいプロジェクトを開始したい場合は、サンプルプロジェクトをフォークしてください。

<i class="fa-youtube-play" aria-hidden="true"></i>この機能の動作に関する[ビデオチュートリアル](https://www.youtube.com/watch?v=TWqh9MtT4Bg)をご覧ください。

サンプルプロジェクトをフォークしてPagesウェブサイトを作成するには:

1. [GitLab Pagesの例](https://gitlab.com/pages)グループに移動してサンプルプロジェクトを表示します。
1. [フォーク](../../repository/forking_workflow.md#create-a-fork)したいプロジェクトの名前を選択します。
1. 右上隅で**フォーク**を選択し、フォーク先のネームスペースを選択します。
1. あなたのプロジェクトで、左サイドバーで**ビルド** > **パイプライン**、そして**新しいパイプライン**を選択します。GitLab CI/CDがサイトをビルドしてデプロイします。

サイトのデプロイには約30分かかる場合があります。パイプラインが完了したら、**デプロイ** > **Pages**に移動してPagesウェブサイトへのリンクを見つけてください。

あなたのリポジトリにプッシュされたすべての変更に対して、GitLab CI/CDは新しいパイプラインを実行し、Pagesサイトに変更を即座に公開します。

## フォークの関係を削除する {#remove-the-fork-relationship}

フォークしたプロジェクトにコントリビュートする場合は、フォークした関係を維持できます。それ以外の場合:

1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. 展開**Advanced settings**。
1. **フォークの関係を削除**を選択します。

## URLを変更する {#change-the-url}

URLをネームスペースに合わせて変更できます。PagesサイトがGitLab.comでホストされている場合、`<namespace>.gitlab.io`に名前を変更できます。ここで、`<namespace>`はあなたのGitLabネームスペースです（プロジェクトをフォークしたときに選択したものです）。

1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **高度な設定**を展開します。
1. **パスを変更**で、パスを`<namespace>.gitlab.io`に更新します。

   たとえば、あなたのプロジェクトのURLが`gitlab.com/gitlab-tests/jekyll`の場合、あなたのネームスペースは`gitlab-tests`です。

   リポジトリのパスを`gitlab-tests.gitlab.io`に設定した場合、PagesウェブサイトのURLは`https://gitlab-tests.gitlab.io`になります。

   ![リポジトリのパスを変更](img/change_path_v12_10.png)

1. あなたのSSG設定ファイルを開き、[base URL](../getting_started_part_one.md#urls-and-base-urls)を`"project-name"`から`""`に変更します。プロジェクト名の設定はSSGによって異なり、設定ファイル内にない場合があります。

## 関連トピック {#related-topics}

- [ジョブのアーティファクトをダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)
