---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Create a new page
---

This guide explains how to add a new page to GitLab, covering a Rails route,
controller action, HAML view, page-specific JavaScript, and page-specific CSS.

## Create a new page

GitLab is a [Ruby on Rails](https://rubyonrails.org/) application. To add a new page,
you need a route, a controller action, and a HAML view.

1. Add a route in `config/routes/` or the relevant routes file. For more information,
   see the [Rails routing guide](https://guides.rubyonrails.org/routing.html).
1. Add a controller action in the appropriate controller under `app/controllers/`.
   For more information, see the
   [Rails controllers guide](https://guides.rubyonrails.org/action_controller_overview.html).
1. Add a HAML view at `app/views/<controller_path>/<action>.html.haml`.
   For more information, see the [HAML documentation](haml.md).

For example, to create a page accessible at `/-/projects/:id/pages/new`:

- Route: defined in `config/routes/project.rb`.
- Controller: `app/controllers/projects/pages_controller.rb` with a `def new` action.
- View: `app/views/projects/pages/new.html.haml`.

## Add page-specific JavaScript

GitLab automatically loads JavaScript entrypoints based on the Rails controller path
and action name.

### Entrypoint loading

The bundler (Webpack or Vite) looks for entrypoint files in
`app/assets/javascripts/pages/` using a cascading convention. For a controller action like
`projects/pages/new`, it loads the following files in order, if they exist:

1. `pages/projects/index.js`
1. `pages/projects/pages/index.js`
1. `pages/projects/pages/new/index.js`

Each file in the hierarchy is loaded, so code in parent entrypoints runs on all child
routes. Use this to share initialization logic across related pages.

> [!note]
> To find the controller path for any page in GitLab, inspect `document.body.dataset.page`
> in your browser's developer console. The value uses `:` as a separator, for example
> `projects:pages:new`.

To add JavaScript for a new page:

1. Create the directory matching the controller path under `app/assets/javascripts/pages/`.
1. Add an `index.js` file in that directory.
1. Keep the entrypoint file lightweight. Import and call functions defined in modules
   outside the entrypoint. Do not add business logic directly to the entrypoint.

For example, for the `projects/pages/new` action:

```javascript
// app/assets/javascripts/pages/projects/pages/new/index.js
import initMyFeature from '~/my_feature';

initMyFeature();
```

For more information, see [page-specific JavaScript](performance.md#page-specific-javascript).

### Enterprise Edition entrypoints

For GitLab Enterprise Edition, a page-specific entrypoint in
`ee/app/assets/javascripts/pages/` takes precedence over the Community Edition
entrypoint with the same path. To share code between the two, import the Community
Edition entrypoint from the Enterprise Edition entrypoint.

## Add page-specific CSS

Prefer [utility classes](style/scss.md#utility-classes) over custom CSS when possible.
When you need custom styles, GitLab has two approaches for page-specific CSS,
depending on whether the styles apply to many pages or to a specific page.
For more information on SCSS conventions, see the [SCSS style guide](style/scss.md).

### Global page styles

For styles shared across many pages, add a SCSS file under
`app/assets/stylesheets/pages/` and import it in
`app/assets/stylesheets/_page_specific_files.scss`:

```scss
// app/assets/stylesheets/_page_specific_files.scss
@import './pages/my_feature';
```

These styles are included in the main stylesheet bundle and load on every page.
Use this approach only when styles genuinely apply to multiple pages.

### Page bundle styles

For styles used on one or a few pages, create a SCSS file under
`app/assets/stylesheets/page_bundles/` and load it from the HAML view with
`add_page_specific_style`:

```haml
-# app/views/projects/my_feature/index.html.haml
- add_page_specific_style 'page_bundles/my_feature'
```

```scss
// app/assets/stylesheets/page_bundles/my_feature.scss
@import 'mixins_and_variables_and_functions';

.my-feature-class {
  // ...
}
```

Page bundle stylesheets load only on the pages that request them, which reduces the CSS
payload for users who never visit those pages. Prefer this approach over global page
styles when possible.
