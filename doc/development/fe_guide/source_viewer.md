---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Source viewer layout development guidelines (repository blob viewer)
---

The source viewer at `app/assets/javascripts/vue_shared/components/source_viewer/` renders
repository files in chunks of 70 lines using CSS Grid to keep the blame gutter, line numbers,
and code aligned without JavaScript measurement. For chunking, staged rendering, and syntax
highlighting, see [Syntax highlighting development guidelines](blob_syntax_highlighting.md).

## Three-column grid

`source_viewer.vue` declares the top-level grid on the `.file-content` container through the
`blameGridStyling` computed property:

```plaintext
grid-template-columns: <blameWidth> auto 1fr
```

The three columns are:

| Column | Track size | Contents |
|--------|-----------|----------|
| 1 | Fixed pixel value | Blame gutter |
| 2 | `auto` | Line numbers |
| 3 | `1fr` | Code |

**Column 1 (blame gutter)** is a user-resizable fixed-pixel track. `BlameColumnResizer`, an
absolutely positioned handle anchored outside the scroll container, drives the width value
through `v-model`, and `blameGridStyling` turns that value into the track size.
When blame is hidden, the width is set to `'0'`, so the column always exists in the grid but
takes no space. Width changes update one inline style and the `--blame-column-width`
custom property. Chunks re-position through CSS without any Vue re-render.

**Column 2 (line numbers)** uses `auto`, which sizes the track to fit its content. The column
becomes as wide as the widest line number requires, subject to the 6rem `min-width` floor that
`.line-numbers` sets in `highlight.scss`.

**Column 3 (code)** uses `1fr`, which is `minmax(auto, 1fr)`. The `auto` minimum resolves to the
`min-content` of `white-space: pre` text, which is the widest line in the file. Because all chunks
share this one track, the widest line in any chunk sets the width for every chunk. A selected line
therefore spans the full content width regardless of which chunk it falls in.

## Subgrid

Each chunk root spans all three columns and inherits the parent's column tracks:

```html
<div class="gl-col-span-3 gl-grid gl-grid-cols-subgrid" :style="chunkGridStyling">
```

`gl-grid-cols-subgrid` applies `grid-template-columns: subgrid`. This is what keeps the blame
gutter, line numbers, and code aligned across all chunk components without any shared measurement.
CSS subgrid is Baseline Widely Available and supported by every browser that GitLab supports.

## Explicit rows

Each chunk declares one grid row per source line:

```javascript
// chunk.vue: chunkGridStyling computed property
{ gridTemplateRows: `repeat(${this.totalLines}, var(--source-line-height))` }
```

The rows must be explicit. Full-height layers use `gl-row-span-full`, which compiles to
`grid-row: 1 / -1`. The `-1` line index resolves against the explicit grid only. With only
implicit rows, those layers collapse to a single line height.

## Blame placement as data

A blame cell sets its grid position from `rowStart` and `rowSpan` values produced by pure
functions (`normalizeBlameGroups` and `blameGroupsForChunk` in `utils.js`):

```javascript
// chunk.vue: blameCellStyling method
{
  gridRowStart: group.rowStart,
  gridRowEnd: group.rowStart + group.rowSpan,
}
```

Blame position is derived entirely from this data, so blame data arriving for one chunk cannot
affect the layout of another.

## Full-height layers

The following items each span the entire chunk height with `gl-row-span-full`. Each is a single
grid item, not one element per line.

| Layer | Column | Purpose |
|-------|--------|---------|
| Gutter background panel | 1 | Backs blame cells, covers lines whose blame has not loaded yet, hides code scrolling underneath |
| Blame skeleton loader | 1 | Shown while a chunk's blame request is in flight and no groups have arrived |
| Line-number placeholder | 2 | Holds the line-number column open before the chunk is highlighted |
| Code area (`GlIntersectionObserver` + `<pre>`) | 3 | The whole chunk's code rendered as one item |

## Stacking layers

Multiple grid items occupy the same cells and stack by z-index. The scroll container sets
`gl-isolate` (`isolation: isolate`) to scope this z-index scale so it cannot tie with page chrome
such as the sticky file header.

| z-index | Layer |
|---------|-------|
| `gl-z-1` | Raw code layer (the raw `<code>` element inside the `<pre>`) |
| `gl-z-2` | Blame gutter: background panel, skeleton loader, blame cells |
| `gl-z-3` | Line numbers, blame column resize handle |
| `gl-z-4` | Blame group separator borders |

The `gl-z-1` tier is half of a two-layer code stack inside the `<pre>`. The raw `<code>` element
renders the plain text with `gl-text-transparent` and sits above the highlighted `<code>`
overlay, which is absolutely positioned and `inert`. The raw layer owns text selection and
pointer events, and forwards mouse events to the highlighted spans at the same coordinates, so
hover-driven features such as code navigation still work. Keeping the raw text in the DOM also
keeps native browser find working before a chunk is highlighted.

Within the same z-index tier, DOM order controls paint order. Distinct z-index values are
reserved for items in different parts of the component tree where DOM order alone cannot express
the required stacking.

## Horizontal scrolling

The blame gutter layer (background panel, skeleton, blame cells) is `position: sticky` at
`left: 0`. Line numbers are sticky at `left: var(--blame-column-width)`. Code in column 3 scrolls
underneath both. The opaque gutter background is what hides the scrolling code below the sticky
columns.

Sticky positioning composes with grid placement: the grid decides where an item lives in the
track layout, and sticky controls how the item behaves during scroll.

## Group separators

Each boundary between blame groups renders as two elements, not one. The gutter half covers
column 1 and uses the default border token (`gl-border-t`), and the code half covers columns 2
and 3 and uses `gl-border-t-gray-500`. The split is necessary because the gutter follows the page
UI theme while the code area follows the user's syntax highlighting theme, so no single border
color reads correctly across both.

Both halves sit at `gl-z-4` so they paint over the blame cells and code they border. The two
halves occupy different columns and never overlap each other.

## Pitfalls

### Do not wrap the chunk list in an intermediate element

`grid-template-columns: subgrid` inherits tracks only from a direct grid parent. Any wrapper
between `.file-content` and the `<chunk>` components silently breaks alignment: the subgrid
falls back to `none` and every chunk builds its own independent column tracks.

### Keep chunk rows explicit

`grid-row: 1 / -1` resolves `-1` against the explicit grid only. Removing or replacing
`chunkGridStyling`'s `grid-template-rows` collapses every full-height layer
(`gl-row-span-full`) to a single row, and any new full-height layer needs explicit rows on the
chunk to work correctly.

### Preserve DOM order within the gutter tier

The gutter background panel must come before the blame cells in the template. Both are `gl-z-2`,
so DOM order is the only paint-order control at that tier.
