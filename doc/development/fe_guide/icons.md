# Icons and SVG Illustrations

We manage our own Icon and Illustration library in the [`gitlab-svgs`](https://gitlab.com/gitlab-org/gitlab-svgs) repository.
This repository is published on [npm](https://www.npmjs.com/package/@gitlab/svgs) and managed as a dependency via yarn.
You can browse all available Icons and Illustrations [here](https://gitlab-org.gitlab.io/gitlab-svgs).
To upgrade to a new version run `yarn upgrade @gitlab/svgs`.

## Icons

We are using SVG Icons in GitLab with a SVG Sprite.
This means the icons are only loaded once, and are referenced through an ID.
The sprite SVG is located under `/assets/icons.svg`.

Our goal is to replace one by one all inline SVG Icons (as those currently bloat the HTML) and also all Font Awesome icons.

### Usage in HAML/Rails

To use a sprite Icon in HAML or Rails we use a specific helper function :

```ruby
sprite_icon(icon_name, size: nil, css_class: '')
```

- **icon_name** Use the icon_name that you can find in the SVG Sprite
  ([Overview is available here](https://gitlab-org.gitlab.io/gitlab-svgs)).
- **size (optional)** Use one of the following sizes : 16, 24, 32, 48, 72 (this will be translated into a `s16` class)
- **css_class (optional)** If you want to add additional CSS classes

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
  />
</template>
```

- **name** Name of the Icon in the SVG Sprite ([Overview is available here](https://gitlab-org.gitlab.io/gitlab-svgs)).
- **size (optional)** Number value for the size which is then mapped to a specific CSS class
  (Available Sizes: 8, 12, 16, 18, 24, 32, 48, 72 are mapped to `sXX` CSS classes)
- **css-classes (optional)** Additional CSS Classes to add to the SVG tag.

### Usage in HTML/JS

Please use the following function inside JS to render an icon:
`gl.utils.spriteIcon(iconName)`

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
