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

### Passing URLs with data attributes

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
