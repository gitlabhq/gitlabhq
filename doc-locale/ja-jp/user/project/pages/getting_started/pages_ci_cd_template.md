---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDテンプレートからGitLab Pagesウェブサイトを作成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、最も一般的な静的サイトジェネレーター（SSG）用の`.gitlab-ci.yml`テンプレートを提供します。これらのテンプレートのいずれかから独自の`.gitlab-ci.yml`ファイルを作成し、CI/CDパイプラインを実行してPagesのウェブサイトを生成できます。

Pagesサイトを追加する既存のプロジェクトがある場合は、`.gitlab-ci.yml`テンプレートを使用します。

GitLabリポジトリには、SSGまたはプレーンHTMLに固有のファイルが含まれている必要があります。これらの手順を完了した後、Pagesサイトが適切に生成されるように、追加の設定が必要になる場合があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**追加**（{{< icon name="plus" >}}）ドロップダウンリストから、**新しいファイル**を選択します。
1. **ファイル名**テキストボックスに、`.gitlab-ci.yml`と入力します。テキストボックスの右側にドロップダウンリストが表示されます。
1. **テンプレートを適用**ドロップダウンリストの**Pages**セクションで、SSGの名前を選択します。プレーンHTMLの場合は、**HTML**を選択します。
1. **コミットメッセージ**ボックスに、コミットメッセージを入力します。
1. **変更をコミットする**を選択します。

すべてが正しく設定されている場合、サイトのデプロイには約30分かかることがあります。

パイプラインを表示するには、**ビルド** > **パイプライン**に移動します。

パイプラインが完了したら、**デプロイ** > **Pages**に移動して、GitLab Pagesウェブサイトへのリンクを見つけます。

リポジトリにプッシュされたすべての変更について、GitLab CI/CDは、Pagesサイトへの変更をすぐに公開する新しいパイプラインを実行します。

サイト用に作成されたHTMLおよびその他の資産を表示するには、[ジョブアーティファクトをダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)します。
