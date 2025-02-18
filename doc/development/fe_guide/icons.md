---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Icons and SVG Illustrations
---

We manage our own icon and illustration library in the [`gitlab-svgs`](https://gitlab.com/gitlab-org/gitlab-svgs)
repository. This repository is published on [npm](https://www.npmjs.com/package/@gitlab/svgs),
and is managed as a dependency with yarn. You can browse all available
[icons and illustrations](https://gitlab-org.gitlab.io/gitlab-svgs). To upgrade
to a new version run `yarn upgrade @gitlab/svgs`.

## Icons

We are using SVG Icons in GitLab with a SVG Sprite.
This means the icons are only loaded once, and are referenced through an ID.
The sprite SVG is located under `/assets/icons.svg`.

### Usage in HAML/Rails

To use a sprite Icon in HAML or Rails we use a specific helper function:

```ruby
sprite_icon(icon_name, size: nil, css_class: '')
```

- **`icon_name`**: Use the `icon_name` for the SVG sprite in the list of
  ([GitLab SVGs](https://gitlab-org.gitlab.io/gitlab-svgs)).
- **`size` (optional)**: Use one of the following sizes : 16, 24, 32, 48, 72 (this
  is translated into a `s16` class)
- **`css_class` (optional)**: If you want to add additional CSS classes.

**Example**

```haml
= sprite_icon('issues', size: 72, css_class: 'icon-danger')
```

**Output from example above**

```html
<svg class="s72 icon-danger">
  <use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons.svg#issues"></use>
</svg>
```

### Usage in Vue

[GitLab UI](https://gitlab-org.gitlab.io/gitlab-ui/), our components library, provides a component to display sprite icons.

Sample usage :

```html
<script>
import { GlIcon } from "@gitlab/ui";

export default {
  components: {
    GlIcon,
  },
};
<script>

<template>
  <gl-icon
    name="issues"
    :size="24"
    class="class-name"
  />
</template>
```

- **name**: Name of the icon of the SVG sprite, as listed in the
  ([GitLab SVG Previewer](https://gitlab-org.gitlab.io/gitlab-svgs)).
- **size: (optional)** Number value for the size which is then mapped to a
  specific CSS class (Available sizes: 8, 12, 16, 18, 24, 32, 48, 72 are mapped
  to `sXX` CSS classes)
- **class (optional)**: Additional CSS classes to add to the SVG tag.

### Usage in HTML/JS

Use the following function inside JS to render an icon:
`gl.utils.spriteIcon(iconName)`

## Loading icon

### Usage in HAML/Rails

To insert a loading spinner in HAML or Rails use the `gl_loading_icon` helper:

```haml
= gl_loading_icon
```

You can include one or more of the following properties with the `gl_loading_icon` helper, as demonstrated
by the examples that follow:

- `inline` (optional): uses in an inline element if `true`, otherwise, a block element (default), with the spinner centered.
- `color` (optional): either `dark` (default) or `light`.
- `size` (optional): either `sm` (default), `md`, `lg`, or `xl`.
- `css_class` (optional): defaults to nothing, but can be used for utility classes to fine-tune alignment or spacing.

**Example 1:**

The following HAML expression generates a loading icon's markup and
centers the icon.

```haml
= gl_loading_icon
```

**Example 2:**

The following HAML expression generates an inline loading icon's markup
with a custom size. It also appends a margin utility class.

```haml
= gl_loading_icon(inline: true, size: 'lg', css_class: 'gl-mr-2')
```

### Usage in Vue

The [GitLab UI](https://gitlab-org.gitlab.io/gitlab-ui/) components library provides a
`GlLoadingIcon` component. See the component's
[storybook](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-loading-icon--default)
for more information about its usage.

**Example:**

The following code snippet demonstrates how to use `GlLoadingIcon` in
a Vue component.

```html
<script>
import { GlLoadingIcon } from "@gitlab/ui";

export default {
  components: {
    GlLoadingIcon,
  },
};
<script>

<template>
  <gl-loading-icon inline />
</template>
```

## SVG Illustrations

From now on, use `img` tags to display any SVG based illustrations with either `image_tag` or `image_path` helpers.
Using the class `svg-content` around it ensures nice rendering.

### Usage in HAML/Rails

**Example**

```haml
.svg-content
  = image_tag 'illustrations/merge_requests.svg'
```

### Usage in Vue

It is discouraged to pass down SVG paths from Rails. Instead of `Rails => Haml => Vue` we can import SVG illustrations directly in `Vue`.

To use an SVG illustration in a template import the SVG from `@gitlab/svgs`. You can find the available SVG paths via the [GitLab SVG Previewer](https://gitlab-org.gitlab.io/gitlab-svgs/illustrations).

Below is an example of how to import an SVG illustration and use with the `GlEmptyState` component.

Component:

```html
<script>
import { GlEmptyState } from '@gitlab/ui';
// The ?url query string ensures the SVG is imported as an URL instead of an inilne SVG
// This is useful for bundle size and optimized loading
import mergeTrainsSvgPath from '@gitlab/svgs/dist/illustrations/train-sm.svg?url';

export default {
  components: {
    GlEmptyState
  },
  mergeTrainsSvgPath,
};
<script>

<template>
  <gl-empty-state
    title="This state is empty"
    description="Empty state description"
    :svg-path="$options.mergeTrainsSvgPath"
  />
</template>
```

### Minimize SVGs

When you develop or export a new SVG illustration, minimize it with an [SVGO](https://github.com/svg/svgo) powered tool, like
[SVGOMG](https://jakearchibald.github.io/svgomg/), to save space. Illustrations
added to [GitLab SVG](https://gitlab.com/gitlab-org/gitlab-svgs) are automatically
minimized, so no manual action is needed.
