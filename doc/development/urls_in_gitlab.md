---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: URLs in GitLab
---

## Overview

GitLab supports multiple deployment configurations that affect how URLs are generated and
resolved. Using hardcoded or absolute URLs can break functionality in these scenarios:

- [Relative URL installations](../install/relative_url.md) - GitLab deployments with a path prefix, for example, `https://example.com/gitlab/`.
- [Geo deployments](../administration/geo/_index.md) - Primary and secondary sites with different URLs
- [Organization scoped routes](organization/_index.md#organization-routing) - Dynamic URL structures based on organization context

To ensure URLs work correctly across all deployment configurations follow the below guidelines.

## General guidelines

- Use Rails as the single source of truth for generating URLs. If you need a URL on the
frontend, generate it in Rails and pass it to the frontend.
- Use relative URLs for internal application links. Use absolute URLs only when:
  - Generating links for emails.
  - Constructing URLs for external services.
  - Building clone or download URLs that must work outside the web interface.

## Backend guidelines

### Path and URL helpers

Use Rails [path and URL helpers](https://guides.rubyonrails.org/routing.html#path-and-url-helpers)
to generate URLs.

- Use `*_path` helpers for all internal application links.
- Use `*_url` helpers only for links that need to be consumed outside of the application, such as:
  - Links for emails.
  - URLs for external services.
  - Clone or download URLs that must work outside the web interface.

```ruby
# Correct - Relative path
redirect_to project_path(@project)

# Incorrect - Absolute URL
redirect_to project_url(@project)
```

## Frontend guidelines

### JavaScript and Vue

Do not hardcode or construct URLs in JavaScript or Vue. Generate URLs in Rails and pass
them to the frontend through data attributes, GraphQL queries, or REST APIs.

```javascript
// Incorrect - Do not construct URLs on the frontend
const endpoint = `${gon.relative_url_root}/${projectPath}/-/refs`;
```

For correct alternatives, see the following sections.

### JavaScript path helpers

We use the [js-routes](https://github.com/railsware/js-routes) to generate JavaScript path helpers that mirror the [backend path helpers](#path-and-url-helpers). These helpers are generated when starting GDK and can be viewed in the `app/assets/javascripts/lib/utils/path_helpers` directory.

#### Finding the correct path helper

The easiest way to find the correct path helper is to search through `app/assets/javascripts/lib/utils/path_helpers` directory for a substring of the path you need. For example if you need `/<project path>/-/snippets/new` search for `/-/snippets/new` until you find the helper that accepts the project path as a parameter.

Path helpers are organized by where they are defined in Rails. For example routes defined in `config/routes/project.rb` will be available to the frontend in `app/assets/javascripts/lib/utils/path_helpers/project.js`. This also applies to EE specific path helpers. For example a route defined in `ee/config/routes/project.rb` will be available to the frontend in `ee/app/assets/javascripts/lib/utils/path_helpers/project.js`.

For more complicated cases you can find routes for a specific controller by running `bin/rails routes -c name_of_controller --expanded`. For example if you wanted to see the routes for project snippets you could run `bin/rails routes -c projects/snippets --expanded`. This would output:

```plaintext
--[ Route 6 ]--------------------------------------------------------------------------------------------------------------
Prefix            | new_snippet
Verb              | GET
URI               | /-/snippets/new(.:format)
Controller#Action | snippets#new
Source Location   | /config/routes/snippets.rb:3
```

The JavaScript path helper is the `Prefix` in camelCase with suffix `Path`. In the above example it will be `newSnippetPath`. The `Source Location` indicates which file the path helper will be in. In the above example it would be in `app/assets/javascripts/lib/utils/path_helpers/snippets.js`

{{< alert type="note" >}}

`app/assets/javascripts/lib/utils/path_helpers/*.js` should be generated when starting [GitLab Development Kit](https://gitlab-org.gitlab.io/gitlab-development-kit/). If the path helpers are not generated or you are getting errors due to them being out of date, you can manually generate the path helpers by running `bundle exec rake gitlab:js:routes`. Similarly you can clear the cache and restart GDK with `yarn clean && gdk restart`.

{{< /alert >}}

#### Project path helpers

To improve usability and match Rails functionality in [config/routes.rb#L368](https://gitlab.com/gitlab-org/gitlab/-/blob/4202e37329fb343ae674db79593ce04427ebab6b/config/routes.rb#L368) project path helpers use a shorthand name and argument. Instead of `newNamespaceProjectSnippetPath` that accepts `namespacePath` and `projectPath` separately it is `newProjectSnippetPath` that accepts one `projectFullPath` argument. See example in [using path helpers](#using-path-helpers).

#### Organization scoped routes

Every route has an [organization scoped counterpart](organization/_index.md#organization-routing). The organization scoped routes do not have a JavaScript path helper. Instead there is logic behind the scenes that uses the organization path helper when in the context of a scoped organization. This means instead of manually using checking if `newOrganizationSnippetPath` you can simply use `newSnippetPath`.

#### Using path helpers

```vue
<script>
import { GlLink } from '@gitlab/ui';
import { newProjectSnippetPath } from '~/lib/utils/path_helpers/project';
import { newSnippetPath } from '~/lib/utils/path_helpers/snippets';

export default {
  components: {
    GlLink
  },
  props: {
    project: {
      type: Object,
      required: true,
    }
  },
  methods: {
    newSnippetPath,
    newProjectSnippetPath,
  }
};
</script>
<template>
  <div>
    <gl-link :href="newSnippetPath()">{{ __('New snippet') }}</gl-link>
    <gl-link :href="newProjectSnippetPath(project.fullPath)">{{ __('New project snippet') }}</gl-link>
  </div>
</template>
```

### Passing URLs with data attributes

{{< alert type="note" >}}

While this approach is still acceptable, using [path helpers](#javascript-path-helpers) is preferred.

{{< /alert >}}

Pass URLs from Rails to the frontend by using `data-*` attributes. For example:

```haml
#js-my-app{ data: { base_path: project_iteration_cadences_path(project) } }
```

```javascript
const initMyApp = () => {
  const el = document.getElementById('js-my-app');

  if (!el) return false;

  const { basePath } = el.dataset
}
```

### GraphQL queries

Avoid using `webUrl` fields. Instead, use the `webPath` or other relative URL field, for
example, `adminEditPath`. If the `webPath` field does not exist on that GraphQL type, add
it. Be careful of [compatibility across updates](multi_version_compatibility.md#when-modifying-javascriptvue)
when you add new GraphQL fields.

### REST API

Avoid using `web_url` fields. Instead, use `web_path` or other relative URL fields, for
example, `admin_edit_path`. If `web_path` does not exist on the REST API endpoint, add it.
Be careful of [compatibility across updates](multi_version_compatibility.md#when-modifying-javascriptvue)
when you add new fields to REST API endpoints.

### Vue router

For the correct way to configure Vue Router, see [Vue Router](fe_guide/vue.md#vue-router).

### HAML templates

Use `*_path` helpers instead of `*_url` helpers:

```haml
-# Correct - Relative URL
= link_to _('Dashboard'), dashboard_projects_path

-# Incorrect - Absolute URL
= link_to _('Dashboard'), dashboard_projects_url
```

## Linking to help pages

For guidance on how to link to help pages, see [linking to /help](documentation/help.md#linking-to-help).
