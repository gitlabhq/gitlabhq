---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Frontend package boundaries
---

Every top-level folder under `app/assets/javascripts` is a package. `config/dependency_cruiser.mjs`
enforces which packages may import which, so that shared code stays reusable and features stay
separable.

A package spans both editions. `app/assets/javascripts/ci/` and `ee/app/assets/javascripts/ci/` are
the same package, so EE code that imports its CE counterpart is internal to the package and allowed.

`config/frontend_packages.mjs` defines three kinds of package.

| Kind | Members | May import | May be imported by |
| ---- | ------- | ---------- | ------------------ |
| Shared layer | The `SHARED_LAYER` list, such as `vue_shared`, `lib`, and `graphql_shared` | Other shared-layer packages only | Anything |
| Feature | Every other folder, such as `ci`, `boards`, and `work_items` | Shared-layer packages and other features | Features and entrypoints |
| Entrypoint | The `ENTRYPOINTS` list: `pages` and `entrypoints` | Anything | Nothing |

## Rules

Two rules enforce the table above. Both run in CI through `scripts/static-analysis`, and on
`git push` through the `dependency-rules` hook in `lefthook.yml`.

`no-shared-layer-imports-from-features` stops a shared-layer package from importing feature code. A
shared-layer module can be imported from anywhere, so when it reaches into a feature, every consumer
of that module depends on that feature as well. The shared module then cannot be reused without the
feature, and neither can be extracted.

`no-imports-from-entrypoints` stops anything from importing an entrypoint. The `pages` folder
mirrors the Rails controller and action tree, and `entrypoints` holds webpack entry files. Both
exist to wire other packages together, so nothing depends on them.

## Fix a violation

To fix `no-shared-layer-imports-from-features`, move the value the shared module needs into the
shared layer, or move the module out of the shared layer and into the feature it belongs to. Prefer
the second option when the module is only used by one feature.

Check what the value means before you move it. A string that appears in two packages is not
necessarily the same concept, and merging two unrelated concepts into one shared constant couples
the packages that use them.

To fix `no-imports-from-entrypoints`, move the shared code out of `pages` into a package, then
import it from both the entrypoint and the other consumer.

## Baselines

Violations that already existed when a rule was introduced are listed in
`.dependency_cruiser_todo/`, one file per rule. Each entry names a single file, so the rules fail
only on new violations.

To see the real violation count, ignore the baselines. No CI job reports this number, so run it
yourself when you want it:

```shell
REVEAL_DEPS_TODO=1 yarn deps:check:all
```

After you fix violations, regenerate the affected list so the count goes down:

```shell
node scripts/frontend/generate_dependency_cruiser_todo.mjs no-shared-layer-imports-from-features
```

Run the script without an argument to regenerate every list. The script reads the rules from
`config/dependency_cruiser.mjs`, so a baseline cannot drift from the rule CI enforces.

## Check your changes

`yarn deps:check` accepts files or folders:

```shell
yarn deps:check app/assets/javascripts/vue_shared
```
