# Domains

This directory holds bounded-context domains extracted from the monolith. Each domain lives in `domains/<name>/`. Register the domain's namespace in `config/bounded_contexts.yml`.

## Layout

A domain mirrors the top-level repo layout: `app/`, `lib/` and `spec/` (including `spec/factories` and `spec/support`). EE code goes in `domains/<name>/ee/` with the same layout (`ee/app`, `ee/lib`, `ee/spec`).

Moved files keep their path relative to the Zeitwerk root. Constant names do not change when code moves into a domain.

## Loading

- `domains/*/app` and `domains/*/lib` are added to the autoload paths in `config/application.rb`.
- `domains/*/ee/...` is loaded only in EE. EE domain code is removed from FOSS builds.
- The test suite loads factories from `domains/*/spec/factories` (and `domains/*/ee/spec/factories` in EE) and support files from `domains/*/spec/support`. Domain specs run in CI.
- `Gitlab::SidekiqConfig` picks up workers in `domains/*/app/workers` and `domains/*/ee/app/workers`.
