---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# TypeScript

## History with GitLab

TypeScript has been [considered](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/35),
discussed, promoted, and rejected for years at GitLab. The general
conclusion is that we are unable to integrate TypeScript into the main
project because the costs outweigh the benefits.

- The main project has **a lot** of pre-existing code that is not strongly typed.
- The main contributors to the main project are not all familiar with TypeScript.

Apart from the main project, TypeScript has been profitably employed in
a handful of satellite projects.

## Projects using TypeScript

The following GitLab projects use TypeScript:

- [`gitlab-web-ide`](https://gitlab.com/gitlab-org/gitlab-web-ide/)
- [`gitlab-vscode-extension`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
- [`gitlab-language-server-for-code-suggestions`](https://gitlab.com/gitlab-org/editor-extensions/gitlab-language-server-for-code-suggestions)
- [`gitlab-org/cluster-integration/javascript-client`](https://gitlab.com/gitlab-org/cluster-integration/javascript-client)

## Recommended configurations

The [GitLab Workflow Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main) project is a good model
for a project's TypeScript configuration. Consider copying the `.tsconfig` and `.eslintrc.json` from there.

- In `.tsconfig`, make sure [`"strict": true`](https://www.typescriptlang.org/tsconfig#strict) is set.
- In `.eslintrc.json`, make sure that TypeScript-specific parsing and linting is placed in an `overrides` for `**/*.ts` files.

## Future plans

- Shared ESLint configuration to reuse across TypeScript projects.

## Recommended patterns

### Avoid casting with `<>` or `as`

Avoid casting with `<>` or `as` as much as possible. This circumvents Type safety. Consider using
[type predicates](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates).

```typescript
// Bad
function handler(data: unknown) {
  console.log((data as StuffContainer).stuff);
}

// Good :)
function hasStuff(data: unknown): data is StuffContainer {
  if (data && typeof data === 'object') {
    return 'stuff' in data;
  }

  return false;
}

function handler(data: unknown) {
  if (hasStuff(data)) {
    // No casting needed :)
    console.log(data.stuff);
  }
  throw new Error('Expected data to have stuff. Catastrophic consequences might follow...');
}

```

### Prefer `interface` over `type` for new interfaces

Prefer interface over type declaration when describing structures.

```typescript
// Bad
type Fooer = {
  foo: () => string;
}

// Good
interface Fooer {
  foo: () => string;
}
```

### Use `type` to define aliases for existing types

Use type to define aliases for existing types, classes or interfaces. Use
the TypeScript [Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
to provide transformations.

```typescript
interface Config = {
  foo: string;

  isBad: boolean;
}

// Bad
type PartialConfig = {
  foo?: string;

  isBad?: boolean;
}

// Good
type PartialConfig = Partial<Config>;
```

### Use union types to improve inference

```typescript
// Bad
interface Foo { type: string }
interface FooBar extends Foo { bar: string }
interface FooZed extends Foo { zed: string }

const doThing = (foo: Foo) => {
  if (foo.type === 'bar') {
    // Casting bad :(
    console.log((foo as FooBar).bar);
  }
}

// Good :)
interface FooBar { type: 'bar', bar: string };
interface FooZed { type: 'zed', zed: string }
type Foo = FooBar | FooZed;

const doThing = (foo: Foo) => {
  if (foo.type === 'bar') {
    // No casting needed :) - TS knows we are FooBar now
    console.log(foo.bar);
  }
}
```

## Related topics

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [TypeScript notes in GitLab Workflow Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/developer/coding-guidelines.md?ref_type=heads#typescript)
