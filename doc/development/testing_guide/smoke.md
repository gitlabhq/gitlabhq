# Smoke Tests

It is imperative in any testing suite that we have Smoke Tests. In short, smoke
tests will run quick sanity end-to-end functional tests from GitLab QA and are
designed to run against the specified environment to ensure that basic
functionality is working.

Currently, our suite consists of this basic functionality coverage:

- User standard authentication
- SSH Key creation and addition to a user
- Project simple creation
- Project creation with Auto-DevOps enabled
- Issue creation
- Merge Request creation
- Snippet creation

Smoke tests have the `:smoke` RSpec metadata.

See [End-to-end Testing](end_to_end/index.md) for more details about
end-to-end tests.

---

[Return to Testing documentation](index.md)
