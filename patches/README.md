# Patches

This directory contains patches that are applied to our `node_modules`
dependencies by [`patch-package`](https://www.npmjs.com/package/patch-package).

The patches are applied automatically after every `yarn install` via the
`postinstall` script (see `scripts/frontend/postinstall.js`), which runs
`patch-package`.

> **Note:** Do not delete this file. `postinstall` aborts if it is missing,
> which catches cases where the `patches/` directory was not copied (e.g. in
> Docker builds). Having no `.patch` files is valid and only logs a warning, so
> keep this README in place even when the directory has no patches.

## File naming

Each patch is named after the package and version it applies to, for example:

- `package-name+1.2.3.patch` patches `package-name` at version `1.2.3`.
- `@scope+package-name+1.2.3.patch` patches the scoped package
  `@scope/package-name` at version `1.2.3`.
- `package-name+1.2.3+001+description.patch` adds a trailing sequence number and
  description, used when a single package needs multiple patches.

## Creating or updating a patch

See [our documentation](https://docs.gitlab.com/development/fe_guide/dependencies/#patching-dependencies).
