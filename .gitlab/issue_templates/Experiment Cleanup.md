<!-- Title suggestion: [Experiment Name] Cleanup -->

## Summary

This issue is created during the experiment's implementation and lives for the whole experiment.
It records the experiment's footprint as it grows, and once the experiment concludes it drives the
cleanup: productize the candidate, or revert to control. The outcome is determined on the rollout
issue via its scoped `experiment::` label, which triage-ops propagates to this issue.

<!-- At creation only the Footprint needs filling in (the rollout issue link, then each MR as it
merges). Everything under Steps is worked out once the experiment has concluded. -->

## Steps

<!-- Work through these once the rollout issue carries ~experiment::validated or
~experiment::invalidated and the label has been synced to this issue. -->

### Before the cleanup MR

- [ ] **Consider the user experience impact of transitioning users between control and candidate experiences.**
   Users who were in the control group will now receive the candidate experience (or vice versa if the experiment is being disabled). Evaluate whether this transition could cause surprising or disorienting experiences, such as:
   - Unexpected UI changes (e.g. layout, navigation, or feature availability shifting without warning)
   - Loss of user-specific state or preferences that were tied to one variant (e.g. pinned items, saved settings)
   - Inconsistency between what a user remembers and what they now see

   If any of these concerns apply, determine what mitigation is needed (e.g. data migration, a transitional state, in-app messaging, or a phased rollout) and add sub-tasks below:
   - [ ] (placeholder for any user experience transition work identified above)
- [ ] Check the **Footprint** lists every MR the experiment merged. Grep for the flag name and experiment class and add anything missing.

### Productize (`~experiment::validated`)

<!-- Decisions for the productized feature. Blank means the default applies; the cleanup MR applies
exactly what is decided here. -->

| Decision | Default | Value |
| --- | --- | --- |
| **Tracking** — keep, remove or modify the events the experiment added | no default, must be filled in | |
| **Availability** — SaaS, self-managed, or both | as implemented | |
| **Tier** — Core or EE tiers | as implemented | |
| **`feature_category:`** — keep or move ownership (PM for Growth and the new category's PM as DRIs) | unchanged | |
| **UX polish** — link to the polish issue owned by the designated UX counterpart | none | |
| **User transition mitigation** — from the transition check above and the implementation issue's UX Transition Considerations | none | |
| **Design assets** — new assets to add to design repos | none unless the MRs added assets | |
| **Documentation** — pages to add or update | update pages describing the behaviour | |
| **Default-enabled feature flag for one milestone** | no | |

- [ ] Review the `Experiment Successful Cleanup Concerns` section of the rollout issue and record anything that changes the table above.
- [ ] Open and merge the cleanup MR: the candidate becomes the only code path, the experiment
      class, feature flag and experiment-only specs are removed, the decisions in the table above
      are applied, and the MR carries a `Changelog: changed` trailer.

### Revert (`~experiment::invalidated`)

- [ ] Open and merge the cleanup MR: the control becomes the only code path, the candidate code,
      experiment class, feature flag, tracking calls and experiment-only specs are removed, and
      the MR carries a `Changelog: removed` trailer.

### Inconclusive, pending, or no label

No cleanup MR. The PM records the decision on the rollout issue and sets `~experiment::validated`
or `~experiment::invalidated`; this issue then follows the matching path above.

### After the cleanup MR merges

- [ ] Add the cleanup MR to the **Footprint** section and prefix the section with `**Cleaned up by <MR URL>.**`
- [ ] Post the outcome to the rollout issue: which path was taken, the cleanup MR, and anything kept (tracking, docs).
- [ ] If a feature flag was kept: in the next milestone, [remove the feature flag](https://docs.gitlab.com/development/feature_flags/controls/#cleaning-up).
- [ ] After the flag removal is deployed, [clean up the feature flag](https://docs.gitlab.com/development/feature_flags/controls/#cleaning-up) by running the chatops command in `#production`.
- [ ] Close the rollout issue and this issue.

## Footprint

<!-- The current net inventory of everything this experiment added, kept up to date as MRs and
issues are created. The cleanup productizes or reverts exactly this list, so keep it complete.
Edit this section in place: one section, no footprint comments. The diffs of the listed MRs are
the file inventory. -->

- Rollout issue: `<URL>`
- Merge requests: `<MR URL> — one-line purpose`, one per MR
- Related issues (follow-ups, bugs, UX polish, tech debt): `<URL> — one-line purpose`, or `none`
- Other artifacts (docs pages, changelog entry, design assets, dashboards/queries): `<path or URL>` per item, or `none`

/label ~"type::maintenance" ~"workflow::scheduling" ~"growth experiment" ~"feature flag" ~"cycle-time-retro" ~"experiment::pending"
