### CE/EE Code Separation

- CE code (outside `ee/`) must not directly reference `EE::` namespaced classes
- EE extensions use `prepend_mod` pattern in CE files
- If CE code needs EE-aware behavior, use `prepend_mod` hooks or `Gitlab.ee?` guards
- Flag direct references to `EE::` namespaced classes in CE code (prevents FOSS build failures)

### ActiveRecord Callbacks

- Callbacks should only modify data on the current model, not associated records
- Question if callback logic should be in a service layer instead
- Flag callbacks with side effects (external API calls, updating other records, complex business logic)
- Flag bulk operations on associated records in callbacks (performance concern as associations grow)
- Acceptable uses: data normalization on current model only (trimming whitespace, setting defaults)

### Authorization

- Before changing authorization logic, read the existing `authorize!` / `authorize_admin!` call and verify what permission it currently enforces; the required fix may be documentation- or test-only with no code change needed
