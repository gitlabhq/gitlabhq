---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Tooling

## ESLint

We use ESLint to encapsulate and enforce frontend code standards. Our configuration may be found in the [`gitlab-eslint-config`](https://gitlab.com/gitlab-org/gitlab-eslint-config) project.

### Yarn Script

This section describes yarn scripts that are available to validate and apply automatic fixes to files using ESLint.

To check all staged files (based on `git diff`) with ESLint, run the following script:

```shell
yarn run lint:eslint:staged
```

A list of problems found are logged to the console.

To apply automatic ESLint fixes to all staged files (based on `git diff`), run the following script:

```shell
yarn run lint:eslint:staged:fix
```

If manual changes are required, a list of changes are sent to the console.

To check a specific file in the repository with ESLINT, run the following script (replacing $PATH_TO_FILE):

```shell
yarn run lint:eslint $PATH_TO_FILE
```

To check **all** files in the repository with ESLint, run the following script:

```shell
yarn run lint:eslint:all
```

A list of problems found are logged to the console.

To apply automatic ESLint fixes to **all** files in the repository, run the following script:

```shell
yarn run lint:eslint:all:fix
```

If manual changes are required, a list of changes are sent to the console.

WARNING:
Limit use to global rule updates. Otherwise, the changes can lead to huge Merge Requests.

### Disabling ESLint in new files

Do not disable ESLint when creating new files. Existing files may have existing rules
disabled due to legacy compatibility reasons but they are in the process of being refactored.

Do not disable specific ESLint rules. To avoid introducing technical debt, you may disable the following
rules only if you are invoking/instantiating existing code modules.

- [`no-new`](https://eslint.org/docs/rules/no-new)
- [`class-method-use-this`](https://eslint.org/docs/rules/class-methods-use-this)

Disable these rules on a per-line basis. This makes it easier to refactor in the
future. For example, use `eslint-disable-next-line` or `eslint-disable-line`.

### Disabling ESLint for a single violation

If you do need to disable a rule for a single violation, disable it for the smallest amount of code necessary:

```javascript
// bad
/* eslint-disable no-new */

import Foo from 'foo';

new Foo();

// better
import Foo from 'foo';

// eslint-disable-next-line no-new
new Foo();
```

### The `no-undef` rule and declaring globals

**Never** disable the `no-undef` rule. Declare globals with `/* global Foo */` instead.

When declaring multiple globals, always use one `/* global [name] */` line per variable.

```javascript
// bad
/* globals Flash, Cookies, jQuery */

// good
/* global Flash */
/* global Cookies */
/* global jQuery */
```

### Deprecating functions with `import/no-deprecated`

Our `@gitlab/eslint-plugin` Node module contains the [`eslint-plugin-import`](https://gitlab.com/gitlab-org/frontend/eslint-plugin) package.

We can use the [`import/no-deprecated`](https://github.com/benmosher/eslint-plugin-import/blob/HEAD/docs/rules/no-deprecated.md) rule to deprecate functions using a JSDoc block with a `@deprecated` tag:

```javascript
/**
 * Convert search query into an object
 *
 * @param {String} query from "document.location.search"
 * @param {Object} options
 * @param {Boolean} options.gatherArrays - gather array values into an Array
 * @returns {Object}
 *
 * ex: "?one=1&two=2" into {one: 1, two: 2}
 * @deprecated Please use `queryToObject` instead. See https://gitlab.com/gitlab-org/gitlab/-/issues/283982 for more information
 */
export function queryToObject(query, options = {}) {
  ...
}
```

It is strongly encouraged that you:

- Put in an **alternative path for developers** looking to use this function.
- **Provide a link to the issue** that tracks the migration process.

NOTE:
Uses are detected if you import the deprecated function into another file. They are not detected when the function is used in the same file.

Running `$ yarn eslint` after this will give us the list of deprecated usages:

```shell
$ yarn eslint

./app/assets/javascripts/issuable_form.js
   9:10  error  Deprecated: Please use `queryToObject` instead. See https://gitlab.com/gitlab-org/gitlab/-/issues/283982 for more information  import/no-deprecated
  33:23  error  Deprecated: Please use `queryToObject` instead. See https://gitlab.com/gitlab-org/gitlab/-/issues/283982 for more information  import/no-deprecated
...
```

Grep for disabled cases of this rule to generate a working list to create issues from, so you can track the effort of removing deprecated uses:

```shell
$ grep "eslint-disable.*import/no-deprecated" -r .

./app/assets/javascripts/issuable_form.js:import { queryToObject, objectToQuery } from './lib/utils/url_utility'; // eslint-disable-line import/no-deprecate
./app/assets/javascripts/issuable_form.js:  // eslint-disable-next-line import/no-deprecated
```

## Formatting with Prettier

> Support for `.graphql` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227280) in GitLab 13.2.

Our code is automatically formatted with [Prettier](https://prettier.io) to follow our style guides. Prettier is taking care of formatting `.js`, `.vue`, `.graphql`, and `.scss` files based on the standard prettier rules. You can find all settings for Prettier in `.prettierrc`.

### Editor

The recommended method to include Prettier in your workflow is to set up your
preferred editor (all major editors are supported) accordingly. We suggest
setting up Prettier to run when each file is saved. For instructions about using
Prettier in your preferred editor, see the [Prettier documentation](https://prettier.io/docs/en/editors.html).

Please take care that you only let Prettier format the same file types as the global Yarn script does (`.js`, `.vue`, `.graphql`, and `.scss`). For example, you can exclude file formats in your Visual Studio Code settings file:

```json
  "prettier.disableLanguages": [
      "json",
      "markdown"
  ]
```

### Yarn Script

The following yarn scripts are available to do global formatting:

```shell
yarn run lint:prettier:staged:fix
```

Updates all staged files (based on `git diff`) with Prettier and saves the needed changes.

```shell
yarn run lint:prettier:staged
```

Checks all staged files (based on `git diff`) with Prettier and log which files would need manual updating to the console.

```shell
yarn run lint:prettier
```

Checks all files with Prettier and logs which files need manual updating to the console.

```shell
yarn run lint:prettier:fix
```

Formats all files in the repository with Prettier.

### VSCode Settings

#### Select Prettier as default formatter

To select Prettier as a formatter, add the following properties to your User or Workspace Settings:

```javascript
{
  "[html]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[vue]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[graphql]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

#### Format on Save

To automatically format your files with Prettier, add the following properties to your User or Workspace Settings:

```javascript
{
  "[html]": {
    "editor.formatOnSave": true
  },
  "[javascript]": {
    "editor.formatOnSave": true
  },
  "[vue]": {
    "editor.formatOnSave": true
  },
  "[graphql]": {
    "editor.formatOnSave": true
  },
}
```
