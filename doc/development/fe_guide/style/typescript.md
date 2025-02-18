---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: TypeScript
---

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

## Recommendations

### Setup ESLint and TypeScript configuration

When setting up a new TypeScript project, configure strict type-safety rules for
ESLint and TypeScript. This ensures that the project remains as type-safe as possible.

The [GitLab Workflow Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
project is a good model for a TypeScript project's boilerplate and configuration.
Consider copying the `tsconfig.json` and `.eslintrc.json` from there.

For `tsconfig.json`:

- Use [`"strict": true`](https://www.typescriptlang.org/tsconfig/#strict).
  This enforces the strongest type-checking capabilities in the project and
  prohibits overriding type-safety.
- Use [`"skipLibCheck": true`](https://www.typescriptlang.org/tsconfig/#skipLibCheck).
  This improves compile time by only checking references `.d.ts`
  files as opposed to all `.d.ts` files in `node_modules`.

For `.eslintrc.json` (or `.eslintrc.js`):

- Make sure that TypeScript-specific parsing and linting are placed in an `overrides`
  for `**/*.ts` files. This way, linting regular `.js` files
  remains unaffected by the TypeScript-specific rules.
- Extend from [`plugin:@typescript-eslint/recommended`](https://typescript-eslint.io/rules/?supported-rules=recommended)
  which has some very sensible defaults, such as:
  - [`"@typescript-eslint/no-explicit-any": "error"`](https://typescript-eslint.io/rules/no-explicit-any/)
  - [`"@typescript-eslint/no-unsafe-assignment": "error"`](https://typescript-eslint.io/rules/no-unsafe-assignment/)
  - [`"@typescript-eslint/no-unsafe-return": "error"`](https://typescript-eslint.io/rules/no-unsafe-return/)

### Avoid `any`

Avoid `any` at all costs. This should already be configured in the project's linter,
but it's worth calling out here.

Developers commonly resort to `any` when dealing with data structures that cross
domain boundaries, such as handling HTTP responses or interacting with untyped
libraries. This appears convenient at first. However, opting for a well-defined type (or using
`unknown` and employing type narrowing through predicates) carries substantial benefits.

```typescript
// Bad :(
function handleMessage(data: any) {
  console.log("We don't know what data is. This could blow up!", data.special.stuff);
}

// Good :)
function handleMessage(data: unknown) {
  console.log("Sometimes it's okay that it remains unknown.", JSON.stringify(data));
}

// Also good :)
function isFooMessage(data: unknown): data is { foo: string } {
  return typeof data === 'object' && data && 'foo' in data;
}

function handleMessage(data: unknown) {
  if (isFooMessage(data)) {
    console.log("We know it's a foo now. This is safe!", data.foo);
  }
}
```

### Avoid casting with `<>` or `as`

Avoid casting with `<>` or `as` as much as possible.

Type casting explicitly circumvents type-safety. Consider using
[type predicates](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates).

```typescript
// Bad :(
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

There's some rare cases this might be acceptable (consider
[this test utility](https://gitlab.com/gitlab-org/gitlab-web-ide/-/blob/3ea8191ed066811caa4fb108713e7538b8d8def1/packages/vscode-extension-web-ide/test-utils/createFakePartial.ts#L1)). However, 99% of the
time, there's a better way.

### Prefer `interface` over `type` for new structures

Prefer declaring a new `interface` over declaring a new `type` alias when defining new structures.

Interfaces and type aliases have a lot of cross-over, but only interfaces can be used
with the `implements` keyword. A class is not able to `implement` a `type` (only an `interface`),
so using `type` would restrict the usability of the structure.

```typescript
// Bad :(
type Fooer = {
  foo: () => string;
}

// Good :)
interface Fooer {
  foo: () => string;
}
```

From the [TypeScript guide](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#differences-between-type-aliases-and-interfaces):

> If you would like a heuristic, use `interface` until you need to use features from `type`.

### Use `type` to define aliases for existing types

Use type to define aliases for existing types, classes or interfaces. Use
the TypeScript [Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
to provide transformations.

```typescript
interface Config = {
  foo: string;

  isBad: boolean;
}

// Bad :(
type PartialConfig = {
  foo?: string;

  isBad?: boolean;
}

// Good :)
type PartialConfig = Partial<Config>;
```

### Use union types to improve inference

```typescript
// Bad :(
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
interface FooBar { type: 'bar', bar: string }
interface FooZed { type: 'zed', zed: string }
type Foo = FooBar | FooZed;

const doThing = (foo: Foo) => {
  if (foo.type === 'bar') {
    // No casting needed :) - TS knows we are FooBar now
    console.log(foo.bar);
  }
}
```

## Future plans

- Shared ESLint configuration to reuse across TypeScript projects.

## Related topics

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [TypeScript notes in GitLab Workflow Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/developer/coding-guidelines.md?ref_type=heads#typescript)
