---
description: 'Learn how to configure the build output folder for the most
common static site generators'
stage: Create
group: Incubation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the public files folder **(FREE)**

GitLab Pages requires all files you intend to be available in the published website to
be in a root-level folder called `public`. This page describe how
to set this up for some common static site generators.

## Guide by framework

### Eleventy

For Eleventy, you should either:

1. Add the `--output=public` flag in Eleventy's build commands, for example:

   `npx @11ty/eleventy --input=path/to/sourcefiles --output=public`

1. Add the following to your `.eleventy.js` file:

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

### Astro

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

### SvelteKit

NOTE:
GitLab Pages supports only static sites. For SvelteKit,
we recommend using [`adapter-static`](https://kit.svelte.dev/docs/adapters#supported-environments-static-sites).

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

### Next.js

NOTE:
GitLab Pages supports only static sites. For Next.js, we
recommend using Next's [Static HTML export functionality](https://nextjs.org/docs/advanced-features/static-html-export)

Use the `-o public` flag after `next export` as the build command, for
example:

```shell
next export -o public
```

### Nuxt.js

NOTE:
GitLab Pages supports only static sites.

1. Add the following to your `nuxt.config.js`:

   ```javascript
   export default {
     target: 'static',
     generate: {
       dir: 'public'
     }
   }
   ```

1. Configure your Nuxt.js application for
   [Static Site Generation](https://nuxtjs.org/docs/features/deployment-targets/#static-hosting).

### Vite

Update your `vite.config.js` to include the following:

```javascript
// vite.config.js
export default {
  build: {
    outDir: 'public'
  }
}
```

### Webpack

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
for an [artifact](../../../ci/pipelines/job_artifacts.md) of that name. So
If you set up a job that creates the `public` folder before deploy, such as by
running `npm run build`, committing the folder isn't required.

If you prefer to build your site locally, you can commit the `public` folder and
omit the build step during the job, instead.
