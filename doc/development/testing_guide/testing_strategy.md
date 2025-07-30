---
stage: none
group: unassigned
info: ''
description: GitLab development guidelines - testing strategy
title: GitLab Testing Strategy
---

## Core Principles

**Fast Feedback**
Prioritize speed by running the most relevant tests first—fail fast, fix fast.

**Progressive Testing**
Start narrow, expand wide. Build confidence through incremental coverage.

**Resource Efficiency**
Every test should earn its keep. No duplication, no waste.

**Clear Ownership**
Every test suite needs an owner. Undefined responsibility leads to decay.

**Test Stability**
If a test can't reliably block a merge, deployment, or release, it shouldn't exist. Fix it or delete it.

## Test Suite Placement Guidelines

{{< alert type="note" >}}

Please see [testing levels](testing_levels.md) for detailed information on the test pyramid and [pipeline tiers](../pipelines/_index.md#pipeline-tiers) for understanding merge request pipeline tiers.

{{< /alert >}}

| Test Type | Purpose | When to Run | Blocking |
|-----------|---------|-------------|----------|
| **Unit Tests** | Validate individual components in isolation | All MR pipelines (predictive in Tier 1, full suite in Tier 2+) | Yes |
| **Integration Tests** | Verify interactions across components | Tier 2+ MRs, stable branches, deployments | Yes in Tier 2+ |
| **System/Feature Tests** | Validate a single feature functionality via UI | Tier 2+ MRs, stable branches | Yes in Tier 2+ |
| **End-to-end (E2E) Tests** | Validate full critical user journey | • Smoke: Deploy pipelines, feature flag toggles<br>• Full: Tier 3 MRs, scheduled pipelines | Yes in Tier 3, Smoke tests block deployments |

## Pipeline Type Requirements

### Merge Request Pipelines

| Tier | Frontend Changes | Backend Changes | Database Changes |
|------|-----------------|-----------------|------------------|
| **Tier 1** | Jest predictive only | RSpec predictive only | Migration tests + predictive |
| **Tier 2** | Full Jest suite + selective E2E | Full RSpec unit/integration + selective E2E | Full test suite |
| **Tier 3** | Full Jest + E2E | Full RSpec + E2E | Full suite + E2E |

### Deployment Pipelines

| Stage | Required Tests | Blocking |
|-------|---------------|----------|
| Staging | E2E smoke suite | ✅ |
| Canary | E2E smoke suite | ✅ |
| Production | Post-deploy smoke | ❌ |

### Stable/Security Branches

| Pipeline Type | Frontend | Backend | Database | E2E |
|---------------|----------|---------|----------|-----|
| **Backport MRs** | Full Jest suite | Full RSpec unit/integration | Migration, DB schema check |  Full suite on Omnibus and GDK |
| **Stable/[Security Branches](https://gitlab.com/gitlab-org/security/gitlab)** (post-merge) | Jest unite/integration | RSpec unit/integration/system | Migration and background migration tests| None |

## Development Workflow

### Adding a New Test

**Test Type Selection**
Start at the lowest level possible: Unit → Integration → System → E2E.

**Coverage Assessment**
Scan existing tests before writing new ones. Don't test the same thing twice.

**Suite Placement**
Match your test to the correct suite and stage. Follow established patterns.

**Default to Blocking**
New tests _block by default_. Non-blocking tests are the exception, not the rule.

### Modifying Test Execution in Pipeline

**Shift Left**
Move tests earlier in the pipeline whenever possible. Faster feedback saves time.

**Preserve Blocking Status**
Once a test blocks at the right stage, it stays blocking. Demotion requires strong justification.

**Document Impact**
Every change to test execution patterns needs an impact assessment. No silent modifications.

## Maintenance and Monitoring

Teams should establish regular practices to maintain test suite health:

**Flaky and quarantined tests**
Review regularly, fix or remove immediately. See [unhealthy tests](unhealthy_tests.md) for details.

**Test suite health**
Periodically assess test suite performance and identify redundant coverage.
