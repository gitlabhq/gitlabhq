#!/usr/bin/env bash
set -euo pipefail

# Runs a single gitlab-housekeeper keep from a scheduled housekeeping pipeline.
#
# The Rails environment (checkout, gems, database) is prepared by the job's
# before_script (scripts/prepare_build.sh). This script only configures the git
# author and push remote, then runs the keep.
#
# Required CI/CD variables:
#   HOUSEKEEPER_GITLAB_API_TOKEN  API token used to open MRs and push the branch.
#
# Required job variables:
#   KEEP            The keep class to run, e.g. Keeps::RubocopFixer.
#   GIT_USER_NAME   Git committer name for the generated commits.
#   GIT_USER_EMAIL  Git committer email for the generated commits.
#
# Optional:
#   MAX_MRS         Maximum number of MRs to create. Defaults to 1.
#   EXTRA_FLAGS     Extra flags for gitlab-housekeeper, e.g. -d for a dry-run.

git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git config --global http.proactiveAuth basic

# gitlab-housekeeper pushes to the `housekeeper` remote when it is present.
git remote add housekeeper \
  "https://gitlab-ci-token:${HOUSEKEEPER_GITLAB_API_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"

# The runner checks out a detached HEAD with only refs/remotes/origin/*, but
# gitlab-housekeeper cuts each keep's branch from a local `master`.
git rev-parse --verify --quiet master >/dev/null || git branch master "${CI_COMMIT_SHA}"

MAX_MRS="${MAX_MRS:-1}"

cmd=(bundle exec gitlab-housekeeper -k "${KEEP}" --max-mrs "${MAX_MRS}")
if [ -n "${EXTRA_FLAGS:-}" ]; then
  read -ra extra_flags <<< "${EXTRA_FLAGS}"
  cmd+=("${extra_flags[@]}")
fi

echo "Running '${cmd[*]}'"

"${cmd[@]}"
