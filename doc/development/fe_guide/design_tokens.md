---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Design tokens

Design tokens provide a single source-of-truth for values (such as color, spacing, and duration), in different modes (such as default and dark), for different tools (such as Figma and code).

## Usage

We manage design tokens in the [`gitlab-ui`](https://gitlab.com/gitlab-org/gitlab-ui) repository. This repository is published on [npm](https://www.npmjs.com/package/@gitlab/ui), and is managed as a dependency with yarn. To upgrade to a new version run `yarn upgrade @gitlab/ui`.

Design tokens are provided in different modes (default/dark) and file formats for use in CSS (custom properties), JavaScript (ES6 Constants/JSON), and SCSS (variables), for example:

**JavaScript**

```javascript
import { BLUE_500 } from '@gitlab/ui/dist/tokens/js/tokens';

const color = BLUE_500; // #1f75cb
```

**CSS**

```css
@import '@gitlab/ui/dist/tokens/css/tokens';

.elem {
  color: var(--blue-500); /* #1f75cb */
}
```

**SCSS**

```scss
@import '@gitlab/ui/dist/tokens/scss/tokens';

.elem {
  color: $blue-500; /* #1f75cb */
}
```

### Dark mode

Where color design tokens are updated for dark mode, their values are provided with the same name in files appended with `.dark`, for example:

**JavaScript**

```javascript
import { BLUE_500 } from '@gitlab/ui/dist/tokens/js/tokens.dark';

const color = BLUE_500; // #428fdc
```

**CSS**

```css
@import '@gitlab/ui/dist/tokens/css/tokens.dark';

.elem {
  color: var(--blue-500); /* #428fdc */
}
```

**SCSS**

```scss
@import '@gitlab/ui/dist/tokens/scss/tokens.dark';

.elem {
  color: $blue-500; /* #428fdc */
}
```

## Creating or updating design tokens

### Format

Our design tokens use the [Design Tokens Format Module](https://tr.designtokens.org/format/) for defining design tokens that integrate with different tools and are converted to required file formats. It is a [community group draft report](https://www.w3.org/standards/types#reports), published by the [Design Tokens Community Group](https://www.w3.org/community/design-tokens/).

The Design Tokens Format Module promotes a `*.token.json` extension standard for design token files, with a format that includes [a name and `$value`](https://tr.designtokens.org/format/#name-and-value) and an explicit [`$type`](https://tr.designtokens.org/format/#type-0):

```json
// color.tokens.json
{
  "token name": {
    "$value": "#000",
    "$type": "color"
  }
}
```

### Transformations

Our design tokens use [style-dictionary](https://amzn.github.io/style-dictionary/) to convert design tokens into consumable file formats (CSS/SCSS/JavaScript/JSON).

A parser makes [design tokens format properties](https://tr.designtokens.org/format/#design-token-properties) compatible with [style-dictionary design token attributes](https://amzn.github.io/style-dictionary/#/tokens?id=design-token-attributes).

| Design Tokens Format Module                                                | style-dictionary                                                                                                                    |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| [`$value`](https://tr.designtokens.org/format/#name-and-value) property    | [`value`](https://amzn.github.io/style-dictionary/#/tokens?id=design-token-attributes) property                                     |
| [`$type`](https://tr.designtokens.org/format/#type-0) property             | implicit nested [`category → type → item` (CTI) convention](https://amzn.github.io/style-dictionary/#/tokens?id=category-type-item) |
| [`$description`](https://tr.designtokens.org/format/#description) property | [`comment`](https://amzn.github.io/style-dictionary/#/tokens?id=design-token-attributes) property                                   |

### Names

A design token name is a unique and case-sensitive identifier of a value. A name can be used across different [modes](#modes) to generate style overrides.

### Groups

Groups are arbitrary ways to cluster tokens together in a category. They should not be used to infer the type or purpose of design tokens. For that purpose, use the [`$type`](#type) property.

```json
{
  "group name": {
    "token name": {
      "$value": "#000"
    }
  }
}
```

Group names prepend design token names in generated output, for example:

**JavaScript**

```javascript
const GROUP_NAME_TOKEN_NAME = "#000";
```

**CSS**

```css
:root {
  --group-name-token-name: #000;
}
```

**SCSS**

```scss
$group-name-token-name: #000;
```

### Values

Name and `$value` are the minimum required properties of a design token, `$value` is a reserved word.

```json
{
  "token name": {
    "$value": "16"
  }
}
```

A design token value can be a string or [alias](#aliases), for example:

| Example       | Value               |
| ------------- | ------------------- |
| color         | `"#1f75cb"`         |
| font weight   | `"bold"`            |
| spacing scale | `"16"`              |
| easing        | `"ease-out"`        |
| duration      | `"200"`             |
| alias         | `"{color.default}"` |

### Aliases

A design token's value can be a reference to another token, for example the alias token `text-color` has the value `{color.default}`:

```json
{
  "text-color": {
    "$value": "{color.default}"
  }
}
```

This allows generated CSS and SCSS that are output by using [Output References](https://amzn.github.io/style-dictionary/#/formats?id=references-in-output-files) to use references as variables:

**CSS**

```css
:root {
  --text-color: var(--color-default);
}
```

**SCSS**

```scss
$text-color: $color-default;
```

### Type

An optional [$type](https://tr.designtokens.org/format/#type-0) property is used for value transformations and grouping tokens together, for example:

```json
{
  "token name": {
    "$value": "#000",
    "$type": "color"
  }
}
```

Results in the output `tokens.grouped.json` that can be used for documentation or tooling configuration:

```json
{
  "color": {
    "token name": "#000"
  }
}
```

### Modes

Modes are processed on top of default tokens and can be combined with other modes, and inherited separately from stylesheets. Modes are denoted with a `.{mode}.token.json` filename which is used to filter tokens by file, for example: for dark mode token files, end with `.dark.token.json`.

#### Default design tokens

**Input**

`color.tokens.json`

```json
{
  "text-color": {
    "$value": "#000",
    "$type": "color"
  }
}
```

**Output**

`tokens.grouped.json`

```json
{
  "color": {
    "text-color": "#000"
  }
}
```

`tokens.js`

```javascript
export const TEXT_COLOR = "#000";
```

`tokens.scss`

```scss
$text-color: #000;
```

`tokens.css`

```css
:root {
  --text-color: #000;
}
```

#### Dark mode design tokens

Design tokens for different modes are generated separately from default tokens. Using the same name for tokens ensures they will override default values when imported, for example:

**Input**

`color.dark.tokens.json`

```json
{
  "text-color": {
    "$value": "#fff",
    "$type": "color"
  }
}
```

**Output**

`tokens.dark.grouped.json`

```json
{
  "color": {
    "text-color": "#fff"
  }
}
```

`tokens.dark.js`

```javascript
export const TEXT_COLOR = "#fff";
```

`tokens.dark.scss`

```scss
$text-color: #fff;
```

`tokens.dark.css`

```css
:root {
  --text: #fff;
}
```
