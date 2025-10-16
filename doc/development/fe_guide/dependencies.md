---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Frontend dependencies
---

We use [yarn@1](https://classic.yarnpkg.com/lang/en/) to manage frontend dependencies.

There are a few exceptions in the GitLab repository, stored in `vendor/assets/`.

## What are production and development dependencies?

These dependencies are defined in two groups within `package.json`, `dependencies` and `devDependencies`.
For our purposes, we consider anything that is required to compile our production assets a "production" dependency.
That is, anything required to run the `webpack` script with `NODE_ENV=production`.
Tools like `eslint`, `jest`, and various plugins and tools used in development are considered `devDependencies`.
This distinction is used by omnibus to determine which dependencies it requires when building GitLab.

Exceptions are made for some tools that we require in the
`compile-production-assets` CI job such as `webpack-bundle-analyzer` to analyze our
production assets post-compile.

## Updating dependencies

See the main [Dependencies](../dependencies.md) page for general information about dependency updates.

## Patching dependencies

Patches can be applied to dependencies with [`patch-package`](https://github.com/ds300/patch-package). Patches are stored under the [`patches/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/patches) directory.

### What warrants a patch

Dependencies should only be patched as a last resort, as they are technical
debt. Here are some acceptable reasons for patching a dependency:

- it is unmaintained, so there isn't an upstream version which includes the change;
- there is a vulnerability identified that we cannot wait for upstream to fix;
- to change aspects that are specific to GitLab and would or could not be changed upstream.

### Patching a dependency

1. If possible, add tests that ensure the patch achieves the desired behavior.
1. Edit the relevant file directly in `node_modules`. Ensure to include a comment in your edit which details:
   - why the patch is needed,
   - when it can be removed,
   - a link to an issue or merge request which describes the problem that the patch solves.
1. Generate the patch from your edit by running `yarn patch-package <package-name>`.
1. Add the patch with `git add patches/`.
1. Commit as usual.

### Updating a patch

Patches are specific to the particular version of the dependency. When that dependency is updated, any patches for it must also be updated.

If the patch applies cleanly:

1. Run `yarn patch-package <package-name>` to rename the patch to apply to the new version.
1. Run `git add patches/`.
1. Commit as usual.

If the patch does not apply cleanly, determine whether the patch is still needed.

- If so, [create](#patching-a-dependency) a new patch from scratch.
- If not, delete the patch file, and commit.

{{< alert type="warning" >}}

Do not delete patches or parts of patches without confirming that they are no longer needed. If in doubt, ask the person who introduced the patch.

{{< /alert >}}
