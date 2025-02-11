---
description: 'Learn how to configure the build output folder for the most
common static site generators'
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages public folder
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - With GitLab 16.1 we introduced the ability to configure the published folder in `.gitlab-ci.yml`, so you longer need to change your framework config. For more information, see how to [set a custom folder to be deployed with Pages](introduction.md#customize-the-default-folder).

Follow these instructions to configure the `public` folder
for the following frameworks.

## Eleventy

For Eleventy, you should do one of the following:

- Add the `--output=public` flag in the Eleventy build commands, for example:

  `npx @11ty/eleventy --input=path/to/sourcefiles --output=public`

- Add the following to your `.eleventy.js` file:

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

## Astro

By default, Astro uses the `public` folder to store static assets. For GitLab Pages,
rename that folder to a collision-free alternative first:

1. In your project directory, run:

   ```shell
   mv public static
   ```

1. Add the following to your `astro.config.mjs`. This code informs Astro about
   our folder name remapping:

   ```javascript
   // astro.config.mjs
   import { defineConfig } from 'astro/config';

   export default defineConfig({
     // GitLab Pages requires exposed files to be located in a folder called "public".
     // So we're instructing Astro to put the static build output in a folder of that name.
     outDir: 'public',

     // The folder name Astro uses for static files (`public`) is already reserved
     // for the build output. So in deviation from the defaults we're using a folder
     // called `static` instead.
     publicDir: 'static',
   });
   ```

## SvelteKit

NOTE:
GitLab Pages supports only static sites. For SvelteKit,
you can use [`adapter-static`](https://kit.svelte.dev/docs/adapters#supported-environments-static-sites).

When using `adapter-static`, add the following to your `svelte.config.js`:

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

## Next.js

NOTE:
GitLab Pages supports only static sites. For Next.js, you can use
Next's [Static HTML export functionality](https://nextjs.org/docs/pages/building-your-application/deploying/static-exports).

With the release of [Next.js 13](https://nextjs.org/blog/next-13) a lot has changed on how Next.js works.
It is recommended to use the following `next.config.js` so all static assets can be exported properly:

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

An example `.gitlab-ci.yml` can be as minimal as:

```yaml
deploy-pages:
  before_script:
    - npm install
  script:
    - npm run build
    - mv out/* public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
```

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

## Nuxt.js

NOTE:
GitLab Pages supports only static sites.

By default, Nuxt uses the `public` folder to store static assets. For GitLab
Pages, rename the `public` folder to a collision-free alternative first:

1. In your project directory, run:

   ```shell
   mv public static
   ```

1. Add the following to your `nuxt.config.js`:

   ```javascript
   export default {
     target: 'static',
     generate: {
       dir: 'public'
     },
     dir: {
       // The folder name Nuxt uses for static files (`public`) is already
       // reserved for the build output. So in deviation from the defaults we're
       // using a folder called `static` instead.
       public: 'static'
     }
   }
   ```

1. Configure your Nuxt.js application for
   [Static Site Generation](https://nuxt.com/docs/getting-started/deployment#static-hosting).

## Vite

Update your `vite.config.js` to include the following:

```javascript
// vite.config.js
export default {
  build: {
    outDir: 'public'
  }
}
```

## Webpack

Update your `webpack.config.js` to include the following:

```javascript
// webpack.config.js
module.exports = {
  output: {
    path: __dirname + '/public'
  }
};
```

## Should you commit the `public` folder?

Not necessarily. However, when the GitLab Pages deploy pipeline runs, it looks
for an [artifact](../../../ci/jobs/job_artifacts.md) of that name.
If you set up a job that creates the `public` folder before deploy, such as by
running `npm run build`, committing the folder isn't required.

If you prefer to build your site locally, you can commit the `public` folder and
omit the build step during the job instead.
