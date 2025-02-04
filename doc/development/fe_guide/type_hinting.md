---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Type hinting overview
---

The Frontend codebase of the GitLab project currently does not require nor enforces types. Adding
type annotations is optional, and we don't currently enforce any type safety in the JavaScript
codebase. However, type annotations might be very helpful in adding clarity to the codebase,
especially in shared utilities code. This document aims to cover how type hinting currently works,
how to add new type annotations, and how to set up type hinting in the GitLab project.

## JSDoc

[JSDoc](https://jsdoc.app/) is a tool to document and describe types in JavaScript code, using
specially formed comments. JSDoc's types vocabulary is relatively limited, but it is widely
supported [by many IDEs](https://en.wikipedia.org/wiki/JSDoc#JSDoc_in_use).

### Examples

#### Describing functions

Use [`@param`](https://jsdoc.app/tags-param) and [`@returns`](https://jsdoc.app/tags-returns)
to describe function type:

```javascript
/**
 * Adds two numbers
 * @param {number} a first number
 * @param {number} b second number
 * @returns {number} sum of two numbers
 */
function add(a, b) {
    return a + b;
}
```

##### Optional parameters

Use square brackets `[]` around a parameter name to mark it as optional. A default value can be
provided by using the `[name=value]` syntax:

```javascript
/**
 * Adds two numbers
 * @param {number} value
 * @param {number} [increment=1] optional param
 * @returns {number} sum of two numbers
 */
function increment(a, b=1) {
    return a + b;
}
```

##### Object parameters

Functions that accept objects can be typed by using `object.field` notation in `@param` names:

```javascript
/**
 * Adds two numbers
 * @param {object} config
 * @param {string} config.path path
 * @param {string} [config.anchor] anchor
 * @returns {string}
 */
function createUrl(config) {
    if (config.anchor) {
        return path + '#' + anchor;
    }
    return path;
}
```

#### Annotating types of variables that are not immediately assigned a value

For tools and IDEs it's hard to infer type of a value that doesn't immediately receive a value. We
can use [`@type`](https://jsdoc.app/tags-type) notation to assign type to such variables:

```javascript
/** @type {number} */
let value;
```

Consult [JSDoc official website](https://jsdoc.app/) for more syntax details.

### Tips for using JSDoc

#### Use lower-case names for basic types

While both uppercase `Boolean` and lowercase `boolean` are acceptable, in most cases when we need a
primitive or an object — lower case versions are the right choice: `boolean`, `number`, `string`,
`symbol`, `object`.

```javascript
/**
 * Translates `text`.
 * @param {string} text - The text to be translated
 * @returns {string} The translated text
 */
const gettext = (text) => locale.gettext(ensureSingleLine(text));
```

#### Use well-known types

Well-known types, like `HTMLDivElement` or `Intl` are available and can be used directly:

```javascript
/** @type {HTMLDivElement} */
let element;
```

```javascript
/**
 * Creates an instance of Intl.DateTimeFormat for the current locale.
 * @param {Intl.DateTimeFormatOptions} [formatOptions] - for available options, please see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat
 * @returns {Intl.DateTimeFormat}
 */
const createDateTimeFormat = (formatOptions) =>
  Intl.DateTimeFormat(getPreferredLocales(), formatOptions);
```

#### Import existing type definitions via `import('path/to/module')`

Here are examples of how to annotate a type of the Vue Test Utils Wrapper variables, that are not
immediately defined:

```javascript
/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
// ...
wrapper = mountExtended(/* ... */);
```

```javascript
/** @type {import('@vue/test-utils').Wrapper} */
let wrapper;
// ...
wrapper = shallowMount(/* ... */);
```

NOTE:
`import()` is [not a native JSDoc construct](https://github.com/jsdoc/jsdoc/issues/1645), but it is
recognized by many IDEs and tools. In this case we're aiming for better clarity in the code and
improved Developer Experience with an IDE.

#### JSDoc is limited

As was stated above, JSDoc has limited vocabulary. And using it would not describe the type fully.
But sometimes it's possible to use 3rd party library's type definitions to make type inference to
work for our code. Here's an example of such approach:

```diff
- export const mountExtended = (...args) => extendedWrapper(mount(...args));
+ import { compose } from 'lodash/fp';
+ export const mountExtended = compose(extendedWrapper, mount);
```

Here we use TypeScript type definitions from `compose` function, to add inferred type definitions to
`mountExtended` function. In this case `mountExtended` arguments will be of same type as `mount`
arguments. And return type will be the same as `extendedWrapper` return type.

We can still use JSDoc's syntax to add description to the function, for example:

```javascript
/** Mounts a component and returns an extended wrapper for it */
export const mountExtended = compose(extendedWrapper, mount);
```

## System requirements

A setup might be required for type definitions from GitLab codebase and from 3rd party packages to
be properly displayed in IDEs and tools.

### VS Code settings

If you are having trouble getting VS Code IntelliSense working you may need to increase the amount of
memory the TS server is allowed to use. To do this, add the following to your `settings.json` file:

```json
{
    "typescript.tsserver.maxTsServerMemory": 8192,
    "typescript.tsserver.nodePath": "node"
}
```

### Aliases

Our codebase uses many aliases for imports. For example, `import Api from '~/api';` would import a
`app/assets/javascripts/api.js` file. But IDEs might not know that alias and thus might not know the
type of the `Api`. To fix that for most IDEs — we need to create a
[`jsconfig.json`](https://code.visualstudio.com/docs/languages/jsconfig) file.

There is a script in the GitLab project that can generate a `jsconfig.json` file based on webpack
configuration and current environment variables. To generate or update the `jsconfig.json` file —
run from the GitLab project root:

```shell
node scripts/frontend/create_jsconfig.js
```

`jsconfig.json` is added to gitignore list, so creating or changing it does not cause Git changes in
the GitLab project. This also means it is not included in Git pulls, so it has to be manually
generated or updated.

### 3rd party TypeScript definitions

While more and more libraries use TypeScript for type definitions, some still might have JSDoc
annotated types or no types at all. To cover that gap, TypeScript community started a
[DefinitelyTyped](https://github.com/DefinitelyTyped/DefinitelyTyped) initiative, that creates and
supports standalone type definitions for popular JavaScript libraries. We can use those definitions
by either explicitly installing the type packages (`yarn add -D "@types/lodash"`) or by using a
feature called [Automatic Type Acquisition (ATA)](https://www.typescriptlang.org/tsconfig/#typeAcquisition),
that is available in some Language Services
(for example, [ATA in VS Code](https://github.com/microsoft/TypeScript/wiki/JavaScript-Language-Service-in-Visual-Studio#user-content--automatic-acquisition-of-type-definitions)).

Automatic Type Acquisition (ATA) automatically fetches type definitions from the DefinitelyTyped
list. But for ATA to work, a globally installed `npm` might be required. IDEs can provide a fallback
configuration options to set location of the `npm` executables. Consult your IDE documentation for
details.

Because ATA is not guaranteed to work and Lodash is a backbone for many of our utility functions
— we have [DefinitelyTyped definitions for Lodash](https://www.npmjs.com/package/@types/lodash)
explicitly added to our `devDependencies` in the `package.json`. This ensures that everyone gets
type hints for `lodash`-based functions out of the box.
