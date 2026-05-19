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

### Internationalization (i18n)

- DO NOT split a translatable sentence across multiple `GlSprintf` instances; keep the full sentence (e.g., `"Created %{date} by %{author}"`) in a single `GlSprintf :message` so translators can reorder words across languages
- Extract translation strings to a static `i18n` object on the Vue component (e.g., `$options.i18n.myString`) instead of inlining `s__()` / `__()` calls directly in `<template>`
