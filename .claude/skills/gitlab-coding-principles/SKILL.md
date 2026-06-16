---
name: gitlab-coding-principles
description: Load all relevant GitLab development principles before planning or implementing. Evaluates every principle group to ensure cross-domain coverage.
---

# Load Project Principles

Evaluate ALL groups below and load principles from EVERY group that applies to
your task. Most tasks span multiple groups (e.g., a model change may need
Backend, Database, and Testing principles). DO NOT stop after the first group.
When your task involves database queries, scopes, or data access patterns,
ALWAYS load Database principles regardless of which files you are editing.

**Database:**
- **Database fundamentals (model queries, batching, sharding, partitioning, N+1)**: Read .ai/principles/distilled/database-fundamentals.md *(load for any database work)*
- **Database migration patterns and zero-downtime safety**: Read .ai/principles/distilled/database-migrations.md *(also load: .ai/principles/distilled/database-fundamentals.md)*
- **Column types, constraints, indexes, naming conventions**: Read .ai/principles/distilled/database-schema.md *(also load: .ai/principles/distilled/database-fundamentals.md)*
- **SQL performance, transactions, batching**: Read .ai/principles/distilled/database-queries.md *(also load: .ai/principles/distilled/database-fundamentals.md)*
- **ClickHouse database concerns**: Read .ai/principles/distilled/clickhouse.md *(also load: .ai/principles/distilled/database-fundamentals.md)*

**Cells:**
- **Cells architecture sharding keys, organization data ownership, routable requests, and cell isolation when adding tables or customer-owned resources**: Read .ai/principles/distilled/cells-fundamentals.md *(load for any cells work)*
- **Cells globally-unique attribute claims (Cells::Claimable), claim rollout lifecycle, and feature flags for cross-cell uniqueness**: Read .ai/principles/distilled/cells-claims.md *(also load: .ai/principles/distilled/cells-fundamentals.md)*

**Security:**
- **Security vulnerabilities and secure coding**: Read .ai/principles/distilled/security.md
- **Authentication, authorization, token handling, OAuth, SAML, identity linking, composite identity, session management, 2FA, MFA, password management**: Read .ai/principles/distilled/authentication.md

**Permissions:**
- **Where to check permissions, naming conventions, role definitions**: Read .ai/principles/distilled/permissions-fundamentals.md *(load for any permissions work)*
- **Granular PAT (GPAT) compliance for GraphQL types and mutations**: Read .ai/principles/distilled/permissions-graphql-gpat.md *(also load: .ai/principles/distilled/permissions-fundamentals.md)*
- **Granular PAT (GPAT) compliance for REST endpoints and job tokens**: Read .ai/principles/distilled/permissions-rest-gpat.md *(also load: .ai/principles/distilled/permissions-fundamentals.md)*

**Code Review:**
- **General code review practices and acceptance checklist**: Read .ai/principles/distilled/code-review.md

**Backend:**
- **Ruby/Rails style, logging, common pitfalls**: Read .ai/principles/distilled/backend-ruby.md *(load for any backend work)*
- **Service patterns, abstractions, design conventions**: Read .ai/principles/distilled/backend-architecture.md *(also load: .ai/principles/distilled/backend-ruby.md)*
- **EE/CE separation, licensing, code placement**: Read .ai/principles/distilled/backend-ee.md *(also load: .ai/principles/distilled/backend-ruby.md)*

**API:**
- **REST API design and conventions**: Read .ai/principles/distilled/rest-api.md
- **GraphQL API design and conventions**: Read .ai/principles/distilled/graphql.md

**Workers:**
- **Sidekiq worker design and reliability**: Read .ai/principles/distilled/workers.md

**CI/CD:**
- **GitLab CI/CD internals — adding pipeline configuration keywords (Ci::Config::Entry classes, feature-flag gating, JSON schema) and creating CI routing/partitioned tables. NOTE this is about GitLab's own CI implementation, not authoring a project's .gitlab-ci.yml**: Read .ai/principles/distilled/cicd-internals.md

**Frontend:**
- **Vue.js components, state management, patterns**: Read .ai/principles/distilled/frontend-vue.md *(load for any frontend work)*
- **CSS/SCSS, Tailwind, dark mode**: Read .ai/principles/distilled/frontend-style.md *(also load: .ai/principles/distilled/frontend-vue.md)*
- **HAML templates, ViewComponents, Pajamas**: Read .ai/principles/distilled/frontend-haml.md *(also load: .ai/principles/distilled/frontend-vue.md)*
- **Frontend accessibility patterns and requirements**: Read .ai/principles/distilled/frontend-a11y.md *(also load: .ai/principles/distilled/frontend-vue.md)*

**Testing:**
- **RSpec patterns, factories, shared examples**: Read .ai/principles/distilled/qa-rspec.md
- **Jest, jsdom, Vue Test Utils patterns**: Read .ai/principles/distilled/qa-jest.md

**Performance:**
- **Performance and scalability**: Read .ai/principles/distilled/performance.md

**Documentation:**
- **Documentation style and completeness**: Read .ai/principles/distilled/documentation.md

**Feature Flags:**
- **Feature flag usage and lifecycle**: Read .ai/principles/distilled/feature-flags.md

**Analytics:**
- **Analytics instrumentation and metrics**: Read .ai/principles/distilled/analytics.md

- **Code style or linting**: Read .ai/code-style.md
- **Git, commits, or branches**: Read .ai/git.md
- **CI/CD pipelines or `.gitlab-ci.yml`**: Read .ai/ci-cd.md
