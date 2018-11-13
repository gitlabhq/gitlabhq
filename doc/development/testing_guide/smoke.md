# Smoke Tests

It is imperative in any testing suite that we have Smoke Tests. In short, smoke
tests will run quick sanity end-to-end functional tests from GitLab QA and are
designed to run against the specified environment to ensure that basic
functionality is working.

Currently, our suite consists of this basic functionality coverage:

- User Login (Standard Auth)
- Project Creation
- Issue Creation
- Merge Request Creation

Smoke tests have the `:smoke` RSpec metadata.

---

[Return to Testing documentation](index.md)
