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

### Scripts during Conversion period

```
node ./scripts/frontend/prettier.js check-all ./vendor/
```

This will go over all files in a specific folder check it.

```
node ./scripts/frontend/prettier.js save-all ./vendor/
```

This will go over all files in a specific folder and save it.

## VSCode Settings

### Format on Save

To automatically format your files with Prettier, add the following properties to your User or Workspace Settings:

```javascript
{
  "[javascript]": {
      "editor.formatOnSave": true
  },
  "[vue]": {
      "editor.formatOnSave": true
  },
}
```

### Conflicts with Vetur Extension

There are some [runtime issues](https://github.com/vuejs/vetur/issues/950) with [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) and [the Vetur extension](https://marketplace.visualstudio.com/items?itemName=octref.vetur) for VSCode. To fix this, try adding the following properties to your User or Workspace Settings:

```javascript
{
  "prettier.disableLanguages": [],
  "vetur.format.defaultFormatter.html": "none",
  "vetur.format.defaultFormatter.js": "none",
  "vetur.format.defaultFormatter.css": "none",
  "vetur.format.defaultFormatter.less": "none",
  "vetur.format.defaultFormatter.postcss": "none",
  "vetur.format.defaultFormatter.scss": "none",
  "vetur.format.defaultFormatter.stylus": "none",
  "vetur.format.defaultFormatter.ts": "none",
}
```
