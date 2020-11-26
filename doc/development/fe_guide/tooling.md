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

To check all currently staged files (based on `git diff`) with ESLint, run the following script:

```shell
yarn eslint-staged
```

A list of problems found will be logged to the console.

To apply automatic ESLint fixes to all currently staged files (based on `git diff`), run the following script:

```shell
yarn eslint-staged-fix
```

If manual changes are required, a list of changes will be sent to the console.

To check **all** files in the repository with ESLint, run the following script:

```shell
yarn eslint
```

A list of problems found will be logged to the console.

To apply automatic ESLint fixes to **all** files in the repository, run the following script:

```shell
yarn eslint-fix
```

If manual changes are required, a list of changes will be sent to the console.

CAUTION: **Caution:**
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

## Formatting with Prettier

> Support for `.graphql` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227280) in GitLab 13.2.

Our code is automatically formatted with [Prettier](https://prettier.io) to follow our style guides. Prettier is taking care of formatting `.js`, `.vue`, `.graphql`, and `.scss` files based on the standard prettier rules. You can find all settings for Prettier in `.prettierrc`.

### Editor

The recommended method to include Prettier in your workflow is to set up your
preferred editor (all major editors are supported) accordingly. We suggest
setting up Prettier to run when each file is saved. For instructions about using
Prettier in your preferred editor, see the [Prettier documentation](https://prettier.io/docs/en/editors.html).

Please take care that you only let Prettier format the same file types as the global Yarn script does (`.js`, `.vue`, `.graphql`, and `.scss`). In VSCode by example you can easily exclude file formats in your settings file:

```json
  "prettier.disableLanguages": [
      "json",
      "markdown"
  ]
```

### Yarn Script

The following yarn scripts are available to do global formatting:

```shell
yarn prettier-staged-save
```

Updates all currently staged files (based on `git diff`) with Prettier and saves the needed changes.

```shell
yarn prettier-staged
```

Checks all currently staged files (based on `git diff`) with Prettier and log which files would need manual updating to the console.

```shell
yarn prettier-all
```

Checks all files with Prettier and logs which files need manual updating to the console.

```shell
yarn prettier-all-save
```

Formats all files in the repository with Prettier. (This should only be used to test global rule updates otherwise you would end up with huge MR's).

The source of these Yarn scripts can be found in `/scripts/frontend/prettier.js`.

#### Scripts during Conversion period

```shell
node ./scripts/frontend/prettier.js check-all ./vendor/
```

This will go over all files in a specific folder check it.

```shell
node ./scripts/frontend/prettier.js save-all ./vendor/
```

This will go over all files in a specific folder and save it.

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
