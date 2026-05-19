---
stage: none
group: Localization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Pluralization
---

Pluralization is one of the most common sources of internationalization defects.
English has two plural forms (singular and other), but [many languages have more](#plural-form-counts-by-language).
Polish and Ukrainian have four, and Arabic has six.
Incorrect pluralization produces broken grammar for millions of users.

## How GitLab handles plurals

GitLab uses GNU gettext for pluralization.
The `n_()` (Ruby/HAML) and `n__()` (JavaScript) functions select the correct
plural form based on a count:

```ruby
# Ruby/HAML
n_('Apple', 'Apples', count)
```

```javascript
// JavaScript
n__('Apple', 'Apples', count)
```

Gettext evaluates a single count to determine which plural form to use:

```plaintext
ngettext(singular, plural, count)
                            ↑
                     one number only
```

Each target language defines its own plural rule in the PO file header (`Plural-Forms`),
which maps the count to the correct `msgstr[]` slot.
Translators provide as many forms as their language requires.

## When to use n_() and n__()

Use `n_()` or `n__()` when a word form changes based on a count.

The test: Does the noun or verb inflect differently based on the number?

```javascript
// Correct: "day" changes form based on count
n__('Last day', 'Last %d days', count)

// Correct: "issue" changes form
n__('%d issue', '%d issues', count)
```

Use `n_()` and `n__()` only to select between plural forms of the same string.
Do not use them to control logic between different strings.

If your string contains a count variable, check whether the noun needs to pluralize.
A common oversight is to pass a count through `%{variable}` but use `__()` or `s__()`
instead of `n__()`, which means the noun always appears in singular form:

```javascript
// Incorrect: "days" is always singular regardless of count
s__('TrialWidget|%{daysLeft} days left in trial')

// Correct: Noun pluralizes with the count
n__('TrialWidget|%{daysLeft} day left in trial',
    'TrialWidget|%{daysLeft} days left in trial', daysLeft)
```

For strings that are structurally different, use `if`/`else` with separate strings:

```ruby
# Preferred: Different strings handled with conditional logic
if selected_projects.one?
  selected_projects.first.name
else
  n_("Project selected", "%d projects selected", selected_projects.count)
end

# Avoid: Mixing a variable name with a count-based selection
format(n_("%{project_name}", "%d projects selected", count), project_name: 'GitLab')
```

### Zero state handling

Do not place a standalone zero-state phrase in the `one` slot to
handle the zero case:

```plaintext
# Avoid — two conceptually different ideas in one plural string
msgid "MlModelRegistry|· No other versions"
msgid_plural "MlModelRegistry|· %d versions"
```

The singular slot here does not express "one version". It expresses "no versions".
These messages are two different concepts, not two forms of the same concept.

Languages like Chinese, Japanese, and Korean have only one plural form and use only the
`other` category. The translator gets a single slot and cannot express both ideas.
One meaning is structurally impossible to translate.

For the zero state, use a separate string. For counted forms, use `n__()`:

```javascript
// Preferred: Zero handled as its own string
if (count === 0) {
  s__('MlModelRegistry|No other versions')
} else {
  n__('MlModelRegistry|%{count} version', 'MlModelRegistry|%{count} versions', count)
}
```

### Whole-sentence pluralization

Pluralize whole sentences to give translators the full context they need:

```javascript
// Preferred: Whole-sentence pluralization
n__('Last day', 'Last %d days', days.length)

// Avoid: Single-word extraction with sentence construction around it
const pluralize = n__('day', 'days', days.length)
if (days.length === 1) {
  return sprintf(s__('Last %{pluralize}'), { pluralize })
}
return sprintf(s__('Last %{dayNumber} %{pluralize}'), { dayNumber: days.length, pluralize })
```

Some languages have different quantities of plural forms. Whole-sentence pluralization
ensures translators can produce correct output regardless of their language's
plural rules.

## When not to use n_() and n__()

Numbers in a string do not automatically make it a plural string.
If the string labels a position, sequence, or identifier rather than a quantity,
it is singular.

```javascript
// These are NOT plural. They label a single step's position.
__('Step %{currentStep}')
__('Step %{currentStep} of %{stepsTotal}')

// "Step" never changes form regardless of the number.
// "Step 1", "Step 5", "Step 42" are always singular.
```

The distinction is counting (which requires pluralization) versus
labeling or sequencing (which does not).
If you always refer to one thing and insert a number as an identifier,
use `__()`, not `n__()`.

## Interpolation in plural strings

Use named `%{count}` interpolation rather than the positional `%d` placeholder.
Named placeholders give translators a readable variable name and are consistent
with the GitLab convention for all other interpolated strings.

For single-count strings, `%d` is acceptable, but `%{count}` is preferred:

```javascript
// Preferred
n__('%{count} issue', '%{count} issues', count)

// Acceptable
n__('%d issue', '%d issues', count)
```

For strings with multiple variables, always use named `%{placeholder}` syntax.

In Ruby and HAML, apply `%` after the `n_()` call to substitute the value:

```ruby
n_("There is a mouse.", "There are %d mice.", size) % size
# => When size == 1: 'There is a mouse.'
# => When size == 2: 'There are 2 mice.'
```

### In Vue

In Vue, do not define pluralized strings that depend on runtime counts as static constants.
Instead, define them as functions that accept a `count` argument:

```javascript
// .../feature/constants.js
import { n__ } from '~/locale';

export const I18N = {
  // Static strings that are always singular do not need a function
  someDaysRemain: __('Some days remain'),
  daysRemaining(count) { return n__('%d day remaining', '%d days remaining', count); },
};
```

Use the function in the component template:

```javascript
// .../feature/components/days_remaining.vue
import { I18N } from '../constants';

export default {
  props: {
    days: { type: Number, required: true },
  },
  i18n: I18N,
};
```

```html
<template>
  <div>
    <span>{{ $options.i18n.someDaysRemain }}</span>
    <span>{{ $options.i18n.daysRemaining(days) }}</span>
  </div>
</template>
```

### `%d` in singular form anti-pattern

Avoid `%d` in the singular form when the number adds no value.
For example, `Last day` reads more naturally than `Last 1 day`:

```javascript
// Preferred: Singular form omits the number
n__('Last day', 'Last %d days', count)

// Avoid: "Last 1 day" is unnatural
n__('Last %d day', 'Last %d days', count)
```

### Problem with `%d` in singular form

Including `%d` in the singular form creates problems in languages where
the `one` plural category is not equivalent to the numeral 1.

The `one` category is a grammatical category, not a literal count.
According to the [Unicode CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
specification, the `one` category represents any number that behaves grammatically like 1 in a given language,
not just the number 1.

Examples:

- In French, 0 uses the `one` category.
- In Ukrainian, any number ending in 1 (except 11) uses the `one` category: 1, 21, 31, 41, 51...

If your singular form does not contain `%d`, a translator working in Ukrainian might
copy the hardcoded number into their translation:

```plaintext
# Source string sent to translators (no placeholder in singular form)
one: You have 1 new message
other: You have %d new messages

# Ukrainian translation — translator mirrors the hardcoded 1
one: У вас є 1 нове повідомлення
other: У вас є %d нових повідомлень
```

In Ukrainian, the `one` category applies to 1, 21, 31, 41, and any number
ending in 1 (except 11). A user with 21 new messages sees
"You have 1 new message". The translation is correct for the
number 1 but incorrect for every other number in the `one` category.

This is not a theoretical risk. A community translator working on a GitLab
string flagged exactly this problem in Crowdin with the comment:
"Singular tag needs to be removed for the sentence to seem natural in ptBR".
The translator had correctly identified that the hardcoded number in the
singular form made their translation read unnaturally.

Crowdin and other translation checkers cannot catch this error because
there is no placeholder to verify. The string passes all checks and the
defect ships silently.

The positional `%s` placeholder is also an improvement over a hardcoded number,
but the named `%{count}` placeholder is preferred. It provides translators
with a readable variable name and is consistent with the GitLab convention:

```javascript
// Avoid: Hardcoded number in singular form
n__('Timeago|1 second ago', 'Timeago|%s seconds ago', n)

// Acceptable: Positional placeholder in both forms
n__('Timeago|%s second ago', 'Timeago|%s seconds ago', n)

// Preferred: Named placeholder
n__('Timeago|%{count} second ago', 'Timeago|%{count} seconds ago', n)
```

When you want a natural singular form without a number, handle it as a
separate string outside the plural call, not inside the `one` slot.

In Ruby/HAML:

```ruby
# Preferred: Separate handling for the exact count of 1
if count == 1
  s_('SecurityProfiles|Last scan successful')
else
  n_('SecurityProfiles|Last %{count} scan successful',
     'SecurityProfiles|Last %{count} scans successful', count)
end
```

In JavaScript:

```javascript
// Preferred: Separate handling for the exact count of 1
if (count === 1) {
  s__('SecurityProfiles|Last scan successful')
} else {
  n__('SecurityProfiles|Last %{count} scan successful',
      'SecurityProfiles|Last %{count} scans successful', count)
}
```

This gives translators and users a natural singular form
while preserving correct plural handling for all other counts.

## Multiple independent plurals in one string

Gettext cannot handle multiple independent plurals in a single string.
The `ngettext` function accepts only one count, so it cannot pluralize
two nouns independently.

Consider this string from the GitLab codebase:

```plaintext
IncidentManagement|%{hours} hours, %{minutes} minutes remaining
```

Both `hours` and `minutes` pluralize based on different counts.
In Arabic, which has six plural forms, that would require 36 combinations.
Gettext cannot express this.

### Split and combine

Split the string into separate pluralized parts and combine them
with a non-pluralized connector:

```javascript
const hoursText = n__('%{count} hour', '%{count} hours', hours);
const minutesText = n__('%{count} minute', '%{count} minutes', minutes);

sprintf(s__('IncidentManagement|%{hours}, %{minutes} remaining'), {
  hours: hoursText,
  minutes: minutesText
});
```

Each `n__()` call handles one plural independently.
The connector string is a standard translatable string that gives translators
control over word order.

> [!note]
> Other internationalization frameworks like ICU MessageFormat and Mozilla Fluent
> support multiple inline plural selectors natively. GitLab uses gettext,
> so the split-and-combine pattern is the correct approach.

## CLDR plural categories

The Unicode Common Locale Data Repository (CLDR) defines six plural categories.
Not every language uses all of them.

| Category | Example languages                         |
|----------|-------------------------------------------|
| `zero`   | Arabic, Welsh                             |
| `one`    | English, French, German, Ukrainian        |
| `two`    | Arabic, Welsh, Slovenian                  |
| `few`    | Polish, Ukrainian, Czech, Arabic          |
| `many`   | Polish, Ukrainian, Arabic                 |
| `other`  | All languages (required)                  |

These categories are mnemonics, not literal descriptions.
The `one` category is not the number 1. It is any number that behaves
grammatically like 1.
The `few` category in Polish covers numbers ending in 2-4, but not 12-14.

For the exact rules per language, see the
[Unicode CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules) specification.

## Plural form counts by language

| Language   | Forms | Categories used                              |
|------------|-------|----------------------------------------------|
| Chinese    | 1     | `other`                                      |
| Japanese   | 1     | `other`                                      |
| Korean     | 1     | `other`                                      |
| English    | 2     | `one`, `other`                               |
| French     | 2     | `one`, `other`                               |
| German     | 2     | `one`, `other`                               |
| Czech      | 3     | `one`, `few`, `other`                        |
| Polish     | 4     | `one`, `few`, `many`, `other`                |
| Ukrainian  | 4     | `one`, `few`, `many`, `other`                |
| Arabic     | 6     | `zero`, `one`, `two`, `few`, `many`, `other` |

## Related topics

- [Externalization for GitLab](externalization.md)
- [Unicode CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
- [CLDR Language Plural Rules chart](https://www.unicode.org/cldr/charts/48/supplemental/language_plural_rules.html)
- [GNU gettext Plural Forms](https://www.gnu.org/software/gettext/manual/html_node/Plural-forms.html)
