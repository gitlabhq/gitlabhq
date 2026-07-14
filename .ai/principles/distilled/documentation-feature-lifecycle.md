---
source_checksum: ab2f08e20f161210
distilled_at_sha: 9eb89263152259e883603c908db1e1cea6a1a74e
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Documentation Feature Lifecycle Principles

## Checklist

### Feature Flags — When to Document

- Document a feature behind a feature flag before it is enabled for all customers in any environment (GitLab Self-Managed, GitLab.com, or GitLab Dedicated); the developer who changes the flag state is responsible for updating the documentation.
- When a feature is disabled on GitLab Self-Managed, DO NOT list `GitLab Dedicated` as an offering in the availability details.

### Feature Flags — History Entries

- Add a history entry for every flag state change (introduced, enabled per offering, generally available, flag removed) using the standard history shortcode format.
- When multiple flag state changes happen in the same release, combine them into a single history entry (e.g., `[Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](link) in GitLab X.X.`).
- When a flag is introduced and enabled by default in the same release, combine into one entry: `[Introduced](link) in GitLab X.X [with a feature flag](link) named \`flag_name\`. Enabled by default.`
- When a flag is renamed or consolidated, record the change in the history entry (e.g., `Feature flag [changed](link) to \`new_flag_name\` in GitLab X.X. Feature flag \`old_flag_name\` removed.`).
- When multiple sub-features each have their own flag lifecycle, use a nested list under the sub-feature name to group their history entries.
- Delete `Enabled on GitLab.com` entries only when the feature is enabled by default for all offerings and the flag is removed.
- If a feature flag is introduced and removed in the same release, delete both the flag history entry and the flag note entirely.

### Feature Flags — Flag Note

- Add the `> [!flag]` note directly below the history block for any feature still behind a flag; remove it when the flag is removed and add a `Generally available` history entry.
- Include the optional "not ready for production use" sentence in the flag note only when appropriate.

### Experiment and Beta Features

- Include the `Status` field in the product availability details for experiment and beta features; remove it when the feature becomes generally available.
- Include feature flag details in experiment/beta documentation when the feature is also behind a feature flag.
- Update the history and status values (including add-on information) whenever the feature status changes.
- When a feature moves from experiment or beta to generally available, remove the `Status` from availability details, remove any language about the feature not being ready for production, and update the history.
- Place enrollment or feedback instructions below the `> [!flag]` alert.
- DO NOT tie non-GitLab Duo experiment or beta features to the namespace-level **Use experiment and beta features** toggle; use feature-specific toggles or feature flags and document the specific controls in the feature's own documentation.

### Experiment and Beta Features — GitLab Duo

- When documenting a GitLab Duo experiment, add a row to the [GitLab Duo feature summary page](https://docs.gitlab.com/user/gitlab_duo/feature_summary/) table and place the feature near similar features in the software development lifecycle order.
- When a GitLab Duo experiment moves to beta, update the row in the feature summary table and update history and status values.
- When a GitLab Duo feature becomes generally available, move it to the GA table on the feature summary page and update history and status values.
- On GitLab.com, check the namespace's `experiment_features_enabled` setting for GitLab Duo features; on Self-Managed and Dedicated, check `instance_level_ai_beta_features_enabled`. DO NOT mix or check both settings for the same instance type.

### Release Notes — Feature Release Notes

- Create each feature release note as a separate Markdown file inside the appropriate release directory (e.g., `doc/releases/19/gitlab-19-1-released/`); use the `Release Notes Item` MR template and assign to an Engineering Manager and Technical Writer for review.
- Keep release note body text to 125 words or fewer; DO NOT include images or videos; use relative links for documentation links; ensure work item links are not confidential.
- Set all required metadata fields: `title` (seven words or fewer), `tier`, `offering`, `documentation_link` (relative URL, no `.md` extension), `work_item` (absolute, non-confidential URL), `categories`, and `stage`.
- Use `level: primary` to place a feature in the `Primary features` section; use `weight` (multiples of 10) to control ordering within a section; omit both when defaults are acceptable.
- Merge all feature release notes by 23:59 UTC on the Friday before release day.

### Release Notes — Publishing

- DO NOT merge release note changes until the release manager confirms packages are publicly available (typically ~14:00 UTC on release day).
- On release day, update the minor release index file: add the `date` metadata, update `description` and `title` metadata, and update the introductory text to reflect the actual release date and version.
- Create the directory and `index.md` for the upcoming release, update the major version `_index.md` cards shortcode, and update `doc/releases/upcoming.md` redirect metadata as part of publishing.
- Add the current release to `data/en-us/navigation.yaml` in the `docs-gitlab-com` repository.
- Backport final release notes to the stable branch on release day (not before): open an MR targeting the stable branch, have a maintainer merge it, then trigger a new pipeline in `docs-gitlab-com` for the relevant stable branch.

### Release Notes — Post-Release Updates

- To update or remove a release note after the deadline: update the `gitlab` repository MR, backport to the stable branch, and trigger a new `docs-gitlab-com` pipeline for the stable branch; verify the update on `docs.gitlab.com` by selecting the version in the upper-right corner.
- To remove a feature release note, delete only the associated Markdown file; no other files require adjustment.

### Upgrade Notes (Version-Specific Changes)

- Place upgrade notes in `doc/update/versions/gitlab_X_changes.md` (one file per major version); create a new page, a matching section in `doc/update/upgrade_paths.md`, a link in `doc/update/versions/_index.md`, and a navigation entry when a new major version begins.
- In the version index, create a `### Upgrade to X.Y` heading per minor version (descending order); list items in descending patch order; prefix each item with the patch version or affected range in brackets.
- For an intentional change or new behavior, use the version that introduced it as the bracket version; for a bug or regression affecting multiple consecutive patches, use a range (e.g., `[18.4.0 - 18.4.1]`).
- DO NOT create separate upgrade note headings for patch releases; list all patch items under the minor version heading.
- When an item affects multiple minor versions, link each version index entry to the same anchor; use an affected-versions table in the upgrade note body when the item spans two or more minor versions.
- Use a descriptive, unique H3 heading for each upgrade note (DO NOT include version numbers in the heading); list `Affects` and `Affected versions` directly after the heading.
- When a required upgrade stop applies to a specific patch, add a note in the version index; for conditional required stops, include the condition and a way for administrators to check if they are affected.
- If an item applies only to specific installation methods, add the installation type(s) in parentheses (e.g., `(Geo)`, `(Linux package)`, `(Helm chart)`).
- For Geo items, include a `{{< details >}}` tier block before the affected versions list.
- Document a known bug before a fix is available only when it has significant impact on upgrades or operations; when the fix ships, update the list item to the affected range and add the fixed patch level to the `Affected versions` field — DO NOT create separate upgrade notes for the bug and the fix.
- When an issue spans two major versions, document full details on the newer major version page and link from the older page; if cross-page linking becomes confusing due to many affected versions, duplicate the item on both pages.

## Authoritative sources

For the full picture, see:

- doc/development/documentation/feature_flags.md
- doc/development/documentation/experiment_beta.md
- doc/development/documentation/release_notes.md
- doc/development/documentation/topic_types/version_specific_changes.md

