### Branch Coverage

- For conditional logic (`||`, `&&`, `if/else`, `case`), verify each branch has test coverage
- For helper methods, ensure unit specs exist (not just integration coverage)
- For ActiveRecord callbacks (`before_validation`, `before_save`), ensure unit specs test the callback behavior specifically

### Edge Case Coverage

- Flag missing edge case coverage for:
  - Nil/empty values
  - Boundary conditions
  - Fallback logic (`||` operators)
  - Error states

### Feature Flags in Tests

- DO NOT use `stub_feature_flags(flag: true)` — feature flags are enabled by default in the test environment, so stubbing to `true` is redundant and misleading
- Only use `stub_feature_flags(flag: false)` to test the disabled code path
- For the enabled case, write tests without any feature flag stub — the default state is already enabled

### Spec File Paths

- DO NOT create a new spec file in a subdirectory when a spec already exists at the canonical path (e.g., modify `spec/requests/api/pages_spec.rb`, DO NOT create `spec/requests/api/pages/pages_spec.rb`)
- DO NOT remove existing shared examples when adding or fixing coverage; extend them or add new examples alongside
