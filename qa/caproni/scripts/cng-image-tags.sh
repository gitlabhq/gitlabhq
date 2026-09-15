#!/usr/bin/env bash
# Source me: exports CAPRONI_CNG_*_TAG. Shell port of Helpers::CI.
#
# In CI only the *_TAG rule fires: build-cng-env emits every *_TAG, because test-on-cng
# sets CNG_SKIP_REDUNDANT_JOBS=true and trigger-build.rb only adds the tags when it is.
# The fallbacks are the local path, where there is no dotenv to read.

# Sourced, so options leak into later job lines; restored at the end
__caproni_saved_opts="$(set +o)"
set -euo pipefail

: "${CI_PROJECT_DIR:?CI_PROJECT_DIR is not set}"
: "${CI_COMMIT_SHA:?CI_COMMIT_SHA is not set}"

with_semver_prefix() {
  local version="$1"
  if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?(-ee)?$ ]]; then
    printf 'v%s' "${version}"
  else
    printf '%s' "${version}"
  fi
}

# Checked explicitly: set -e does not catch nested command substitution
resolve_from_file() {
  local tag_value="${!1:-}"
  if [[ -n "${tag_value}" ]]; then
    with_semver_prefix "${tag_value}"
    return
  fi

  local version_file="${CI_PROJECT_DIR}/$2"
  if [[ ! -r "${version_file}" ]]; then
    echo "Cannot read ${version_file}, and \$$1 is not set" >&2
    return 1
  fi

  local version
  version=$(tr -d '[:space:]' < "${version_file}")
  if [[ -z "${version}" ]]; then
    echo "${version_file} is empty, and \$$1 is not set" >&2
    return 1
  fi

  with_semver_prefix "${version}"
}

resolve_from_sha() {
  local tag_value="${!1:-}"
  printf '%s' "${tag_value:-${CI_COMMIT_SHA}}"
}

# Assign before export, or export masks the failure exit status
CAPRONI_CNG_GITALY_TAG="$(resolve_from_file GITALY_TAG GITALY_SERVER_VERSION)"
CAPRONI_CNG_GITLAB_SHELL_TAG="$(resolve_from_file GITLAB_SHELL_TAG GITLAB_SHELL_VERSION)"
CAPRONI_CNG_KAS_TAG="$(resolve_from_file GITLAB_KAS_TAG GITLAB_KAS_VERSION)"

CAPRONI_CNG_SIDEKIQ_TAG="$(resolve_from_sha GITLAB_SIDEKIQ_TAG)"
CAPRONI_CNG_TOOLBOX_TAG="$(resolve_from_sha GITLAB_TOOLBOX_TAG)"
CAPRONI_CNG_WEBSERVICE_TAG="$(resolve_from_sha GITLAB_WEBSERVICE_TAG)"
CAPRONI_CNG_WORKHORSE_TAG="$(resolve_from_sha GITLAB_WORKHORSE_TAG)"
CAPRONI_CNG_REGISTRY_TAG="$(resolve_from_sha GITLAB_CONTAINER_REGISTRY_TAG)"

export CAPRONI_CNG_GITALY_TAG CAPRONI_CNG_GITLAB_SHELL_TAG CAPRONI_CNG_KAS_TAG
export CAPRONI_CNG_SIDEKIQ_TAG CAPRONI_CNG_TOOLBOX_TAG CAPRONI_CNG_WEBSERVICE_TAG
export CAPRONI_CNG_WORKHORSE_TAG CAPRONI_CNG_REGISTRY_TAG

# A function so set -e sees the failure, sourced or executed
report_cng_image_tags() {
  local var name
  echo "Resolved CNG image tags:"
  for var in GITALY GITLAB_SHELL KAS SIDEKIQ TOOLBOX WEBSERVICE WORKHORSE REGISTRY; do
    name="CAPRONI_CNG_${var}_TAG"
    if [[ -z "${!name}" ]]; then
      echo "${name} resolved to an empty value" >&2
      return 1
    fi
    echo "  ${name}=${!name}"
  done
}

report_cng_image_tags

eval "${__caproni_saved_opts}"
unset __caproni_saved_opts
