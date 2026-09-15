---
source_checksum: dccc3e71696cd255
distilled_at_sha: 1f3c26497b7f19bbd0b53f947a7f7aaa95685501
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Internationalization Principles

## Checklist

### Marking Strings for Translation

- Use `_()` in Ruby/HAML, `__()` in JavaScript/Vue, and `s__()`/`s_()` for namespaced strings to mark content for translation.
- Use `n_()` in Ruby/HAML and `n__()` in JavaScript/Vue to mark pluralized strings (see Pluralization section).
- DO NOT translate strings at the class or module level (constants or memoized class methods); keep translation calls in instance methods or lambdas so they are evaluated per request with the correct locale.
- Use a `Proc`/lambda for Rails model `:message` options instead of calling `_()` inline, to avoid translating at class-load time.
- DO NOT externalize strings from `lib/api/` or `app/graphql/`; API messages do not need to be translated.
- Always pass string literals to translation helpers (`_()`, `__()`, `s__()`, `n__()`); DO NOT pass variables, function calls, or interpolated strings — the `tooling/bin/gettext_extractor` parser cannot resolve them.
- In Vue `<template>` blocks, call `__()`, `s__()`, `n__()`, and `sprintf()` directly (the `translate` mixin provides them); import from `~/locale` only when translating inside component JavaScript.

### Namespaces

- Add a namespace (PascalCase prefix followed by `|`) to all UI strings using `s__()`/`s_()` to provide translators with context.
- Use granular, specific namespaces rather than broad category names (e.g., `WorkItemsStatusConfigure|Add to` instead of `WorkItems|Add to`).
- DO NOT share the same English key across different UI contexts without namespacing; the same English string may require different translations in other languages.

### Interpolation

- Match placeholder style to the file type: use `%{snake_case}` in Ruby/HAML and `%{camelCase}` in JavaScript.
- In Vue, use the `GlSprintf` component when the translated string contains child components, HTML, or when passing `false` to `sprintf` to suppress escaping; use `sprintf` in computed properties for simpler cases.
- When using `sprintf` with markup and `false` as the third argument, manually escape all dynamic values (e.g., with `escape` from `lodash-es`) to prevent XSS.
- DO NOT split sentences across multiple translation calls or across multiple `GlSprintf` instances; externalize the whole sentence with placeholders for dynamic parts (including links) so translators can reorder words to match their language's grammar.
- For links inside translated strings, use `%{linkStart}…%{linkEnd}` placeholder pairs rather than passing a full `<a>` tag as a single placeholder.
- In Ruby/HAML, use `safe_format` with `tag_pair` to inject HTML formatting into translated strings; DO NOT embed raw HTML in the source string.
- DO NOT include raw HTML directly in strings submitted for translation (XSS risk and invalid-HTML risk); use placeholder pairs or `GlSprintf` instead.
- For angle brackets (`<`/`>`) that are not HTML, use the HTML entity codes (`&lt;`/`&gt;`) to avoid `rake gettext:lint` errors.

### Pluralization

- Use `n_()` (Ruby/HAML) or `n__()` (JavaScript) when a noun or verb changes form based on a count; DO NOT use `__()` or `s__()` for strings where the noun must pluralize with the count.
- Use `n_()` and `n__()` only to select between plural forms of the same concept; DO NOT use them to switch between structurally different strings — use `if`/`else` with separate strings instead.
- DO NOT place a zero-state phrase in the `one` (singular) slot of a plural string; handle the zero state as a separate string outside the `n__()` call.
- Pluralize whole sentences rather than extracting a single word and constructing the sentence around it, so translators have full context for all plural forms.
- Prefer named `%{count}` interpolation over positional `%d` in plural strings; for strings with multiple variables, always use named `%{placeholder}` syntax.
- DO NOT hardcode the number `1` in the singular form of a plural string; use `%{count}` (preferred) or `%s` (acceptable) so that languages where the `one` CLDR category covers numbers other than 1 (e.g., Ukrainian: 21, 31, …) produce correct output. Exception: when a natural singular form without a number is desired, handle the exact count of 1 as a separate string outside the plural call (e.g., `if count == 1 … else n_(…) end`).
- DO NOT use `%d` in the singular form when the number adds no value (e.g., prefer `'Last day'` over `'Last 1 day'`).
- For strings with multiple independently pluralized nouns (e.g., hours and minutes), split into separate `n__()` calls and combine with a non-pluralized connector string via `sprintf`; DO NOT attempt to pluralize multiple nouns in a single `n__()` call.
- DO NOT use Rails `pluralize` helper or `String#pluralize` on translated strings; they apply English-only rules and produce broken output in other locales. Use `n_()` with a whole-sentence pattern instead.
- In Vue, define pluralized strings that depend on runtime counts as functions accepting a `count` argument in the `i18n` constants object; DO NOT define them as static string constants.

### Vue Single-File Components

- Place translation calls inline in the `<template>` by default; DO NOT move a single-use string into `$options.i18n` unless one of the documented exceptions applies.
- Use `$options.i18n` or a shared constant only when: the same string is reused across the template and component JavaScript and must stay in sync; the string requires processing (e.g., `sanitize()`); the string is a value in a runtime-keyed lookup map; or the string is shared across multiple components in the same module.
- DO NOT import translation constants from component files into specs; write the expected string literal directly in the assertion to avoid false positives from `undefined` imports.
- Place inline translations as close as possible to where they are used; prefer inline calls over variables with translations.

### Numbers, Dates, and Times

- Use `formatNumber` from `~/locale` (backed by `toLocaleString()`) to format numbers for display; DO NOT format numbers as plain strings without locale awareness.
- In JavaScript, use `createDateTimeFormat` from `~/locale` (backed by `Intl.DateTimeFormat`) for locale-aware date/time formatting.
- In Ruby/HAML, use the `l` helper with a predefined format from `en.yml` for dates and times; use `strftime` only for one-off formats not worth adding to `en.yml`.

### Case Transformation

- DO NOT call `downcase`, `toLocaleLowerCase()`, or similar methods on translatable strings; let translators control capitalization for their language.

### Variables in Translatable Strings

- Avoid inserting text as variables into translatable strings when possible; prefer unique strings for each case to avoid gender-agreement, declension, and word-order issues across languages.
- When variable insertion cannot be avoided, use a topic-comment structure (e.g., `Related items: %{a} → %{b}`) rather than a full sentence with inserted variables.

### Rails Model Error Messages

- Add error messages to `:base` with a complete sentence rather than to a specific attribute; Rails prepends the humanized attribute name to attribute-level messages, producing split sentences that are untranslatable.

### Updating and Validating PO Files

- Run `tooling/bin/gettext_extractor locale/gitlab.pot` after marking new strings for translation to update the POT file; DO NOT push changes without updating it (pre-push checks and the CI `gettext` pipeline job will fail).
- DO NOT check in changes to `locale/[language]/gitlab.po` files manually; they are updated automatically when Crowdin translations are merged.
- Run `rake gettext:lint` locally to validate PO files before pushing; the same lint runs in CI as part of the `static-analysis` job and checks PO syntax, variable usage, and angle-bracket presence.
- If the `gitlab.pot` file has merge conflicts, delete it and regenerate with `tooling/bin/gettext_extractor locale/gitlab.pot`.

### Test Files

- In RSpec tests, DO NOT hard-code expected translated strings; call the same translation helper (e.g., `_('…')`) in the expectation so tests pass under non-default locales.
- In Jest tests, DO NOT wrap expected strings in translation helpers (`__()` etc.); externalization is mocked in the frontend test environment, so use plain string literals in assertions.

### Adding a New Language

- Add a new language to the UI only after at least 10% of strings have been translated and approved in Crowdin; languages below 2% are not shown in the UI.
- Register the new language in `lib/gitlab/i18n.rb` and run `bin/rake gettext:add_language[<locale>]` to create the locale directory and PO file.

## Authoritative sources

For the full picture, see:

- doc/development/i18n/externalization.md
- doc/development/i18n/pluralization.md
