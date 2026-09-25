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

The grid lives inside two nested containers with similar names. The outer isolation wrapper,
referenced in the template as `fileContent`, scopes the z-index scale and anchors the blame column
resize handle. The inner `.file-content` grid declares the three-column grid and is the element
that scrolls horizontally. The `fileContent` ref does not point at the `.file-content` element.

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

**Column 1 (blame gutter)** is a user-resizable fixed-pixel track. `BlameColumnResizer` is an
absolutely positioned handle anchored to the isolation wrapper rather than the scrolling grid, so
it stays aligned with the gutter edge during horizontal scroll. The handle drives the width value
through `v-model`, and `blameGridStyling` turns that value into the track size and publishes it as
the `--blame-column-width` custom property. When blame is hidden, the width is set to `'0'`, so the
column always exists in the grid but takes no space. A width change re-renders `source_viewer`, but
the chunk components' props do not change, so they skip re-rendering and reposition through CSS
alone.

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

## Explicit rows

Each chunk declares one grid row per source line:

```javascript
// chunk.vue: chunkGridStyling computed property
{ gridTemplateRows: `repeat(${this.totalLines}, var(--source-line-height))` }
```

The rows must be explicit. Full-height layers use `gl-row-span-full`, which compiles to
`grid-row: 1 / -1`. The `-1` line index resolves against the explicit grid only. With only
implicit rows, those layers collapse to a single line height.

`chunk.vue` builds those explicit rows from `--source-line-height`, a custom property defined on
`.blob-viewer` in `app/assets/stylesheets/framework/highlight.scss`. Its `chunkGridStyling`
computed repeats that value into `gridTemplateRows`, and its `rawCodeStyling` computed derives the
raw code layer's `min-height` from the same token, so a change to the row height has to account
for both.

## Blame placement as data

A blame cell sets its grid position from `rowStart` and `rowSpan` values, produced per chunk by a
blame slice builder (`createBlameSliceBuilder` in `utils.js`) that `source_viewer.vue` creates
once and feeds from `normalizeBlameGroups`. A cell then reads the values straight into its grid
placement:

```javascript
// chunk.vue: blameCellStyling method
{
  gridRowStart: group.rowStart,
  gridRowEnd: group.rowStart + group.rowSpan,
  // ...
}
```

Blame position is derived entirely from this data, so blame data arriving for one chunk cannot
affect the layout of another. `createBlameSliceBuilder` also caches each chunk's previous slice and
returns that same array reference when the new slice is equivalent, instead of the freshly computed
one. That reference stability keeps the `blameGroups` prop identity unchanged for chunks whose
blame did not move, so only the chunks whose blame actually changed re-render.

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

Multiple grid items occupy the same cells and stack by z-index. The isolation wrapper sets
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

A boundary renders a separator only when its blame group has `hasSeparator` set. `hasSeparator` is
false for a group that continues from the previous chunk and for the group starting on line 1
(see `blameGroupsForChunk` in `utils.js`; `blameSeparatorRows` in `chunk.vue` reads the flag).

Each boundary between blame groups renders as two elements, not one. The gutter half covers
column 1 and uses the default border token (`gl-border-t`), and the code half covers columns 2
and 3 and uses `gl-border-t-gray-500`. The split is necessary because the gutter follows the page
UI theme while the code area follows the user's syntax highlighting theme, so no single border
color reads correctly across both.

Both halves sit at `gl-z-4` so they paint over the blame cells and code they border. The code
half is not sticky, so it slides underneath the gutter column during horizontal scroll, and the
two halves do overlap there. The template renders the code half first and the sticky gutter half
second, so the gutter half covers the code half where they meet.

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

### Preserve DOM order within each z-index tier

Two tiers rely on DOM order alone for correct paint order, because elements in each tier share
the same z-index. In the `gl-z-2` gutter tier, the gutter background panel must come before the
blame cells. In the `gl-z-4` separator tier, the code half of a group separator must come before
the gutter half (see [Group separators](#group-separators)). Reordering either pair breaks its
layer without changing any z-index value.

### Treat cached blame slices as immutable

Never mutate a blame group or the array the slice builder returns. Vue doesn't track those objects,
so a mutation doesn't re-render the cell. The next rebuild keeps the cached slice whenever the
compared fields match, so a change to any other field can persist indefinitely.

The equivalence check itself, `isSameBlameSlice`, compares only `rowStart`, `rowSpan`,
`hasSeparator`, and `commit?.sha`. If you add a field that changes how a blame cell renders, such
as something derived from the group's original `lineno` rather than its clamped `rowStart`, extend
that comparison too, or the cell keeps its stale rendering after the underlying data changes.
