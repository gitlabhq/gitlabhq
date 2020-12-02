---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Icons and SVG Illustrations

We manage our own icon and illustration library in the [`gitlab-svgs`](https://gitlab.com/gitlab-org/gitlab-svgs)
repository. This repository is published on [npm](https://www.npmjs.com/package/@gitlab/svgs),
and is managed as a dependency with yarn. You can browse all available
[icons and illustrations](https://gitlab-org.gitlab.io/gitlab-svgs). To upgrade
to a new version run `yarn upgrade @gitlab/svgs`.

## Icons

We are using SVG Icons in GitLab with a SVG Sprite.
This means the icons are only loaded once, and are referenced through an ID.
The sprite SVG is located under `/assets/icons.svg`.

Our goal is to replace one by one all inline SVG Icons (as those currently bloat the HTML) and also all Font Awesome icons.

### Usage in HAML/Rails

To use a sprite Icon in HAML or Rails we use a specific helper function:

```ruby
sprite_icon(icon_name, size: nil, css_class: '')
```

- **icon_name**: Use the icon_name for the SVG sprite in the list of
  ([GitLab SVGs](https://gitlab-org.gitlab.io/gitlab-svgs)).
- **size (optional)**: Use one of the following sizes : 16, 24, 32, 48, 72 (this
  will be translated into a `s16` class)
- **css_class (optional)**: If you want to add additional CSS classes.

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

**Please note:** The `icon(icon_name, options: {})` helper function is deprecated and should not be used anymore.

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

Please use the following function inside JS to render an icon:
`gl.utils.spriteIcon(iconName)`

## Loading icon

### Usage in HAML/Rails

DANGER: **Warning:**
Do not use the `spinner` or `icon('spinner spin')` rails helpers to insert
loading icons. These helpers rely on the Font Awesome icon library which is
deprecated.

To insert a loading spinner in HAML or Rails use the `loading_icon` helper:

```haml
= loading_icon
```

You can include one or more of the following properties with the `loading_icon` helper, as demonstrated
by the examples that follow:

- `container` (optional): wraps the loading icon in a container, which centers the loading icon using the `text-center` CSS property.
- `color` (optional): either `orange` (default), `light`, or `dark`.
- `size` (optional): either `sm` (default), `md`, `lg`, or `xl`.
- `css_class` (optional): defaults to an empty string, but can be useful for utility classes to fine-tune alignment or spacing.

**Example 1:**

The following HAML expression generates a loading icon’s markup and
centers the icon by wrapping it in a `gl-spinner-container` element.

```haml
= loading_icon(container: true)
```

**Output from example 1:**

```html
<div class="gl-spinner-container">
  <span class="gl-spinner gl-spinner-orange gl-spinner-sm" aria-label="Loading"></span>
</div>
```

**Example 2:**

The following HAML expression generates a loading icon’s markup
with a custom size. It also appends a margin utility class.

```haml
= loading_icon(size: 'lg', css_class: 'gl-mr-2')
```

**Output from example 2:**

```html
<span class="gl-spinner gl-spinner-orange gl-spinner-lg gl-mr-2" aria-label="Loading"></span>
```

### Usage in Vue

The [GitLab UI](https://gitlab-org.gitlab.io/gitlab-ui/) components library provides a
`GlLoadingIcon` component. See the component’s
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

Please use from now on for any SVG based illustrations simple `img` tags to show an illustration by simply using either `image_tag` or `image_path` helpers.
Please use the class `svg-content` around it to ensure nice rendering.

### Usage in HAML/Rails

**Example**

```haml
.svg-content
  = image_tag 'illustrations/merge_requests.svg'
```

### Usage in Vue

To use an SVG illustrations in a template provide the path as a property and display it through a standard `img` tag.

Component:

```html
<script>
export default {
  props: {
    svgIllustrationPath: {
      type: String,
      required: true,
    },
  },
};
<script>

<template>
  <img :src="svgIllustrationPath" />
</template>
```
