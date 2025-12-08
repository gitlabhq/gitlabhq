---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フォークされたサンプルプロジェクトからGitLab Pagesのウェブサイトを作成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、最も一般的な[静的サイトジェネレーター（SSG）のサンプルプロジェクト](https://gitlab.com/pages)を提供しています。サンプルプロジェクトをフォークして、CI/CDパイプラインを実行し、Pagesウェブサイトを生成できます。

GitLab Pagesをテストする場合、またはPagesサイトを生成するように既に構成されている新しいプロジェクトを開始する場合は、サンプルプロジェクトをフォークします。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>これがどのように機能するかを[ビデオチュートリアル](https://www.youtube.com/watch?v=TWqh9MtT4Bg)でご覧ください。

サンプルプロジェクトをフォークしてPagesウェブサイトを作成するには、次の手順に従います:

1. [GitLab Pagesの例](https://gitlab.com/pages)グループに移動して、サンプルプロジェクトを表示します。
1. [フォーク](../../repository/forking_workflow.md#create-a-fork)するプロジェクトの名前を選択します。
1. 右上隅で**フォーク**を選択し、フォーク先のネームスペースを選択します。
1. プロジェクトの左側のサイドバーで、**ビルド** > **パイプライン**、**パイプラインを新規作成**の順に選択します。GitLab CI/CDでサイトをビルドしてデプロイします。

サイトのデプロイには、約30分かかる場合があります。パイプラインが完了したら、**デプロイ** > **Pages**に移動して、Pagesウェブサイトへのリンクを見つけます。

リポジトリにプッシュされたすべての変更に対して、GitLab CI/CDは、Pagesサイトへの変更をすぐに公開する新しいパイプラインを実行します。

## フォーク関係を削除する {#remove-the-fork-relationship}

フォーク元のプロジェクトにコントリビュートする場合は、フォーク関係を維持できます。それ以外の場合:

1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **Advanced settings**（高度な設定）を展開します。
1. **フォークの関係を削除**を選択します。

## URLを変更する {#change-the-url}

ネームスペースに合わせてURLを変更できます。PagesサイトがGitLab.comでホストされている場合は、`<namespace>.gitlab.io`に名前を変更できます。ここで、`<namespace>`はGitLabのネームスペース（プロジェクトをフォークしたときに選択したネームスペース）です。

1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **高度な設定**を展開します。
1. **パスを変更**で、パスを`<namespace>.gitlab.io`に更新します。

   たとえば、プロジェクトのURLが`gitlab.com/gitlab-tests/jekyll`の場合、ネームスペースは`gitlab-tests`です。

   リポジトリパスを`gitlab-tests.gitlab.io`に設定すると、Pages Webサイトの結果のURLは`https://gitlab-tests.gitlab.io`になります。

   ![リポジトリのパスを変更](img/change_path_v12_10.png)

1. 静的サイトジェネレーター設定ファイルを開き、[ベースURL](../getting_started_part_one.md#urls-and-base-urls)を`"project-name"`から`""`に変更します。プロジェクト名の設定は静的サイトジェネレーターによって異なり、設定ファイルにない場合があります。

## 関連トピック {#related-topics}

- [ジョブアーティファクトをダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)
