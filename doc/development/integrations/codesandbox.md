---
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Set up local CodeSandbox development environment

This guide walks through setting up a local [CodeSandbox repository](https://github.com/codesandbox/codesandbox-client) and integrating it with a local GitLab instance. CodeSandbox
is used to power the Web IDE's [Live Preview feature](../../user/project/web_ide/index.md#live-preview). Having a local CodeSandbox setup is useful for debugging upstream issues or
creating upstream contributions like [this one](https://github.com/codesandbox/codesandbox-client/pull/5137).

## Initial setup

Before using CodeSandbox with your local GitLab instance, you must:

1. Enable HTTPS on your GDK. CodeSandbox uses Service Workers that require `https`.
   Follow the GDK [NGINX configuration instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/nginx.md) to enable HTTPS for GDK.
1. Clone the [`codesandbox-client` project](https://github.com/codesandbox/codesandbox-client)
   locally. If you plan on contributing upstream, you might want to fork and clone first.
1. (Optional) Use correct `python` and `nodejs` versions. Otherwise, `yarn` may fail to
   install or build some packages. If you're using `asdf` you can run the following commands:

   ```shell
   asdf local nodejs 10.14.2
   asdf local python 2.7.18
   ```

1. Run the following commands in the `codesandbox-client` project checkout:

   ```shell
   # This might be necessary for the `prepublishOnly` job that is run later
   yarn global add lerna

   # Install packages
   yarn
   ```

   You can run `yarn build:clean` to clean up the build assets.

## Use local GitLab instance with local CodeSandbox

GitLab integrates with two parts of CodeSandbox:

- An npm package called `smooshpack` (called `sandpack` in the `codesandbox-client` project).
  This exposes an entrypoint for us to kick off Codesandbox's bundler.
- A server that houses CodeSandbox assets for bundling and previewing. This is hosted
  on a separate server for security.

Each time you want to run GitLab and CodeSandbox together, you need to perform the
steps in the following sections.

### Use local `smooshpack` for GitLab

GitLab usually satisfies its `smooshpack` dependency with a remote module, but we want
to use a locally-built module. To build and use a local `smooshpack` module:

1. In the `codesandbox-client` project directory, run:

   ```shell
   cd standalone-packages/sandpack
   yarn link

   # (Optional) you might want to start a development build
   yarn run start
   ```

   Now, in the GitLab project, you can run `yarn link "smooshpack"`. `yarn` looks
   for `smooshpack` **on disk** as opposed to the one hosted remotely.

1. In the `gitlab` project directory, run:

   ```shell
   # Remove and reinstall node_modules just to be safe
   rm -rf node_modules
   yarn install

   # Use the "smooshpack" package on disk
   yarn link "smooshpack"
   ```

### Fix possible GDK webpack problem

`webpack` in GDK can fail to find packages inside a linked package. This step can help
you avoid `webpack` breaking with messages saying that it can't resolve packages from
`smooshpack/dist/sandpack.es5.js`.

In the `codesandbox-client` project directory, run:

```shell
cd standalone-packages

mkdir node_modules
ln -s $PATH_TO_LOCAL_GITLAB/node_modules/core-js ./node_modules/core-js
```

### Start building CodeSandbox app assets

In the `codesandbox-client` project directory:

```shell
cd packages/app

yarn start:sandpack-sandbox
```

### Create HTTPS proxy for CodeSandbox `sandpack` assets

Because we need `https`, we need to create a proxy to the webpack server. We can use
[`http-server`](https://www.npmjs.com/package/http-server), which can do this proxying
out of the box:

```shell
npx http-server --proxy http://localhost:3000 -S -C $PATH_TO_CERT_PEM -K $PATH_TO_KEY_PEM -p 8044 -d false
```

### Update `bundler_url` setting in GitLab

We need to update our `application_setting_implementation.rb` to point to the server that hosts the
CodeSandbox `sandpack` assets. For instance, if these assets are hosted by a server at `https://sandpack.local:8044`:

```patch
diff --git a/app/models/application_setting_implementation.rb b/app/models/application_setting_implementation.rb
index 6eed627b502..1824669e881 100644
--- a/app/models/application_setting_implementation.rb
+++ b/app/models/application_setting_implementation.rb
@@ -391,7 +391,7 @@ def static_objects_external_storage_enabled?
   # This will eventually be configurable
   # https://gitlab.com/gitlab-org/gitlab/-/issues/208161
   def web_ide_clientside_preview_bundler_url
-    'https://sandbox-prod.gitlab-static.net'
+    'https://sandpack.local:8044'
   end

   private

```

NOTE:
You can apply this patch by copying it to your clipboard and running `pbpaste | git apply`.

You may want to restart the GitLab Rails server after making this change:

```shell
gdk restart rails-web
```
