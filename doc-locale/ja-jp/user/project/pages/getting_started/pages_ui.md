---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 静的サイトのGitLab Pagesデプロイを作成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Pagesデプロイを作成して、静的サイトまたはフレームワークをGitLabでホストされるウェブサイトに変換します。段階的なフォームを使用して、GitLabは以下を行います。

- プロジェクト設定に基づいて、カスタムのCI/CD設定を生成します。
- GitLab Pagesデプロイに合わせて設定された`.gitlab-ci.yml`ファイルを作成します。
- レビューのために、マージリクエストによって変更を送信します。
- マージリクエストがコミットされると、ウェブサイトを自動的にデプロイします。

このガイドでは、Pages UIを使用して、静的サイトまたはフレームワークベースのアプリケーションをデプロイする方法について説明します。

## 前提要件

- アプリは[`public`フォルダーにファイルを出力](../public_folder.md)する必要があります。ビルドパイプライン中にこのフォルダーを作成する場合、Gitにコミットする必要はありません。

  {{< alert type="warning" >}}

  この手順は重要です。ファイルがルートレベルの`public`フォルダーに確実に配置されるようにしてください。

  {{< /alert >}}

- 次のいずれかのプロジェクトが必要です。
  - [Eleventy](https://www.11ty.dev)、[Astro](https://astro.build)、[Jekyll](https://jekyllrb.com)などの静的サイトまたはクライアントレンダリングのシングルページアプリケーション（SPA）を生成するプロジェクト
  - [Next.js](https://nextjs.org)、[Nuxt](https://nuxt.com)、[SvelteKit](https://kit.svelte.dev)などの静的出力用に設定されたフレームワークを含んでいるプロジェクト
- プロジェクトに対してGitLab Pagesが有効になっている必要があります（有効にするには、**設定 > 一般**に移動し、**可視性、プロジェクトの機能、権限**を展開して、**Pages**切替をオンにします）。

## Pagesデプロイを作成する

セットアップを完了してGitLab Pagesデプロイを生成するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > Pages**を選択します。

   **Pagesを始める**フォームが表示されます。このフォームを利用できない場合は、「[トラブルシューティング](#if-the-get-started-with-pages-form-is-not-available)」を参照してください。
1. **ステップ1**で、イメージ名を入力し、ファイルが`public`フォルダーにあることを確認します。
1. **次へ**を選択します。
1. **ステップ2**で、インストール手順を入力します。フレームワークのビルドプロセスで、用意されているビルドコマンドのいずれかが不要な場合は、次のいずれかを行います。
   - **次へ**を選択して、ステップをスキップします。
   - そのステップのボイラープレートを`.gitlab-ci.yml`ファイルに組み込む場合は、`:`（bashの「何もしない」コマンド）を入力します。
1. **次へ**を選択します。
1. **ステップ3**で、アプリケーションのビルド方法を示すスクリプトを入力します。
1. **次へ**を選択します。
1. オプション。必要に応じて、生成された`.gitlab-ci.yml`ファイルを編集します。
1. **ステップ4**で、コミットメッセージを追加し、**コミット**を選択します。このコミットにより、最初のGitLab Pagesデプロイがトリガーされます。

実行中のパイプラインを表示するには、**ビルドする > パイプライン**に移動します。

デプロイ中に作成されたアーティファクトを表示するには、ジョブを表示し、右側の**アーティファクトをダウンロード**を選択します。

## トラブルシューティング

### `Get Started with Pages`フォームを利用できない場合

次の場合、`Get Started with Pages`フォームは利用できません。

- 以前にGitLab Pagesサイトをデプロイした。
- 少なくとも1回、フォームから`.gitlab-ci.yml`をコミットした。

この問題を解決するには:

- メッセージ**Pagesパイプラインが完了するのを待機しています**が表示された場合は、**最初から実行**を選択してフォームを再度開始します。
- プロジェクトで以前にGitLab Pagesが正常にデプロイされた場合は、`.gitlab-ci.yml`ファイルを[手動で更新](pages_from_scratch.md)します。
