---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 最も一般的な静的サイトジェネレーターのビルド出力フォルダーを設定する方法を学習します。
title: GitLab Pagesのpublicフォルダー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1では、`.gitlab-ci.yml`で公開フォルダーを設定するサポートが導入されました。フレームワークの設定を変更する必要はなくなりました。詳細については、[Pagesでデプロイするカスタムフォルダーを設定](introduction.md#customize-the-default-folder)を参照してください。

{{< /history >}}

次のフレームワークの`public`フォルダーを設定するには、以下の手順に従ってください。

## Eleventy {#eleventy}

Eleventyの場合、次のいずれかを実行する必要があります:

- Eleventyのビルドコマンドで`--output=public`フラグを追加します。例:

  `npx @11ty/eleventy --input=path/to/sourcefiles --output=public`

- 次の内容を`.eleventy.js`ファイルに追加します:

  ```javascript
  // .eleventy.js
  module.exports = function(eleventyConfig) {
    return {
      dir: {
        output: "public"
      }
    }
  };
  ```

## Astro {#astro}

デフォルトでは、Astroは静的アセットを保存するために`public`フォルダーを使用します。GitLab Pagesの場合、まずそのフォルダーを衝突のない代替名に変更してください:

1. プロジェクトディレクトリで、次を実行します。

   ```shell
   mv public static
   ```

1. 名前変更されたフォルダー用にAstroを設定するために、次の内容を`astro.config.mjs`に追加します:

   ```javascript
   // astro.config.mjs
   import { defineConfig } from 'astro/config';

   export default defineConfig({
     // GitLab Pages requires exposed files to be located in a folder called "public".
     // This instructs Astro to put the static build output in a folder of that name.
     outDir: 'public',

     // The folder name Astro uses for static files (`public`) is already reserved
     // for the build output. This uses a folder called `static` instead.
     publicDir: 'static',
   });
   ```

## SvelteKit {#sveltekit}

> [!note]
> GitLab Pagesは静的サイトのみをサポートします。SvelteKitの場合、[`adapter-static`](https://kit.svelte.dev/docs/adapters#supported-environments-static-sites)を使用できます。

`adapter-static`を使用する場合、次の内容を`svelte.config.js`に追加します:

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-static';

export default {
  kit: {
    adapter: adapter({
      pages: 'public'
    })
  }
};
```

## Next.js {#nextjs}

> [!note]
> GitLab Pagesは静的サイトのみをサポートします。Next.jsの場合、Nextの[Static HTMLエクスポート機能](https://nextjs.org/docs/pages/building-your-application/deploying/static-exports)を使用できます。

[Next.js 13](https://nextjs.org/blog/next-13)のリリースにより、Next.jsの動作が大きく変わりました。すべての静的アセットを適切にエクスポートできるように、次の`next.config.js`を使用する必要があります:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    unoptimized: true,
  },
  assetPrefix: "https://example.gitlab.io/namespace-here/my-gitlab-project/"
}

module.exports = nextConfig
```

例えば、`.gitlab-ci.yml`は最小限にすると次のようになります:

```yaml
create-pages:
  before_script:
    - npm install
  script:
    - npm run build
    - mv out/* public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

## Nuxt.js {#nuxtjs}

> [!note]
> GitLab Pagesは静的サイトのみをサポートします。

デフォルトでは、Nuxtは静的アセットを保存するために`public`フォルダーを使用します。GitLab Pagesの場合、まず`public`フォルダーを衝突のない代替名に変更してください:

1. プロジェクトディレクトリで、次を実行します。

   ```shell
   mv public static
   ```

1. 次の内容を`nuxt.config.js`に追加します:

   ```javascript
   export default {
     target: 'static',
     generate: {
       dir: 'public'
     },
     dir: {
       // The folder name Nuxt uses for static files (`public`) is already
       // reserved for the build output. This uses a folder called `static` instead.
       public: 'static'
     }
   }
   ```

1. Nuxt.jsアプリケーションを[Static Site Generation](https://nuxt.com/docs/getting-started/deployment#static-hosting)用に設定します。

## Vite {#vite}

`vite.config.js`を更新して、次の内容を含めます:

```javascript
// vite.config.js
export default {
  build: {
    outDir: 'public'
  }
}
```

## Webpack {#webpack}

`webpack.config.js`を更新して、次の内容を含めます:

```javascript
// webpack.config.js
module.exports = {
  output: {
    path: __dirname + '/public'
  }
};
```

## `public`フォルダーをコミットする必要がありますか？ {#should-you-commit-the-public-folder}

必ずしも必要ではありません。ただし、GitLab Pagesのデプロイパイプラインが実行されると、その名前の[アーティファクト](../../../ci/jobs/job_artifacts.md)を検索します。デプロイ前に`public`フォルダーを作成するジョブを設定した場合、たとえば`npm run build`を実行して作成した場合、フォルダーをコミットする必要はありません。

サイトをローカルでビルドしたい場合は、`public`フォルダーをコミットし、代わりにジョブ中のビルドステップを省略できます。
