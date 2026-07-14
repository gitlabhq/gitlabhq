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

- All feature flags are enabled by default in the test environment (regardless of the `default_enabled:` value in the YAML definition), so DO NOT stub a flag to `true` to reach its enabled path — the only exception is a flag explicitly disabled in `spec/spec_helper.rb`, where stubbing to `true` is warranted
- Use `stub_feature_flags(flag: false)` to test the disabled code path

### Spec File Paths

- DO NOT create a new spec file in a subdirectory when a spec already exists at the canonical path (e.g., modify `spec/requests/api/pages_spec.rb`, DO NOT create `spec/requests/api/pages/pages_spec.rb`)
- DO NOT remove existing shared examples when adding or fixing coverage; extend them or add new examples alongside

### Test Design

- Use shared examples to reduce duplication across specs
- Write error-handling tests for security-sensitive operations
- Write input-validation tests for user-facing endpoints
- Follow the testing pyramid: most tests at the unit level, fewer at the integration/system level

### Deterministic Assertions

- When asserting on a collection where order does not matter, use `match_array` instead of `eq` or `match` to avoid dataset-specific flakiness
- DO NOT call `.first`, `.last`, or `.take` on an ActiveRecord relation without an explicit `.order(...)` — PostgreSQL does not guarantee row order without ORDER BY, which causes dataset-specific flaky tests
- When using `Faker` or random values, ensure the test handles any value the generator can produce; if the test depends on a specific format, use a hardcoded value instead
