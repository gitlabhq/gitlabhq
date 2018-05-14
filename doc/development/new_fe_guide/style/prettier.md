# Formatting with Prettier

Our code is automatically formatted with [Prettier](https://prettier.io) to follow our style guides. Prettier is taking care of formatting .js, .vue, and .scss files based on the standard prettier rules. You can find all settings for Prettier in `.prettierrc`.

## Editor

The easiest way to include prettier in your workflow is by setting up your preferred editor (all major editors are supported) accordingly. We suggest setting up prettier to run automatically when each file is saved. Find [here](https://prettier.io/docs/en/editors.html) the best way to set it up in your preferred editor. 

Please take care that you only let Prettier format the same file types as the global Yarn script does (.js, .vue, and .scss). In VSCode by example you can easily exclude file formats in your settings file:

```
  "prettier.disableLanguages": [
      "json",
      "markdown"
  ],
```

## Yarn Script

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
