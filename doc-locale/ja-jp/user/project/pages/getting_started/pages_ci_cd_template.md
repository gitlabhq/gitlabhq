---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab PagesウェブサイトをCI/CDテンプレートから作成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、最も人気のある静的サイトジェネレーター（SSGs）向けに`.gitlab-ci.yml`テンプレートを提供します。これらのテンプレートのいずれかから独自の`.gitlab-ci.yml`ファイルを作成し、CI/CDパイプラインを実行してPagesウェブサイトを生成できます。

既存のプロジェクトにPagesサイトを追加したい場合は、`.gitlab-ci.yml`テンプレートを使用します。

あなたのGitLabリポジトリには、静的サイトジェネレーターに固有のファイル、またはプレーンなHTMLが含まれている必要があります。これらのステップを完了すると、Pagesサイトを適切に生成するために追加の設定を行う必要がある場合があります。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **追加** ({{< icon name="plus" >}}) ドロップダウンリストから、**新しいファイル**を選択します。
1. **ファイル名**テキストボックスに、`.gitlab-ci.yml`を入力します。テキストボックスの右側にドロップダウンリストが表示されます。
1. **テンプレートを適用**ドロップダウンリストの**Pages**セクションで、静的サイトジェネレーターの名前を選択します。プレーンなHTMLの場合は、**HTML**を選択します。
1. **コミットメッセージ**ボックスに、コミットメッセージを入力します。
1. **変更をコミットする**を選択します。

すべてが正しく設定されている場合、サイトのデプロイには約30分かかることがあります。

パイプラインを表示するには、**ビルド** > **パイプライン**に移動します。

パイプラインが完了したら、**デプロイ** > **Pages**に移動してPagesウェブサイトへのリンクを見つけます。

あなたのリポジトリにプッシュされるすべての変更に対して、GitLab CI/CDは新しいパイプラインを実行し、変更をPagesサイトに即座に公開します。

サイト用に作成されたHTMLおよびその他の資産を表示するには、[ジョブアーティファクトをダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)します。
