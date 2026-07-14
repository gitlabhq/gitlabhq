---
title: Organizations platform release status
---

<!-- This file is generated from config/organizations_release.yml. Do not edit it manually. -->
<!-- Regenerate it with: bin/rake gitlab:organizations:release:docs -->

Every organization flag and its current stage are listed below.
The stage determines who can use a flag and whether it can be disabled.

## Release stages

| Stage | Audience | Description |
|-------|----------|-------------|
| Experimental | Organizations team and selected peers | In flux. Being designed and built. No stability contract. |
| Beta | GitLab Team Members and opted-in customers | Ready for real world use. No SLA. May change. |
| LA (25%) | Customers, 25% rollout | Trusted as working. Rolled out to 25% of GitLab.com. |
| LA (50%) | Customers, 50% rollout | Trusted as working. Rolled out to 50% of GitLab.com. |
| LA (75%) | Customers, 75% rollout | Trusted as working. Rolled out to 75% of GitLab.com. |
| LA (100%) | All GitLab.com customers | Trusted as working. Rolled out to 100% of GitLab.com. |
| GA | Everyone | Generally available on all platforms. Flag retained as a handbrake (inert on GitLab Dedicated). |

## Organization flags

| Flag | Stage | Description |
|------|-------|-------------|
| `org_admin_area` | Experimental | Organization admin area for organization owners. |
