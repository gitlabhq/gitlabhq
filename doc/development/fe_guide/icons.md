# Icons

We are using SVG Icons in GitLab with a SVG Sprite, due to this the icons are only loaded once and then referenced through an ID. The sprite SVG is located under `/assets/icons.svg`. Our goal is to replace one by one all inline SVG Icons (as those currently bloat the HTML) and also all Font Awesome usages.

### Usage in HAML/Rails

To use a sprite Icon in HAML or Rails we use a specific helper function : 

`sprite_icon(icon_name, size: nil, css_class: '')`

**icon_name** Use the icon_name that you can find in the SVG Sprite (Overview is available under `/assets/sprite.symbol.html`).
**size (optional)** Use one of the following sizes : 16,24,32,48,72 (this will be translated into a `s16` class)
**css_class (optional)** If you want to add additional css classes

**Example** 

`= sprite_icon('issues', size: 72, css_class: 'icon-danger')`

**Output from example above**

`<svg class="s72 icon-danger"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons.svg#issues"></use></svg>`

### Usage in HTML/JS

Please use the following function inside JS to render an icon : 
`gl.utils.spriteIcon(iconName)`

## Adding a new icon to the sprite

All Icons and Illustrations are managed in the [gitlab-svgs](https://gitlab.com/gitlab-org/gitlab-svgs) repository which is added as a dev-dependency.

To upgrade to a new SVG Sprite version run `yarn upgrade https://gitlab.com/gitlab-org/gitlab-svgs` and then run `yarn run svg`. This task will copy the svg sprite and all illustrations in the correct folders.

# SVG Illustrations

Please use from now on for any SVG based illustrations simple `img` tags to show an illustration by simply using either `image_tag` or `image_path` helpers. Please use the class `svg-content` around it to ensure nice rendering. The illustrations are also organised in the [gitlab-svgs](https://gitlab.com/gitlab-org/gitlab-svgs) repository (as they are then automatically optimised).

**Example**

`= image_tag 'illustrations/merge_requests.svg'`
