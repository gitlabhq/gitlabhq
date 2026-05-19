---
source_checksum: 4fcb3e4127a73961
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Frontend Principles

## Checklist

### General Architecture

- Use GraphQL (Apollo) as the first choice for API calls; use REST only for simple Haml pages or legacy code
- DO NOT use Vuex for new code; use Apollo or Pinia instead
- DO NOT use Apollo and Vuex together
- DO NOT create new Vuex stores; migrate existing ones to Pinia or Apollo
- Follow the standard feature directory structure: `components/`, `graphql/`, `utils/`, `router/`, `constants.js`, `index.js`
- Have as few Vue applications per page as possible; prefer Ruby ViewComponents for simple pages to avoid Vue overhead

### Vue Component Basics

- Use `.vue` files for Vue templates; DO NOT use `%template` in HAML
- Explicitly define all data passed into the Vue app (DO NOT use spread operator on `provide`/`props` at instantiation)
- Use kebab-case component names in templates (e.g., `<my-component />` not `<MyComponent />`)
- DO NOT use `<style>` tags in Vue components; use Tailwind CSS utility classes or page-specific CSS instead
- Parse non-scalar values (e.g., booleans) during Vue app instantiation using helpers like `parseBoolean`

### State Management

- Use Apollo as the default state manager for GraphQL-based applications
- Use Pinia for apps with significant client-side state or when migrating from Vuex
- DO NOT combine Apollo and Pinia as co-equal state managers; pick one as primary
- DO NOT use Apollo Client inside Pinia stores; use it only within Vue components or composables
- DO NOT sync data between Apollo and Pinia stores

### Pinia

- Use the shared Pinia instance from `~/pinia/instance`
- Prefer small, single-responsibility stores over large monolithic ones
- Use Option Stores (not Setup Stores) for new Pinia stores
- Place state, actions, and getters in a single file; DO NOT create barrel index files importing from `actions.js`, `state.js`, `getters.js`
- Use global Pinia stores for global reactive state
- DO NOT use HMR (Hot Module Replacement) with Pinia
- DO NOT create circular dependencies between Pinia stores; use `tryStore` only during Vuex migration, then refactor
- Use `createTestingPinia` with `stubActions: false` when unit testing Pinia stores
- Always create a fresh Pinia instance per test case; DO NOT reuse Pinia instances across test cases
- Register `PiniaVuePlugin` and provide the Pinia instance explicitly to `shallowMount`/`mount` in component tests
- Create stores before rendering components in tests (to avoid Vue 3 compat issues)

### JavaScript Style

- DO NOT use `forEach` when mutating data; use `map`, `reduce`, or `filter` instead
- Use an object parameter when a function has more than 3 parameters
- DO NOT use classes solely to bind DOM events; use a function instead
- Pass element containers as constructor parameters when manipulating the DOM
- Always include the radix argument when using `parseInt`; prefer `Number` for simple conversions
- Prefix CSS classes used only as JavaScript selectors with `js-`
- Use named ES module exports; reserve default exports for Vue SFCs and Vuex mutation files
- Use relative paths for imports less than two levels up; use `~/` absolute paths for two or more levels up
- DO NOT add to the global namespace (e.g., `window.MyClass`)
- DO NOT use `DOMContentLoaded` in non-page modules (only allowed in `/pages/*`)
- DO NOT use `innerHTML`, `append()`, or `html()` to set content (XSS risk)
- DO NOT use IIFEs
- DO NOT place top-level side effects in modules that contain `export`
- DO NOT make async calls, API requests, or DOM manipulations in constructors; move them to separate methods
- Export constant primitives with a common namespace (e.g., `VARIANT_WARNING = 'warning'`) rather than exporting objects; only export as a collection when iteration is needed
- Use `parseErrorMessage` from `~/lib/utils/error_message` to handle user-facing vs. generic server errors

### TypeScript (satellite projects only)

- Set `"strict": true` in `tsconfig.json`
- DO NOT use `any`; use `unknown` with type narrowing or well-defined types
- DO NOT cast with `<>` or `as`; use type predicates instead
- Prefer `interface` over `type` for new structures
- Use `type` only for aliases of existing types/interfaces
- Use union types to improve type inference and avoid casting

### Design Patterns

- DO NOT use Shared Global Objects (instances accessible from anywhere with no clear owner); export a factory function instead so the caller manages the lifecycle
- DO NOT use the Singleton pattern; prefer utility functions or dependency injection
- Use Vue `provide`/`inject` or constructor parameters for dependency injection instead of singletons

### Axios

- Import Axios from `axios_utils` (not directly from `axios`) to ensure CSRF token is set
- DO NOT use Axios in new applications; use `apollo-client` for GraphQL API calls
- Use `axios-mock-adapter` (not `spyOn`) to mock Axios responses in tests
- Always include an empty headers object `{}` as the third argument when mocking poll requests

### Internationalization (i18n)

- Use `__()`, `s__()`, `n__()` from `~/locale` for JavaScript/Vue translations
- DO NOT include HTML directly in translation strings; use placeholder pairs (e.g., `%{linkStart}/%{linkEnd}`) instead
- DO NOT split a sentence across multiple translation calls; keep full sentences together so word order can be reordered by translators
- DO NOT split a translatable sentence across multiple `GlSprintf` instances; keep the full sentence in a single `GlSprintf :message`
- Use `GlSprintf` when including child components or HTML in translation strings
- Use `sprintf` for simple variable interpolation in computed properties
- Use namespaces (PascalCase, pipe-separated) for all UI strings; prefer granular subcategories (e.g., `WorkItemsStatusConfigure|Add to`) over broad ones (e.g., `WorkItems|Add to`)
- DO NOT use `downcase` or `toLocaleLowerCase()` on translatable strings; let translators control casing
- Always pass string literals to translation helpers; DO NOT pass variables, function calls, or template literals
- DO NOT split sentences when adding links; use `%{linkStart}/%{linkEnd}` placeholder pairs
- Extract translation strings to a static `i18n` object on the Vue component (e.g., `$options.i18n.myString`) instead of inlining `s__()`/`__()` calls directly in `<template>`
- In Jest tests, DO NOT wrap expected strings in `__()` or `s__()`; use plain string literals (i18n is mocked in the test environment)
- Run `tooling/bin/gettext_extractor locale/gitlab.pot` after adding new translatable strings
- Keep translations dynamic (in methods, not class-level constants or memoized class methods)
- DO NOT use variables as arguments to translation helpers when the string can be made unique per case; create separate strings instead
- DO NOT add errors to specific model attributes when the error message is a complete sentence; add to `:base` instead so Rails does not prepend the humanized attribute name

### Vue Testing

- Re-mount the component in every test block using a `createComponent` factory function
- Use `mountExtended` / `shallowMountExtended` helpers to access `wrapper.findByTestId()`
- Use a single object argument for `createComponent` parameters
- DO NOT use `data`, `methods`, or other options that extend component internals in `createComponent`
- Set component state via `propsData` at mount time; DO NOT use `setProps` except when testing reactivity
- DO NOT use `setData`; trigger events or side-effects to force state changes
- Prefer `wrapper.props('myProp')` over `wrapper.props().myProp` or `wrapper.vm.myProp`
- Use `toEqual` when asserting multiple props; use `toMatchObject` over `expect.objectContaining` for partial prop checks
- Use `assertProps` helper to test props validation failures
- Use `stubs` option to properly stub async child components in `shallowMount`; ensure async child components have a `name` option

### Pajamas Component Usage

- Flag component usage that appears inconsistent with Pajamas "when to use" and "when not to use" guidelines
- Flag usage of container components purely for simple visual separation without using the component's structural features (header, footer, etc.)
- For simple visual separation without structured content, prefer utility classes (e.g., `gl-border gl-rounded-lg gl-p-5`) over container components
- When both control and variants are toggled in Vue components layer, prefer the `<gitlab-experiment>` component

### Experiments

- Experiment uses an `experiment` type feature flag (not `development` or `ops`)
- Context is appropriate and consistent (e.g., `actor:`, `project:`, `group:`)
- Variants are clearly defined (control, candidate, or named variants)
- Tracking calls use the same context as experiment runs
- Frontend or feature tests exist to prevent premature code removal
- Tests cover experiment variants and tracking behavior
- Temporary assets (icons/illustrations) are in `/ee/app/assets/images` or `/app/assets/images`, not Pajamas library

## Authoritative sources

For the full picture, see:

- doc/development/fe_guide/_index.md
- doc/development/fe_guide/style/vue.md
- doc/development/fe_guide/style/javascript.md
- doc/development/fe_guide/style/typescript.md
- doc/development/fe_guide/design_patterns.md
- doc/development/fe_guide/state_management.md
- doc/development/fe_guide/pinia.md
- doc/development/fe_guide/axios.md
- doc/development/i18n/externalization.md

