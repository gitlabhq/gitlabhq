---
name: dependency-management-auto-remediation
description: Add a package manager/ecosystem (e.g. npm, pip, go, sbt) to dependency management security auto remediation. Use when extending auto remediation beyond the currently supported package managers.
---

# Add an ecosystem to auto remediation

Auto remediation opens merge requests to bump vulnerable dependencies, one
package manager at a time. Adding an ecosystem is mostly small config edits, but
two things are NOT obvious and are where it actually breaks. Read the guardrails
before writing code.

## Mechanical changes

All service code is under `ee/app/services/dependency_management/security_update/`.

1. In `scheduler_service.rb`, add the GitLab package manager name to the
   `SUPPORTED_PACKAGE_MANAGERS` array. This value is matched against
   `sbom_occurrences.package_manager`, so it must be exactly what dependency
   scanning stores for that ecosystem (verify with Guardrail 1). The scheduler
   already iterates this array, so no other scheduler logic changes.

2. In `job_builder.rb`, add an entry to the `PACKAGE_MANAGER_MAPPING` hash,
   mapping the GitLab package manager name to the orchestrator ecosystem name
   (often identical).

3. If the ecosystem needs name normalization (Guardrail 1), handle it in
   `JobBuilder#dependency_name`. Ecosystems that store names as `group/artifact`
   but the updater identifies as `group:artifact` are listed in
   `COLON_SEPARATED_ECOSYSTEMS`.

4. Add a row to the supported package managers table in
   `doc/user/application_security/remediate/auto_remediation.md` (Language,
   Package Manager, manifest file names).

5. Add/extend specs under
   `ee/spec/services/dependency_management/security_update/`
   (`scheduler_service_spec.rb`, `job_builder_spec.rb`).

6. Add a changelog trailer `Changelog: added` and `EE: true` (user-facing,
   EE-only change).

## Guardrail 1 — dependency-name format (the silent failure)

The updater identifies a dependency by name. If the name GitLab sends differs
from what the updater parses from the manifest, the updater filters it out and
**no MR opens** — with no error. Unit tests pass while the feature does nothing.

GitLab stores some component names differently than the updater expects. For
example Maven/Gradle are stored as `group/artifact`, but the updater
(dependabot) wants `group:artifact`, so `JobBuilder#dependency_name` converts
them. The name is built in `ee/lib/gitlab/ci/reports/sbom/component.rb`
(`[purl.namespace, purl.name].join('/')`) and split back in
`ee/app/models/sbom/occurrence.rb` (`name.rpartition('/')`). The package
manager → purl type mapping is in `ee/lib/sbom/purl_type/converter.rb`.

For a new ecosystem: after a real scan, check the stored format and the format
the updater expects. If they differ, normalize in `JobBuilder`. Inspect real
data with:

```ruby
project = Project.find_by_full_path('<ns>/<project>')
project.sbom_occurrences.distinct.pluck(:package_manager)
project.sbom_occurrences.first.component_name
```

## Guardrail 2 — validate end to end (do not skip)

Unit tests CANNOT catch a name-format mismatch, because the updater runs in a
separate container. Run the whole flow before declaring it done:

1. Create a project with a manifest pinning a known vulnerable dependency whose
   fix is a **patch or minor** bump. Major-only fixes are intentionally skipped,
   so they look like a failure but are expected.
2. Use the v2 dependency scanning template
   (`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`) — it emits the SBOM this feature
   consumes, and its `.pre` resolution jobs handle manifests without a lockfile.
3. Enable the flag for the project (project must be Ultimate):

   ```ruby
   Feature.enable(:dependency_management_auto_remediation, Project.find_by_full_path('<ns>/<project>'))
   ```

4. Run a pipeline; confirm occurrences are ingested with the expected
   `package_manager` (Guardrail 1 command above).
5. Trigger the scheduler in a fresh process (picks up code without a Sidekiq
   restart) and confirm an MR opens bumping the dependency:

   ```ruby
   DependencyManagement::SecurityUpdate::SchedulerService.execute(
     project: Project.find_by_full_path('<ns>/<project>')
   )
   ```

A silent failure (no MR; "filtered out" / "0 to update" in the updater logs)
almost always means a name mismatch — return to Guardrail 1.

## Done checklist

- [ ] `SUPPORTED_PACKAGE_MANAGERS` + `PACKAGE_MANAGER_MAPPING` updated
- [ ] Dependency-name format verified, converted in `JobBuilder` if needed
- [ ] Docs table updated
- [ ] Specs added/extended
- [ ] Changelog `added` + `EE: true`
- [ ] Validated end to end — an MR actually opened
