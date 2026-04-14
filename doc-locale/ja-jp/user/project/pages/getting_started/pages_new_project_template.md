---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトテンプレートからGitLab Pagesウェブサイトを作成します
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、最も人気のある静的サイトジェネレーター（SSG）用のテンプレートを提供します。テンプレートから新しいプロジェクトを作成し、CI/CDパイプラインを実行してPagesウェブサイトを生成できます。

GitLab Pagesをテストしたい場合や、すでにPagesサイトを生成するように設定されている新しいプロジェクトを開始したい場合は、テンプレートを使用します。

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **Create from Template**を選択します。
1. **Pages**で始まるテンプレートのいずれかの隣にある**テンプレートを使用**を選択します。
1. フォームに入力し、**プロジェクトを作成**を選択します。
1. 左サイドバーで**ビルド** > **パイプライン**を選択し、**新しいパイプライン**を選択して、GitLab CI/CDがサイトをビルドおよびデプロイするようにトリガーします。

パイプラインが完了したら、**デプロイ** > **Pages**に移動して、Pagesウェブサイトへのリンクを見つけてください。

リポジトリにプッシュされたすべての変更に対して、GitLab CI/CDは新しいパイプラインを実行し、変更をPagesサイトに即座に公開します。

サイト用に作成されたHTMLおよびその他の資産を表示するには、[ジョブアーティファクトをダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)します。

## プロジェクトテンプレート {#project-templates}

{{< history >}}

- GitLab 18.0でプロジェクトテンプレートから以下のテンプレートが[削除](https://gitlab.com/groups/gitlab-org/-/epics/13847)されました: [`Bridgetown`](https://gitlab.com/pages/bridgetown) 、[`Gatsby`](https://gitlab.com/pages/gatsby) 、[`Hexo`](https://gitlab.com/pages/hexo) 、[`Middleman`](https://gitlab.com/pages/middleman)、`Netlify/GitBook`、[`Netlify/Hexo`](https://gitlab.com/pages/nfhexo) 、[`Netlify/Hugo`](https://gitlab.com/pages/nfhugo) 、[`Netlify/Jekyll`](https://gitlab.com/pages/nfjekyll) 、[`Netlify/Plain HTML`](https://gitlab.com/pages/nfplain-html) 、および[`Pelican`](https://gitlab.com/pages/pelican)。

{{< /history >}}

GitLabは、これらのフレームワーク用のテンプレートプロジェクトを管理しています:

| Realm          | フレームワーク                                           | 利用可能なプロジェクトテンプレート |
|----------------|-----------------------------------------------------|-----------------------------|
| **Go**         | [`hugo`](https://gitlab.com/pages/hugo)             | Pages/Hugo                  |
| **Markdown**   | [`astro`](https://gitlab.com/pages/astro)           | Pages/Astro                 |
| **Markdown**   | [`docusaurus`](https://gitlab.com/pages/docusaurus) | Pages/Docusaurus            |
| **Plain HTML** | [`plain-html`](https://gitlab.com/pages/plain-html) | Pages/Plain HTML            |
| **React**      | [`next.js`](https://gitlab.com/pages/nextjs)        | Pages/Next.js               |
| **Ruby**       | [`jekyll`](https://gitlab.com/pages/jekyll)         | Pages/Jekyll                |
| **Vue.js**     | [`nuxt`](https://gitlab.com/pages/nuxt)             | Pages/Nuxt                  |
