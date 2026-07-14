#!/usr/bin/env bash
set -eo pipefail

# Read-only guard that detects Duo Code Review instruction fences in
# .gitlab/duo/mr-review-instructions.yaml that are stale (recorded
# distilled_at_sha/source_checksum no longer match their distilled file),
# malformed (a BEGIN marker without exactly one matching region), or orphaned
# (a fence with no backing distilled file or manifest entry).
#
# Runs at commit/MR time (lefthook + the `ai-duo-review-instructions` CI jobs).
# The guard's severity is split in CI (gitlab-org/gitlab#604890): malformed and
# orphaned fences always fail, while STALE fences are blocking only on refs that
# own the fences (the reconcile MR and MRs touching the fence file, the gem, or
# this script). On ordinary MRs and on master, staleness is expected transient
# state (a distilled MR merges independently and the daily fence-reconcile job
# catches the fences up from master afterwards), so the caller sets
# WARN_STALE=1 to downgrade staleness to a non-blocking warning. See
# gitlab-org/gitlab#604738 and gitlab-org/gitlab#604890.
#
# The command's only runtime dependency is the `rainbow` gem and it loads no
# Rails. Locally (lefthook) the host bundle already provides `rainbow`, so the
# default `bundle exec ruby` resolves it. The CI job runs on a bare Ruby image
# and sets RUBY_RUN="ruby" after a single `gem install rainbow`, skipping the
# full bundle install entirely.

GEM_DIR="gems/gitlab-ai-principles-distiller"
RUBY_RUN="${RUBY_RUN:-bundle exec ruby}"

WARN_STALE_FLAG=()
if [ -n "${WARN_STALE:-}" ]; then
	WARN_STALE_FLAG=(--warn-stale)
fi

exec ${RUBY_RUN} "${GEM_DIR}/bin/gitlab-ai-principles-distiller-sync" --check-duo-instructions "${WARN_STALE_FLAG[@]}" --workspace .
