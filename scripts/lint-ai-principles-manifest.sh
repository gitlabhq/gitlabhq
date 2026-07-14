#!/usr/bin/env bash
set -eo pipefail

# Validates that every SSOT path referenced by .ai/principles/manifest.yml
# (each principle's `sources[].path` and `baseline:`, plus every
# `static_entries[].path`) exists on the current branch.
#
# Runs at commit/MR time (lefthook + the `ai-principles-manifest` CI job) so a
# doc rename/deletion that orphans a manifest reference fails fast, instead of
# surfacing mid-run on the weekly scheduled distillation. See
# gitlab-org/gitlab#604077.
#
# The validator's only runtime dependency is the `rainbow` gem and it loads no
# Rails. Locally (lefthook) the host bundle already provides `rainbow`, so the
# default `bundle exec ruby` resolves it. The CI job runs on a bare Ruby image
# and sets RUBY_RUN="ruby" after a single `gem install rainbow`, skipping the
# full bundle install entirely.

GEM_DIR="gems/gitlab-ai-principles-distiller"
RUBY_RUN="${RUBY_RUN:-bundle exec ruby}"

exec ${RUBY_RUN} "${GEM_DIR}/bin/gitlab-ai-principles-distiller-validate" --workspace .
