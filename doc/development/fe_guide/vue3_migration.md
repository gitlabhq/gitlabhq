---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Migration to Vue 3
---

The migration from Vue 2 to 3 is tracked in epic [&6252](https://gitlab.com/groups/gitlab-org/-/work_items/6252).

To ease migration to Vue 3.x, we have added [ESLint rules](https://gitlab.com/gitlab-org/frontend/eslint-plugin/-/merge_requests/50)
that prevent us from using the following deprecated features in the codebase.

## GitLab can use Vue 3 (@vue/compat)

The GitLab frontend team has enabled Vue 3 (@vue/compat) for development environments like GDK. While not yet production-ready, you can opt-in locally to verify your client code is forward-compatible with Vue 3.

**How does it work?** When the build tool (Vite or Webpack) detects the VUE_VERSION=3 environment variable,
it uses module aliasing to swap out certain dependencies, including Vue itself, for their Vue 3-compatible counterparts.

Some of these replacement libraries are maintained by the team. They act as thin wrappers around existing
libraries, making them Vue 3-compatible without requiring any changes in consumer code.

## Set up GDK to use Vue 3 (@vue/compat)

This guide walks you through configuring the GitLab Development Kit (GDK) to use Vite as the build tool with Vue 3.

### Prerequisites

- GDK installed and configured
- Basic familiarity with Vue.js and Vite
- Vite configured in your GDK environment (see [GDK Vite Settings](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md?ref_type=heads#vite-settings))

### Initial Setup

### Switching Between Vue Versions

To switch between Vue 2 and Vue 3, follow these steps:

1. **Set the desired Vue version:**

   ```shell
   gdk config set vite.vue_version 3  # or 2
   ```

1. **Reconfigure GDK:**

   ```shell
   gdk reconfigure
   ```

1. **Restart GDK:**

   ```shell
   gdk restart # or `gdk start` if running for the first time
   ```

> **Important:** You can clear caches with `yarn clean` or `gdk kill vite` if you face issues switching Vue versions.

### Verifying Your Setup

You can verify your Vite configuration by checking your `gdk.yml` file:

```shell
gdk config get vite
```

This should display your current Vite settings, including the enabled status and Vue version. Your GDK
should also be up and running.

```shell
---
enabled: true
hot_module_reloading: true
https:
  enabled: true
port: 3038
vue_version: 3
```

### Troubleshooting

#### General Debugging

When encountering issues, start by checking the Vite logs:

```shell
gdk tail vite
```

This shows real-time Vite output and error messages that can help identify the problem.

#### Build Errors After Switching Versions

If you encounter build errors after switching Vue versions:

1. Ensure you've cleared the Vite cache with `yarn clean`
1. Try clearing `node_modules` and reinstalling dependencies:

   ```shell
   rm -rf node_modules
   yarn install
   ```

#### Vite Not Starting

If Vite fails to start:

- Check that `vite.enabled` is set to `true`
- Verify your Node.js version meets Vite's requirements
- Review GDK logs for specific error messages

### Additional Resources

- [Vite Documentation](https://vitejs.dev/)
- [Vue 3 Documentation](https://vuejs.org/)
- [GDK Documentation](https://gitlab.com/gitlab-org/gitlab-development-kit)

## Compatibility changes

The changes below are the ones this migration hits most often, not the whole surface. An app can
break on anything it imports, so treat this list as a starting point rather than a checklist. The
libraries aliased in `config/helpers/context_aliases_shared.js`, such as `vuex`, `vue-router`,
`vue-apollo`, `portal-vue`, `vuedraggable`, and the virtual scrollers, run through a Vue 3 shim and
are the most sensitive to a migration.

### Vue filters

**Why**

Filters [are removed](https://github.com/vuejs/rfcs/blob/master/active-rfcs/0015-remove-filters.md) from the Vue 3 API completely.

**What to use instead**

Component's computed properties / methods or external helpers.

### Event hub

**Why**

`$on`, `$once`, and `$off` methods [are removed](https://github.com/vuejs/rfcs/blob/master/active-rfcs/0020-events-api-change.md) from the Vue instance, so in Vue 3 it can't be used to create an event hub.

**When to use**

If you are in a Vue app that doesn't use any event hub, try to avoid adding a new one unless absolutely necessary. For example, if you need a child component to react to its parent's event, it's preferred to pass a prop down. Then, use the watch property on that prop in the child component to create the desired side effect.

If you need cross-component communication (between different Vue apps), then perhaps introducing a hub is the right decision.

**What to use instead**

We have created a factory that you can use to instantiate a new [mitt](https://github.com/developit/mitt)-like event hub.

This makes it easier to migrate existing event hubs to the new recommended approach, or
to create new ones.

```javascript
import createEventHub from '~/helpers/event_hub_factory';

export default createEventHub();
```

Event hubs created with the factory expose the same methods as Vue 2 event hubs (`$on`, `$once`, `$off` and
`$emit`), making them backward compatible with our previous approach.

### \<template functional>

**Why**

In Vue 3, `{ functional: true }` option [is removed](https://github.com/vuejs/rfcs/blob/functional-async-api-change/active-rfcs/0007-functional-async-api-change.md) and `<template functional>` is no longer supported.

**What to use instead**

Functional components must be written as plain functions:

```javascript
import { h } from 'vue'

const FunctionalComp = (props, slots) => {
  return h('div', `Hello! ${props.name}`)
}
```

It is not recommended to replace stateful components with functional components unless you absolutely need a performance improvement right now. In Vue 3, performance gains for functional components are negligible.

### Old slots syntax with `slot` attribute

**Why**

In Vue 2.6 `slot` attribute was already deprecated in favor of `v-slot` directive. The `slot` attribute usage is still allowed and sometimes we prefer using it because it simplifies unit tests (with old syntax, slots are rendered on `shallowMount`). However, in Vue 3 we can't use old syntax anymore.

**What to use instead**

The syntax with `v-slot` directive. To fix rendering slots in `shallowMount`, we need to stub a child component with slots explicitly.

```html
<!-- MyAwesomeComponent.vue -->
<script>
import SomeChildComponent from './some_child_component.vue'

export default {
  components: {
    SomeChildComponent
  }
}

</script>

<template>
  <div>
    <h1>Hello GitLab!</h1>
    <some-child-component>
      <template #header>
        Header content
      </template>
    </some-child-component>
  </div>
</template>
```

```javascript
// MyAwesomeComponent.spec.js

import SomeChildComponent from '~/some_child_component.vue'

shallowMount(MyAwesomeComponent, {
  stubs: {
    SomeChildComponent
  }
})
```

### Props default function `this` access

**Why**

In Vue 3, props default value factory functions no longer have access to `this`
(the component instance).

**What to use instead**

Write a computed prop that resolves the desired value from other props. This
works in both Vue 2 and 3.

```html
<script>
export default {
  props: {
    metric: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    actualTitle() {
      return this.title ?? this.metric;
    },
  },
}

</script>

<template>
  <div>{{ actualTitle }}</div>
</template>
```

[In Vue 3](https://v3-migration.vuejs.org/breaking-changes/props-default-this.html),
the props default value factory is passed the raw props as an argument, and can
also access injections.

### `Vue.observable`

**Why?**

`Vue.observable` creates reactive state that is tied to the Vue version that created it.
In the hybrid Vue 2/Vue 3 infection system, modules can be duplicated - one copy for
each Vue version. When these modules use `Vue.observable()`, each copy creates its own
separate reactive object, so state changes in one are invisible to the other.

**What to use instead**

Use `observable()` from `~/lib/utils/observable`:

```javascript
import { observable } from '~/lib/utils/observable';

// Before
export const state = Vue.observable({ count: 0 });

// After
export const state = observable('unique_key', { count: 0 });
```

The `observable(key, defaults)` function:

- Stores a single canonical state in a global registry keyed by `key`
- Creates a per-Vue-context reactive mirror via `Vue.observable()` internally
- Returns a Proxy that syncs writes to all mirrors across Vue versions
- Supports flat objects, getters, and methods

The `key` must be a unique string identifier (for example, `'super_sidebar_state'`). It ensures
both module copies share the same underlying state.

An ESLint rule (`no-restricted-properties`) enforces this - direct `Vue.observable` usage
produces a lint error.

**Limitations**

- **Flat objects only**: Nested mutations like `state.nested.prop = value` or `state.array.push(item)` do not sync across Vue versions. Refactor to top-level property replacement instead:

  ```javascript
  // Instead of: state.items.push(newItem)
  state.items = [...state.items, newItem];

  // Instead of: state.config[key] = value
  state.config = { ...state.config, [key]: value };
  ```

### Handling libraries that do not work with `@vue/compat`

**Problem**

Some libraries rely on Vue.js 2 internals. They might not work with `@vue/compat`, so we have added an adapter or replacements as a compatibility layer.

**Goals**

- We should add as few changes as possible to existing code to support new libraries. Instead, we should **add** new code, which acts as **a facade**, making the new version compatible with the old one
- Switching between new and old versions should be hidden inside tooling (webpack / jest) and should not be exposed to the code
- All facades specific to migration should live in the same directory to simplify future migration steps

## Migrate to Vue 3

For general Vue 3 migration information, see the
[Vue 3 official migration guide](https://v3-migration.vuejs.org/).

### Option 1 (recommended): Migrate your page entrypoint using a feature flag and `vue3_migration.yml`

GitLab declares the migration state of every page entry under `app/assets/javascripts/pages` (and
the EE and JH equivalents) in a `vue3_migration.yml` file co-located with the page's entrypoint,
called `index.js`.

```plaintext
└── pages/
    └── [area]/
        └── [page]/
            ├── index.js              # Entrypoint: imports and calls the initializer
            └── vue3_migration.yml    # Declares the page's migration status
```

The bundler reads these files to decide whether to emit a Vue 3 chunk, and Rails decides at
request time which chunk to render depending on the feature flag.

```yaml
status: rollout
feature_flag: vue3_migrate_jobs # we recommend naming the flag `vue3_migrate_<page>`
group: group::pipeline authoring # optional
migration_issue: https://gitlab.com/gitlab-org/gitlab/-/work_items/... # optional
```

When the file exists, it must declare a `status` field with one of two values:

- `rollout`: both Vue 2 and Vue 3 chunks are built (the Vue 3 chunk as a `.vue3` sibling
  entrypoint). Rails serves the Vue 3 chunk when the declared feature flag is enabled, and the
  Vue 2 chunk otherwise. A `feature_flag` field is required.
- `migrated`: only the Vue 3 chunk is built, under the original entrypoint name, so Rails serves
  it with no lookup at all. Use this after the feature flag has been fully rolled out and removed.

Optional fields `group` and `migration_issue` are accepted for documentation. The schema is
defined in `config/helpers/vue3_migration_file_validation.js`.

#### How the metadata reaches production

Rails does not read the `vue3_migration.yml` files at runtime in production: packaged builds
(for example, Omnibus) strip `app/assets` from the Rails application, so the files do not exist
there. Instead, the webpack build compiles the `rollout` entries into a single
`public/assets/webpack/vue3_migration.json` manifest
(see `config/plugins/vue3_migration_manifest_plugin.js`), which ships with the compiled assets in
every distribution.

To verify which apps run under Vue 3 on any environment, query the DOM marker set by the Vue 3
runtime: `document.querySelectorAll('[data-gitlab-vue3-app]')`.

Use the [`beta`](../feature_flags/_index.md#beta-type) feature flag type, since it is the only
type that lets you both enable the migration by default and still turn it off if a regression
appears.

#### Migration steps

1. Identify your page's entrypoint under `app/assets/javascripts/pages` (or `ee/...`).
   For example, `app/assets/javascripts/pages/projects/jobs/show/index.js`.
1. Create or update the feature flag in `config/feature_flags/`. The migration mechanism uses
   the current user as the actor.
1. Create a `vue3_migration.yml` file next to the page's `index.js`, declaring `status: rollout`
   with the feature flag name:

   ```yaml
   # app/assets/javascripts/pages/projects/jobs/show/vue3_migration.yml
   status: rollout
   feature_flag: vue3_migrate_jobs
   ```

   If the page is shadowed across CE and EE, add the file to whichever directory currently owns
   the `index.js`, or to both if both directories contain an `index.js`. CE and EE YAMLs for the
   same page must agree on `status` and `feature_flag`.
1. Restart Vite with `gdk restart vite`. Vite builds its page entry map at startup, so it does not
   serve an entrypoint added while it was running.
1. Enable the feature flag and load the page locally.
1. Verify that the console shows
   `[gitlab] [V] Using Vue.js 3 (with @vue/compat) for <your app name>`.
1. Verify that `document.querySelectorAll('[data-gitlab-vue3-app]')` returns your app.
1. **Verify the app works correctly locally**. To turn that check into evidence a reviewer can
   watch, see [Record the verification as a video](#record-the-verification-as-a-video).
1. Open an MR with your changes and get them merged!
1. Proceed with the feature flag rollout with the `user` actor.
1. Upon removing the feature flag, change the YAML to `status: migrated` and
   remove the `feature_flag` line. You are done!

### Option 2: Migrate your page partially using `?vue3`

A `vue3_migration.yml` file applies to the entire page entry, so it moves every app that the
entrypoint initializes. Some entrypoints mount many independent apps owned by different teams.
Settings pages are a common case, where a single `index.js` initializes a dozen unrelated apps.

If you own one app on such a page, `Option 1` is too wide: enabling your feature flag would also
move apps you do not own.

Instead, add `?vue3` to the import of your own app. Every module below that import is built for
Vue 3, and the rest of the page stays on Vue 2. Use this option when Option 1 does not fit,
because it costs more code: a feature flag wired through your controller, and a conditional in the
page entrypoint.

#### Migration steps

1. Create or update the feature flag in `config/feature_flags/`.
1. Push the flag to the frontend from the controller that renders the page:

   ```ruby
   # app/controllers/projects/settings/ci_cd_controller.rb
   before_action do
     push_frontend_feature_flag(:vue3_migrate_my_app, current_user)
   end
   ```

1. In the page entrypoint, import the Vue 3 build of your app dynamically when the flag is
   enabled, and fall back to the Vue 2 build if that import fails:

   ```javascript
   // app/assets/javascripts/pages/projects/settings/ci_cd/show/index.js
   import { initMyApp } from '~/my_app';
   import { initOtherApp } from '~/other_app';
   import * as Sentry from '~/sentry/sentry_browser_wrapper';

   // Other apps on this page stay on Vue 2.
   initOtherApp();

   if (gon.features?.vue3MigrateMyApp) {
     (async () => {
       try {
         // eslint-disable-next-line no-shadow -- Override with Vue 3 app
         const { initMyApp } = await import('~/my_app?vue3');
         initMyApp();
         return;
       } catch (e) {
         Sentry.captureException(e);
       }

       initMyApp();
     })();
   } else {
     initMyApp();
   }
   ```

   Keep the `?vue3` path a string literal, because the bundler cannot see a path built at runtime.
   Point the `?vue3` import at the module that creates the Vue instance: infection propagates downward, so an
   import higher in the tree also moves every other app below it. Declare the import inside the
   `try` block so the outer Vue 2 import stays in scope for the fallback.

1. Enable the feature flag and load the page locally.
1. Verify that the console shows
   `[gitlab] [V] Using Vue.js 3 (with @vue/compat) for <your app name>`.
1. Verify that `document.querySelectorAll('[data-gitlab-vue3-app]')` returns your app.
1. **Verify the app works correctly locally**, and record the walkthrough as evidence for the
   reviewer.
1. Open an MR with your changes and get them merged.
1. Proceed with the feature flag rollout with the `user` actor.
1. Upon removing the feature flag, import `~/my_app?vue3` directly and delete both the conditional
   and the Vue 2 import.

### Record the verification as a video

Both options end with the same manual step: check that the app still works under Vue 3. Unit tests
mount a component in isolation, so regressions that need a browser survive a green suite, and an MR
that states "verified locally" leaves the reviewer nothing to look at. Have an AI agent walk the app
in a browser, record the session, and attach the video to your MR.

> [!warning]
> The agent drives a real browser with your signed-in session, so every interaction it performs is
> a real write. It can create, change, and delete data. Record against seeded data in your local
> GDK only, never against a shared or production environment, and tell the agent which records it
> may touch. A separate browser profile (`--user-data-dir`) isolates the session and its cookies,
> but it does not limit what the agent can change in the application. If you need that guarantee,
> record against a disposable GDK.

#### Playwright Record MCP

[Playwright Record MCP](https://gitlab.com/jotolo_gl/playwright-record-mcp) is a Model Context
Protocol (MCP) server that gives an agent Playwright browser tools (`browser_navigate`,
`browser_click`, `browser_type`, `browser_snapshot`, and others), records the session, and exports
it as an H.264 `.mp4`.

To install it, ask your agent to follow the README section
**Instructions for AI agents (autonomous install)**. That section covers the prerequisites
(Node.js 18 or later, `ffmpeg`), the clone, `npx playwright install chromium`, and the MCP client
registration. Restart your MCP client afterwards, because the server is not available in the
session that installed it.

#### Suggested workflow

1. List the interactions the app supports, and derive the list from the component templates and
   their specs instead of from memory. Each interaction is one step in the recording: form
   submissions, filters, dropdowns, dialogs, dragging, pagination, empty states, and error
   states.
1. Prepare the stage before you record: the project, the records, and the states the checklist
   needs. Doing this yourself keeps setup out of the video and keeps the agent from improvising
   fixtures against your GDK. The seeders in `lib/gitlab/seeders/` cover common cases. You can
   delegate the setup, but hand the agent an explicit list, run it as its own step before the
   recording, and read what it created.
1. Ask the agent to run the list twice: once with the feature flag disabled, and once with it
   enabled. The Vue 2 pass is the baseline. A step that fails in both passes is an existing bug,
   not a migration regression.
1. Confirm that the second pass ran under Vue 3. Serving Vue 2 raises no error, so a mistake in the
   feature flag or in a `?vue3` import produces a video of the Vue 2 app. Pin the engine notice to
   the overlay with `--console-overlay-pin "Using Vue.js"`, and the video carries that proof
   itself. `browser_console_messages` reports the same lines if you want them in the run log.
1. Call `browser_video_save` with an `.mp4` filename as the last step. It closes the browser to
   finalize the video, so no other browser tool works afterwards. One session produces one video,
   so each pass needs its own session.
1. Attach the `.mp4` to your MR, together with the list of steps, and describe any difference
   between the two passes. With the [`glab` CLI](https://gitlab.com/gitlab-org/cli) installed, the
   agent can also do this itself. It uploads the file:

   ```shell
   glab api projects/<project-id-or-path>/uploads -X POST --form "file=@vue3-my-app.mp4"
   ```

   The response holds a `markdown` field. The agent puts that snippet in the MR description with
   `glab mr update <mr-id> --description ...`, or in a comment with `glab mr note <mr-id>`.

#### Show the console in the recording

Some Vue 3 regressions never reach the screen. A `@vue/compat` deprecation warning, or an error
thrown inside a handler that leaves the UI unchanged, exists only in the console. The previous step
catches these with `browser_console_messages`, but a reviewer cannot see a console in a video.

To carry the console in the video, add the overlay flags to the server arguments:

```shell
claude mcp add -s user playwright-record -- \
  node "$HOME/playwright-record-mcp/cli.js" \
  --record-video --video-dir "$HOME/playwright-record-mcp/mcp_videos" \
  --video-size 1280x800 --video-speed 1.5 \
  --console-overlay --console-overlay-pin "Using Vue.js"
```

Every console error and warning, every uncaught error, and every rejected promise is then painted
into a panel at the bottom right of the page, which the recording captures. The panel holds the
last eight messages, newest first, and survives navigation, so the reviewer reads the console as
the walkthrough runs. Because these are server flags, no instruction to the agent is needed.

Three options shape what the panel shows. Each one implies `--console-overlay`, so a pin on its own
is enough.

The panel covers what the application logs through `console`, plus uncaught errors and rejected
promises. Messages that the browser writes itself, for example a failed request, do not pass
through `console`, so they stay out of the panel. Read those from `browser_console_messages` and
`browser_network_requests`.

#### Starter prompt

Copy the following prompt to your agent to verify a migration end to end in a real browser, with
the recording as evidence. Adapt the details, such as the app name, the feature flag, and the
seeded data, before you run it.

<details>
<summary><strong>Starter prompt for your agent</strong></summary>

````markdown
You are verifying a Vue 2 to Vue 3 (`@vue/compat`) migration for a Vue app, in a real browser,
with a recorded video as evidence.

Fill these in before you run this prompt:

- GDK URL: `http://gdk.test:3000`
- Feature flag: `<vue3_migrate_my_app>`
- Page that mounts the app: `<path>`
- Sign-in: the username and password of a local GDK account.
- Project or records to use: `<what I already prepared for you>`

Only ever use a local GDK account. Never pass me credentials for a shared or production
environment.

Follow these steps in order.

Constraints:

- You drive a real browser against my local GDK, signed in as a real user. Every interaction is a
  real write, so stay on the records I named above and tell me anything you changed.
- Do not modify application code to make a step pass. Report the failure instead.
- Do not create projects, users, or fixtures, and do not run seeders or migrations. Verify against
  what I prepared. If the checklist needs a record that does not exist, or the environment errors
  on you, stop and tell me. A broken local environment is not a migration finding.
- Record with the console overlay on, so the video carries the console instead of a separate log.
  The server needs these arguments, and each overlay option implies `--console-overlay`:

  ```shell
  --record-video --video-size 1280x800 --video-speed 1.5 \
    --console-overlay --console-overlay-pin "Using Vue.js"
  ```

  If the panel is too noisy to read, narrow it with `--console-overlay-match <regex>`. If you need
  a level that the default does not paint, name it with `--console-overlay-levels error,warn,log`.
  Prefer these options over filtering the output yourself. You cannot restart the server, so tell
  me when a flag has to change and wait.
- Use the `playwright-record` MCP server for all browser actions: `browser_navigate`,
  `browser_click`, `browser_type`, `browser_hover`, `browser_drag`, `browser_select_option`,
  `browser_press_key`, `browser_snapshot`, `browser_wait`, `browser_console_messages`,
  `browser_network_requests`, `browser_video_save`. It cannot evaluate arbitrary JavaScript, so
  read state from `browser_snapshot` and `browser_console_messages`, not from the DOM.

1. Read the code before you touch a browser. Work out from the diff and the component source what
   the app does: which components sit in the migrated dependency tree, every `$emit` and every
   `v-on` or `@` listener, the `emits:` declarations, props with default factory functions, scoped
   slots, `v-model` usage, Vue Router usage, and anything the Vue 3 migration is known to break.
   Read the component's Jest specs too. They enumerate the behavior, and they show which covered
   behavior a browser walkthrough does not reach.

   Then read the compatibility changes in the migration guide,
   <https://docs.gitlab.com/development/fe_guide/vue3_migration/#compatibility-changes>, and check
   the app against each one. That list is a starting point, not the whole surface: look for
   anything else the app depends on. Pay attention to the libraries aliased in
   `config/helpers/context_aliases_shared.js`, because they run through a Vue 3 shim, and give the
   ones this app imports their own checklist entries.

1. Build an explicit checklist of interactions from that reading, and share it with me before you
   run anything, so I can correct it. Group it into:
   - Main features: the app's primary user flows.
   - Event and emit paths: each emitted event and the observable result its listener produces.
   - Edge cases: empty state, error state, loading state, permission-restricted state, long or
     truncated content, and keyboard-only interaction.

1. Sign in at `<GDK URL>/users/sign_in` with the credentials above, as your first browser action
   in every session. The GitLab session cookie does not survive a browser restart, so each
   recorded session signs in again. The sign-in form is itself a Vue app, so read a fresh
   `browser_snapshot` before each field: typing into one field re-renders the form and stales the
   reference to the other.

1. Confirm the page runs under Vue 3 before you verify anything. The pin keeps every
   `[gitlab] [V] Using Vue.js 3` line on screen for the whole recording, one per app root that
   started, so the video states which engine ran. Read that pinned block from `browser_snapshot`.
   If your app is missing from it, stop and report it. A walkthrough on Vue 2 proves nothing about
   the migration.

1. Run the checklist twice, in two separate recorded sessions: once with the feature flag off
   (Vue 2 baseline) and once with it on (Vue 3). A step that fails in both is an existing bug, not
   a migration regression.

1. For every interaction, assert an observable result, not just that the click happened. Examples:
   text that appears or changes, a row count, a URL query parameter, a request in
   `browser_network_requests`, an element that appears or disappears in `browser_snapshot`. If the
   handler for an event produces nothing observable on the page, call it out as unverifiable from
   the browser. Do not report it as passing.

1. Read the overlay after each step. Treat any error or `@vue/compat` warning that appears in the
   Vue 3 pass but not in the Vue 2 pass as a migration regression. `browser_console_messages` holds
   the full log for your report, including the messages the panel clipped.

1. Call `browser_video_save` with an `.mp4` filename as your last call in each session. It closes
   the browser to finalize the video, so no browser tool works after it. Then report the checklist
   with a pass or fail for each item, the console difference between the two passes, anything you
   could not verify from the browser, and the video path for each session. If `glab` is installed,
   upload the videos and attach them to the merge request.
````

</details>

#### Caveats

- A video shows that the interactions the agent performed work at that commit. It is not a test:
  nothing replays it against later changes. Keep covering fixed behavior with Jest specs.
- Recordings have no audio, so `--video-speed 1.5` shortens the clip without losing detail.

## Common migration issues

### Vue Router props reactivity

Router props passed with the `props` function are not reactive in Vue 3. Use computed properties
that read from `this.$route` instead.

```javascript
// Component - use computed property instead of props
computed: {
  currentPath() {
    return this.$route?.params.path || '';
  }
}
```

### Watch expressions

Watch specific route properties using string paths, not the entire `$route` object. You can still
use `deep: true` with `$route`, but it adds performance overhead. Watching specific properties is
more efficient and explicit about your component's dependencies.

```javascript
watch: {
  '$route.params.path'() {
    this.fetchData();
  }
}
```

## Testing

For more information about implementing or fixing tests that fail while using Vue 3, read the
[Vue 3 testing guide](../testing_guide/testing_vue3.md).

## Updating `@vue/compat` patches

See [this document](https://gitlab.com/gitlab-org/frontend/vuejs-core/-/blob/v3.5.30-gitlab-hybrid/README.md) for information about how to update our `@vue/compat` patches, as it can be tricky.
