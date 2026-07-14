---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Tooling
---

## ESLint

We use ESLint to encapsulate and enforce frontend code standards. Our configuration may be found in the [`gitlab-eslint-config`](https://gitlab.com/gitlab-org/gitlab-eslint-config) project.

You can set the environment variable `REVEAL_ESLINT_TODO` to `1` in your environment (and your IDE's) to see pending eslint todo's that were excluded by `.eslint_todo/*.mjs`. This allows you to reveal existing `eslint` exceptions to fix them along your daily work.

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

> [!warning]
> Limit use to global rule updates. Otherwise, the changes can lead to huge Merge Requests.

### Disabling ESLint in new files

Do not disable ESLint when creating new files. Existing files may have existing rules
disabled due to legacy compatibility reasons but they are in the process of being refactored.

Do not disable specific ESLint rules. To avoid introducing technical debt, you may disable the following
rules only if you are invoking/instantiating existing code modules.

- [`no-new`](https://eslint.org/docs/latest/rules/no-new)
- [`class-method-use-this`](https://eslint.org/docs/latest/rules/class-methods-use-this)

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

### Generating todo files

When enabling a new ESLint rule that uncovers many offenses across the codebase, it might be easier
to generate a todo file to temporarily ignore those offenses. This approach has some pros and cons:

**Pros**:

- A single source of truth for all the files that violate a specific rule. This can make it easier
  to track the work necessary to pay the incurred technical debt.
- A smaller changeset when initially enabling the rule as you don't need to modify every offending
  file.

**Cons**:

- Disabling the rule for entire files means that more offenses of the same type can be introduced in
  those files.
- When fixing offenses over multiple concurrent merge requests, conflicts can often arise in the todo files,
  requiring MR authors to rebase their branches.

To generate a todo file, run the `scripts/frontend/generate_eslint_todo_list.mjs` script:

```shell
node scripts/frontend/generate_eslint_todo_list.mjs <rule_name>
```

For example, generating a todo file for the `vue/no-unused-properties` rule:

```shell
node scripts/frontend/generate_eslint_todo_list.mjs vue/no-unused-properties
```

This creates an ESLint configuration in `.eslint_todo/vue-no-unused-properties.mjs` which gets
automatically added to the global configuration.

Once a todo file has been created for a given rule, make sure to plan for the work necessary to
address those violations. Todo files should be as short lived as possible. If some offenses cannot
be addressed, switch to inline ignores by [disabling ESLint for a single violation](#disabling-eslint-for-a-single-violation).

When all offending files have been fixed, the todo file should be removed along with the `export`
statement in `.eslint_todo/index.mjs`.

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
 *For example: "?one=1&two=2" into {one: 1, two: 2}
 * @deprecated Please use `queryToObject` instead. See https://gitlab.com/gitlab-org/gitlab/-/issues/283982 for more information
 */
export function queryToObject(query, options = {}) {
  ...
}
```

It is strongly encouraged that you:

- Put in an **alternative path for developers** looking to use this function.
- **Provide a link to the issue** that tracks the migration process.

> [!note]
> Uses are detected if you import the deprecated function into another file. They are not detected when the function is used in the same file.

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

### `vue/multi-word-component-names` is disabled in my file

Single name components are discouraged by the
[Vue style guide](https://vuejs.org/style-guide/rules-essential.html#use-multi-word-component-names).

They are problematic because they can be confused with other HTML components: We could name a
component `<table>` and it would stop rendering an HTML `<table>`.

To solve this, you should rename the `.vue` file and its references to use at least two words,
for example:

- `user/table.vue` could be renamed to `user/users_table.vue` and be imported as `UsersTable` and used with `<users-table />`.

### GraphQL schema and operations validation

We use [`@graphql-eslint/eslint-plugin`](https://www.npmjs.com/package/@graphql-eslint/eslint-plugin)
to lint GraphQL schema and operations. This plugin requires the entire schema to function properly.
It is thus recommended to generate an up-to-date dump of the schema when running ESLint locally.
You can do this by running the `./scripts/dump_graphql_schema` script.

## Formatting with Prettier

Our code is automatically formatted with [Prettier](https://prettier.io) to follow our style guides. Prettier is taking care of formatting `.js`, `.vue`, `.graphql`, and `.scss` files based on the standard prettier rules. You can find all settings for Prettier in `.prettierrc`.

### Editor

The recommended method to include Prettier in your workflow is to set up your
preferred editor (all major editors are supported) accordingly. We suggest
setting up Prettier to run when each file is saved. For instructions about using
Prettier in your preferred editor, see the [Prettier documentation](https://prettier.io/docs/en/editors.html).

Take care that you only let Prettier format the same file types as the global Yarn script does (`.js`, `.vue`, `.graphql`, and `.scss`). For example, you can exclude file formats in your Visual Studio Code settings file:

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

### VS Code Settings

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

## Trace unused Vue provides

Vue [dependency injection](vue.md#provide-and-inject) decays over time.
When a component that uses `inject` is refactored or removed, the matching `provide` entry often
stays behind, along with the `el.dataset` read, the HAML `data:` attribute, and the Ruby helper
that feed it.
The `scripts/frontend/trace_provide_inject_usage.mjs` script finds the provided keys that no
descendant injects, so you can remove the dead plumbing.
For examples of this cleanup, see merge requests
[!242664](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242664) and
[!242662](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242662).

To trace a provider file or a set of files, run the script with one or more file paths or globs.
The script requires [ripgrep](https://github.com/BurntSushi/ripgrep#installation) (`rg`) on your
`PATH` and analyzes only `.vue` and `.js` files:

```shell
node scripts/frontend/trace_provide_inject_usage.mjs <file|glob> [<file|glob>...]
```

For example, to trace a single entry point and then a whole directory (quote globs so the shell
does not expand them):

```shell
node scripts/frontend/trace_provide_inject_usage.mjs app/assets/javascripts/ci/pipeline_details/pipeline_header.js

node scripts/frontend/trace_provide_inject_usage.mjs 'app/assets/javascripts/ci/**/*.js'
```

The script prints a breakdown for each traced file and a final list of removal candidates.
Each provided key gets one of the following verdicts:

| Verdict | Action | Description |
|---------|--------|-------------|
| `REMOVABLE` | Remove it | No component injects the key anywhere, so the provide is dead. |
| `LIKELY-REMOVABLE` | Remove it, then confirm | Injectors exist, but none are reachable from this provider in the module import graph. Reachability is a heuristic that misses some dynamic imports, so confirm with the component specs or by loading the page. |
| `IN USE` | Keep it | An injector is reachable from this provider. This result is a possibility of use, not proof, because shared modules can link unrelated components. |
| `INCONCLUSIVE` | Investigate manually | A dynamic boundary, such as a `Vue.component()` global registration or an unresolved dynamic import, prevents a reliable verdict. |

To remove a key the script reports as `REMOVABLE` or `LIKELY-REMOVABLE`, work through the layers
that feed it, and stop at any layer that another consumer still uses:

1. Remove the `provide:` entry.
1. Remove the `el.dataset` read and any derived constants or imports, but only when they are
   unused elsewhere in the entry point. Keep them when the value also feeds a store, a router,
   props, or a sibling application.
1. Remove the HAML `data:` attribute, after you confirm that no other entry point reads the same
   mount element.
1. Remove the Ruby helper that builds the attribute value, after you check for other callers in
   both `app/` and `ee/app/`.
1. Update the RSpec and Jest specs that assert the removed key.

A removed provide that a descendant still injects throws an `injection not found` error at
runtime, so load the affected page or run its feature spec to confirm the removal is safe.
Scope each change to a single provider file.
