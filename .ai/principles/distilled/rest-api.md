---
source_checksum: 4148ec7d13baa0fa
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# REST API Principles

## Checklist

### General Structure

- DO NOT use instance variables in API endpoints; use local variables instead
- Use an [Entity](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/api/entities) to present every endpoint's payload
- Share implementations (e.g., service classes) between REST and GraphQL APIs where possible
- Wrap all API path helper usages in `expose_path(...)` to support relative URL installations

### Entity Field Definitions

- Include a valid `type` for every exposed field in an entity
- Define field types as strings inside the `documentation` hash (e.g., `documentation: { type: 'Integer', example: 1 }`)
- Use the `using:` option when exposing a field that references another entity; pass only an `API::Entities::*` constant
- DO NOT add new `expose` calls to high-impact entities (`UserBasic`, `ProjectIdentity`, `Commit`, etc.); create a feature-bounded entity instead
- Name feature-bounded entities after their domain context (e.g., `Ci::JobOwner`), not after the fields they contain (e.g., `UserWithNotificationEmail`)
- DO NOT manually edit `api_entity_exposure_baseline.yml` to allowlist new fields; open a discussion with the API Platform team if a field genuinely belongs on a high-impact entity

### Endpoint Description (Grape DSL)

- Include `desc`, `detail`, `success`, and `tags` in every endpoint's `desc` block
- Begin the `desc` summary with an action verb aligned to the HTTP method (Get, List, Create, Update, Delete)
- Use a string literal or interpolated string for `desc` (DO NOT use a variable or method call)
- Keep the `desc` summary to 120 characters or fewer
- Put additional details (version introduced, feature flag, deprecation) in `detail`, not in `desc`
- DO NOT include lifecycle terms ("experiment", "beta", "GA") in `desc` or `detail` strings; use `route_setting :lifecycle` instead
- Use `route_setting :lifecycle, :experiment` or `route_setting :lifecycle, :beta` for non-GA endpoints
- Use `deprecated true` in the `desc` block when deprecating an endpoint; DO NOT use `route_setting :lifecycle` for deprecation
- Assign at least one tag per endpoint; use plural entity names (for example, `audit_events`, `users`); DO NOT use singular or product-category-coupled names

### Endpoint Success Definition

- Include a `success` value in every endpoint's `desc` block
- DO NOT use the `http_codes` option to document the success response
- Pass the `Grape::Entity` class directly or via `model:` for JSON responses; omit `model:` only for no-body responses (204, redirects)
- Use `[Entities::MyEntity]` or `is_array: true` when the endpoint returns a collection
- Use `example:` (single) or `examples:` (multiple, named) to illustrate response bodies; both require `model:` and are mutually exclusive

### Parameters

- Always use `declared(params, include_parent_namespaces: false)` when passing the params hash to a method call
- Use `params[key]` directly only when accessing a single element
- Define Array types with a `coerce_with` block in Grape v1.3+
- Use the `coerce_nil_params_to_array!` helper in `before` blocks to preserve empty-array behavior for nil Array params

### HTTP Verbs and Status Codes

- Use `PATCH` when updating some attributes of a resource; use `PUT` when replacing all attributes
- Use HTTP status helpers from `lib/api/helpers.rb` (for example, `not_found!`, `no_content!`) for non-200 responses
- Use `destroy_conditionally!` for `DELETE` requests (returns 204 on success, 412 on stale `If-Unmodified-Since`)

### Breaking Changes

- DO NOT remove or rename fields, arguments, or enum values in REST API v4
- DO NOT add new required arguments to existing endpoints
- DO NOT change the type of existing response fields
- DO NOT change authentication, authorization, or header requirements
- DO NOT change any status code other than `500`
- DO NOT add new redirects without verifying client redirect-following behavior
- When a feature is removed, return a sensible static value or empty response (silent degradation) unless the feature was the endpoint's primary purpose, in which case return `404 Not Found`
- Document intended deprecations ahead of time following the v4 deprecation guide

### Experimental and Beta Features

- Add `route_setting :lifecycle, :experiment` and use an off-by-default feature flag for experiment-stage endpoints; return `404 Not Found` / ignore arguments / suppress fields when the flag is off
- Add `route_setting :lifecycle, :beta` and an on-by-default feature flag for beta-stage endpoints
- Document experiment/beta status and the feature flag in API documentation
- DO NOT describe experiment or beta changes in the OpenAPI documentation (use the `hidden` option)
- Remove `route_setting :lifecycle`, the feature flag, and experiment/beta API docs when a feature becomes generally available; add OpenAPI documentation at that point

### N+1 Query Prevention

- Implement a `with_api_entity_associations` scope on models to eager-load associations returned in the API
- Add an `ActiveRecord::QueryRecorder` test for every collection-returning endpoint to verify no N+1 queries are introduced

### File Uploads

- Use Workhorse-assisted uploads for all REST API endpoints that accept file content

### Custom Validators

- Use existing custom validators (`FilePath`, `Git SHA`, `Absence`, `IntegerNoneAny`, `ArrayNoneAny`, `EmailOrEmailList`) for parameter validation before passing values downstream
- Add new custom validators in `lib/api/validations/validators/` inheriting from `Grape::Validations::Validators::Base` and register them with `Grape::Validations.register_validator`
- Add RSpec tests for new validators in `spec/lib/api/validations/validators/`

### Testing

- Use schema fixtures from `/spec/fixtures/api/schemas` and `match_response_schema` to validate API responses

### Changelog

- Include a changelog entry for all client-facing API changes; internal API changes do not require one

### API Documentation Format

- Every method must include the REST API request with HTTP method (GET, PUT, DELETE) followed by the request path starting with `/`
- Every method must have a detailed description of attributes in a table format, with required attributes listed first, then sorted alphabetically
- Every method must include a cURL example using `https://gitlab.example.com/api/v4/` as the endpoint and `<your_access_token>` as the token placeholder
- Every method must have a detailed description of the response body and a JSON response example
- If endpoint attributes are available only to higher subscription tiers or specific offerings, include this information in the attribute description
- For complex object types, represent sub-attributes with dots, like `project.name` or `projects[].name` for arrays
- For cURL commands: use long option names (`--header` instead of `-H`), declare URLs with the `--url` parameter in double quotes, and use line breaks with `\` for readability

## Authoritative sources

For the full picture, see:

- doc/development/api_styleguide.md

