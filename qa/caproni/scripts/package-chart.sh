#!/usr/bin/env bash
# Shim: the helm deployer cannot pin a SHA yet
# https://gitlab.com/gitlab-org/caproni/-/issues/242

# Sourced, so options leak into later job lines; restored at the end
__caproni_saved_opts="$(set +o)"
set -euo pipefail

: "${CI_PROJECT_DIR:?CI_PROJECT_DIR is not set}"

# Falls back to the CI file so laptops use the same commit
if [[ -z "${GITLAB_HELM_CHART_REF:-}" ]]; then
  GITLAB_HELM_CHART_REF=$(awk -F'"' '/GITLAB_HELM_CHART_REF:/ {print $2}' \
    "${CI_PROJECT_DIR}/.gitlab/ci/qa-common/variables.gitlab-ci.yml")
  export GITLAB_HELM_CHART_REF
fi
: "${GITLAB_HELM_CHART_REF:?could not determine GITLAB_HELM_CHART_REF}"

CHART_PROJECT_URL="https://gitlab.com/gitlab-org/charts/gitlab"
WORK_DIR="${WORK_DIR:-/tmp/gitlab-chart}"
CHART_TAR="gitlab-${GITLAB_HELM_CHART_REF}.tgz"
CACHED_CHART="${CNG_HELM_REPOSITORY_CACHE:-}/${CHART_TAR}"

# A function so set -e sees the failure, sourced or executed
build_chart_package() {
  if [[ -n "${CNG_HELM_REPOSITORY_CACHE:-}" && -f "${CACHED_CHART}" ]]; then
    echo "Cached chart found at ${CACHED_CHART}, skipping packaging"
    GITLAB_CHART_PACKAGE="${CACHED_CHART}"
    return 0
  fi

  rm -rf "${WORK_DIR}"
  mkdir -p "${WORK_DIR}"

  echo "Downloading chart repo at ${GITLAB_HELM_CHART_REF}"
  curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
    "${CHART_PROJECT_URL}/-/archive/${GITLAB_HELM_CHART_REF}/gitlab-${GITLAB_HELM_CHART_REF}.tar" \
    | tar -x -C "${WORK_DIR}" --strip-components=1

  echo "Packaging chart (helm package --dependency-update)"
  helm package --dependency-update --destination "${WORK_DIR}" "${WORK_DIR}"

  local packaged
  packaged=$(find "${WORK_DIR}" -maxdepth 1 -name 'gitlab-*.tgz' -print -quit)
  if [[ -z "${packaged}" ]]; then
    echo "Failed to package chart: no gitlab-*.tgz produced in ${WORK_DIR}" >&2
    return 1
  fi

  if [[ -n "${CNG_HELM_REPOSITORY_CACHE:-}" ]] && mkdir -p "${CNG_HELM_REPOSITORY_CACHE}" 2>/dev/null; then
    cp "${packaged}" "${CACHED_CHART}"
    packaged="${CACHED_CHART}"
  fi

  GITLAB_CHART_PACKAGE="${packaged}"
}

build_chart_package
export GITLAB_CHART_PACKAGE
echo "GITLAB_CHART_PACKAGE=${GITLAB_CHART_PACKAGE}"

eval "${__caproni_saved_opts}"
unset __caproni_saved_opts
