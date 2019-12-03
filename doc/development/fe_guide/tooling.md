# Tooling

## ESLint

We use ESLint to encapsulate and enforce frontend code standards. Our configuration may be found in the [gitlab-eslint-config](https://gitlab.com/gitlab-org/gitlab-eslint-config) project.

### Disabling ESLint in new files

Do not disable ESLint when creating new files. Existing files may have existing rules
disabled due to legacy compatibility reasons but they are in the process of being refactored.

Do not disable specific ESLint rules. To avoid introducing technical debt, you may disable the following
rules only if you are invoking/instantiating existing code modules.

- [`no-new`](https://eslint.org/docs/rules/no-new)
- [`class-method-use-this`](https://eslint.org/docs/rules/class-methods-use-this)

NOTE: **Note:**
Disable these rules on a per-line basis. This makes it easier to refactor
in the future. E.g. use `eslint-disable-next-line` or `eslint-disable-line`.

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

Our code is automatically formatted with [Prettier](https://prettier.io) to follow our style guides. Prettier is taking care of formatting .js, .vue, and .scss files based on the standard prettier rules. You can find all settings for Prettier in `.prettierrc`.

### Editor

The easiest way to include prettier in your workflow is by setting up your preferred editor (all major editors are supported) accordingly. We suggest setting up prettier to run automatically when each file is saved. Find [here](https://prettier.io/docs/en/editors.html) the best way to set it up in your preferred editor.

Please take care that you only let Prettier format the same file types as the global Yarn script does (.js, .vue, and .scss). In VSCode by example you can easily exclude file formats in your settings file:

```
  "prettier.disableLanguages": [
      "json",
      "markdown"
  ],
```

### Yarn Script

The following yarn scripts are available to do global formatting:

```
yarn prettier-staged-save
```

Updates all currently staged files (based on `git diff`) with Prettier and saves the needed changes.

```
yarn prettier-staged
```

Checks all currently staged files (based on `git diff`) with Prettier and log which files would need manual updating to the console.

```
yarn prettier-all
```

Checks all files with Prettier and logs which files need manual updating to the console.

```
yarn prettier-all-save
```

Formats all files in the repository with Prettier. (This should only be used to test global rule updates otherwise you would end up with huge MR's).

The source of these Yarn scripts can be found in `/scripts/frontend/prettier.js`.

#### Scripts during Conversion period

```
node ./scripts/frontend/prettier.js check-all ./vendor/
```

This will go over all files in a specific folder check it.

```
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
}
```
