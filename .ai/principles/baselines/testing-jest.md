## Frontend Testing Principles

### Test structure

Follow BDD (Behaviour-Driven Development) conventions: use `describe` blocks to define the context or state the system is in, `it` blocks to declare the specific behaviour being verified, and `beforeEach` to set up shared state. Group related tests together under a shared `describe` block.

```js
// Bad
it('does Y when X', () => { ... })
```

```js
// Good
describe('when X', () => {
  beforeEach(() => { /* set up X */ });
  it('does Y', () => { ... });
});
```

### Path Helpers

- Do not mock JavaScript path helpers imported from `app/assets/javascripts/lib/utils/path_helpers` or `ee/app/assets/javascripts/lib/utils/path_helpers` in Jest tests. You can assume that `gon.current_organization.has_scoped_paths` will be `false` and that `window.gon?.relative_url_root` will be `''` in Jest tests. There may be existing tests for the `relative_url_root` functionality, for these you can use `useConfigurePathHelpers` in `spec/frontend/__helpers__/configure_path_helpers.js`.
