---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: App initialization development guidelines (repository and blob pages)
---

The repository (tree) page and the blob page mount the same shared Vue apps,
but different entry points bootstrap them depending on how the user reaches the page.
The following sections describe which apps mount in each flow and what each entry
point must initialize.

In this page, `~/` is an alias for `app/assets/javascripts`, and the words "tree" and
"repository" are used interchangeably.

## Summary

The tree page bundle initializes the apps when a user navigates to a blob from the
repository page. The blob page bundle initializes the apps when a user loads a blob
URL directly, for example when refreshing the page. The first flow is faster because
only the content area is swapped out.

Both flows call the same [shared bootstrap](#shared-bootstrap),
`initRepositoryPage()`, so they create the same Vue Router and mount the same
shared repository app (`~/repository/components/app.vue`), and tree and blob
navigation is client-side in both directions. The difference between the two flows
is which page bundle calls the bootstrap, and which HAML provides the mount points.

As a result, each entry point must initialize the apps with the correct data for all
of these flows:

- Tree page, then client-side navigation to a blob.
- Direct blob page access.
- Project overview page, then client-side navigation to a blob.

## Router

In `~/repository/router.js`, the route path determines the rendered Vue component:

- `TreePage`: `~/repository/pages/tree.vue`
- `BlobPage`: `~/repository/pages/blob.vue`
- `IndexPage`: `~/repository/pages/index.vue`

Each tree and blob route is registered multiple times (`*PathDecoded`,
`*PathEncoded`, `*PathEncodedSlashes`, and plain) so refs with special characters
(`#`, `%`, and others) resolve regardless of how the backend encoded them.

## Shared bootstrap

`initRepositoryPage()` (`~/repository/init_repository_page.js`) wires up everything
both pages share. In order:

- Picks the main mount point: `#js-tree-list` (tree page) or `#js-view-blob-app`
  (blob page), and returns `null` when neither exists.
- `createRouter(projectPath, escapedRef, fullName)`. The router base must use the
  pre-encoded ref: the route patterns embed encoded variants of it, so a raw ref
  containing `#` or `%` would double-encode.
- Apollo cache writes for the `projectPath`, `projectShortPath`, and `ref` queries.
  These happen before any app mounts because the apps read them from the cache. On
  blob pages, the short path comes from the header mount point's dataset until the
  consolidated helper from
  [work item 630950](https://gitlab.com/gitlab-org/gitlab/-/work_items/630950) lands.
- `initFileTreeBrowser` (`#js-file-browser`): `~/repository/file_tree_browser/`.
- `initHeaderApp` (`#js-repository-blob-header-app`):
  `~/repository/init_header_app.js`. The header area app also renders the
  breadcrumbs and the Web IDE button.
- `initLastCommitApp` (`#js-last-commit`): `~/repository/init_last_commit_app.js`.
- `initForkInfoApp` (`#js-fork-info`): `~/repository/init_fork_info_app.js`.
- The main repository app (`~/repository/components/app.vue`) on the mount point
  from the first step.

It returns `{ router, apolloProvider, projectPath }` so the EE wrappers can mount
the code owners app against the same router and Apollo provider instead of
creating duplicates.

## File tree browser

Both the tree page load and the direct blob page load mount the file tree browser
with `initFileTreeBrowser` (`~/repository/file_tree_browser/index.js`):

- Both HAML entry points render the mount point `#js-file-browser` with a
  pre-reserved width of 320 pixels to prevent layout shift. The width must match
  `TREE_WIDTH` in `file_tree_browser.vue`.
- The file tree browser shares the router instance with the repository app, so
  selecting a file in it is a client-side navigation. Tree to blob and blob to blob
  navigation happen without a full page load.
- The file tree browser renders on tree and blob routes, but hides itself on the
  project root route (`projectRoot`).
- A Pinia store keeps the expanded, peek, and visible state, so the state persists
  across route changes.

## Tree page load

HAML partials:

- `app/views/projects/tree/show.html.haml` renders `app/views/projects/_files.html.haml`,
  which renders `app/views/projects/_tree_content.html.haml`. These provide
  `#js-tree-list`, `#js-last-commit`, and the other mount points.

Initialization:

- `~/pages/projects/tree/show/index.js` imports `ee_else_ce/repository` and calls
  `initTree()`, `initAmbiguousRefModal()` (`#js-ambiguous-ref-modal`), and
  `addShortcutsExtension(ShortcutsNavigation)`.
  - CE: `~/repository/index.js` (`setupVueRepositoryList`) registers the
    `SimpleViewer` and `BlobContent` performance plugin components and delegates to
    the [shared bootstrap](#shared-bootstrap), which mounts everything on this page.
  - EE: `ee/app/assets/javascripts/repository/index.js` wraps the CE init and
    additionally mounts the code owners app (`#js-code-owners`) with the router and
    Apollo provider that `setupVueRepositoryList` returns.

Vue apps on the page:

- `~/repository/components/header_area.vue`
- `~/repository/components/last_commit.vue`
- `~/repository/components/app.vue`, which renders `~/repository/pages/tree.vue` and
  `~/repository/components/tree_content.vue`
- `~/repository/file_tree_browser/file_tree_browser.vue`
- `~/repository/components/fork_info.vue`
- `~/vue_shared/components/ref/components/ambiguous_ref_modal.vue`
- `ee/app/assets/javascripts/vue_shared/components/code_owners/code_owners.vue` (EE only)

## Tree to blob navigation (client-side)

No apps are re-initialized when a user navigates from the tree page to a blob.
The router swaps `TreePage` for `BlobPage` inside the already-mounted repository app
(`app.vue` renders `<router-view>`), and the other apps (header area, last commit,
and file tree browser) react to the route change on their own.
The fast path swaps out only the content area. Everything else stays mounted.

One consequence: a blob reached through client-side navigation never runs
`show_blob_bundle.js`, so anything set up only by that bundle (for example,
`initAuxiliaryViewer` and the legacy `initBlob` behaviors) is not initialized
in this flow. Equivalent
functionality has to either live inside the shared Vue apps (for example,
`last_commit.vue` fetches the pipeline status itself through GraphQL) or be mounted
by both entry points (for example, code owners).

## Direct blob page access

A direct blob page access happens when a user loads or refreshes a blob URL.

HAML partials:

- `app/views/projects/blob/show.html.haml` renders
  `app/views/projects/blob/_blob.html.haml`, which provides `#js-view-blob-app`.

Initialization:

- `~/pages/projects/blob/show/index.js` is a thin shim. The logic lives in
  `~/blob/show/show_blob_bundle.js` (`initBlobShow`).
- The EE page entry calls `initEEBlobShow`
  (`ee/app/assets/javascripts/blob/show/blob_show_bundle.js`), which calls
  `initBlobShow` and additionally mounts the code owners app (`#js-code-owners`).
- `initBlobShow` always runs `initPerformancePlugin`, `initAmbiguousRefModal`
  (`#js-ambiguous-ref-modal`), and `showAlertFromLocalStorage`.
- When `#js-view-blob-app` exists: the [shared bootstrap](#shared-bootstrap),
  which mounts everything including the repository app rendering `BlobPage`,
  followed by `initAuxiliaryViewer` and `initBlob` (legacy blob behaviors: line
  links, blame shortcuts, and others).
- Fallback when `#js-view-blob-app` does not exist, which happens on the expanded
  blob view (`?expanded=true`): `new BlobViewer()`, `initBlob()`, and `initForkInfoApp`
  (`#js-fork-info`). The dynamic `~/code_navigation` import also runs only in this
  fallback, and only when `#js-code-navigation` exists.
- In both cases the bundle calls `initWebIdeLink` (`#js-blob-web-ide-link`) and
  `initTableOfContentsApp` (`.js-table-contents`), but both mount points come from
  the blob header HAML (`app/views/projects/blob/_header.html.haml`), which
  `_blob.html.haml` renders only in the expanded view. On the Vue blob page both
  calls return early: the header area app renders the Web IDE button, and
  `blob_header.vue` renders the table of contents for rich viewers.

Vue apps on the page:

- `~/repository/components/header_area.vue`
- `~/repository/components/last_commit.vue`
- `~/repository/components/app.vue`, which renders `~/repository/pages/blob.vue` and
  `~/repository/components/blob_content_viewer.vue`
- `~/repository/file_tree_browser/file_tree_browser.vue`
- `~/repository/components/fork_info.vue`
- `~/vue_shared/components/ref/components/ambiguous_ref_modal.vue`
- `ee/app/assets/javascripts/vue_shared/components/code_owners/code_owners.vue` (EE only)

## Blob to tree navigation (client-side)

Blob to tree navigation is also client-side: the router swaps `BlobPage` for
`TreePage` inside the already-mounted repository app. Because nothing tears the
page down, anything set up only by `show_blob_bundle.js` on the direct blob load
(`initAuxiliaryViewer` and the legacy `initBlob` behaviors) stays in place after
the user leaves the blob route.

## Project overview page

The project overview page uses different HAML partials depending on the user's
project overview setting (**Preferences** > **Behavior** > **Project overview content**) and
on whether the repository is empty. `~/pages/projects/show/index.js` conditionally
initializes apps with dynamic imports:

- `#js-tree-list` present: dynamic import of `ee_else_ce/repository`, the same tree
  initialization as above.
- `.blob-viewer` present (README): dynamic import of `~/blob/viewer`
  (`new BlobViewer()`) and `initHeaderApp({ isReadmeView: true })`.
- `.project-show-activity` present: dynamic import of `~/activities`.

Regardless of the overview content, `initWebIdeLink` (`#js-tree-web-ide-link`)
always runs.

Related partials:

- `app/views/projects/_readme.html.haml`
- `app/views/projects/_activity.html.haml`

For an empty repository, `initCodeDropdown`
(`#js-project-show-empty-page #js-code-dropdown`) also lives in
`~/pages/projects/show/index.js` and mounts
`ee_else_ce/repository/components/code_dropdown/compact_code_dropdown.vue`.
The mount point comes from `app/views/projects/buttons/_code.html.haml`, rendered by
`app/views/projects/empty.html.haml`.

## Related reading

- [Merge request 58053](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58053)
- [Issue 323200](https://gitlab.com/gitlab-org/gitlab/-/issues/323200)
