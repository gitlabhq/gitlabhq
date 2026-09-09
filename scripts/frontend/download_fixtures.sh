#!/usr/bin/env bash

#
# Downloads the most recent frontend fixtures for the current commit, going up the commit parent
# chain up to max-commits commits (defaults to 50 commits).
#
# Can also resolve fixtures for a pipeline (including unmerged branches) by asking the GitLab
# API for the relevant commit SHA. gitlab-org/gitlab is public, so this API call is
# unauthenticated.
#

source scripts/packages/helpers.sh

GITLAB_PROJECT_ID=278964
API_BASE_URL="https://gitlab.com/api/v4/projects/${GITLAB_PROJECT_ID}"
API_PACKAGES_BASE_URL="${API_BASE_URL}/packages/generic"

print_help() {
  echo "Usage: scripts/frontend/download_fixtures.sh [--branch <branch-name>] [--max-commits <number>] [--pipeline <id>]"
  echo
  echo "Looks for a frontend fixture package in the package registry."
  echo
  echo "Local strategy (walk the local git history and probe by commit SHA):"
  echo "  --branch <branch-name>   Use the given branch as the commit reference (default: current branch)."
  echo "                           Fetch a remote branch first (git fetch <remote> <branch>) to use it, e.g."
  echo "                           --branch <remote>/<branch-name>."
  echo "  --max-commits <number>   How many commits to walk (default: 50)."
  echo
  echo "Remote strategy (resolve a SHA through the public GitLab API):"
  echo "  --pipeline <id>          Fetch fixtures published by the given pipeline ID."
  echo
  echo "The pipeline strategy is useful for unmerged branches: run the manual 'upload-frontend-fixtures-on-demand'"
  echo "CI job on the branch pipeline first, then download its fixtures here."

  return
}

# Downloads and extracts the fixture package for a commit SHA. Returns 0 on success, 1 if not found.
download_fixtures_for_sha() {
  local commit_sha="$1"
  local fixtures_package="fixtures-${commit_sha}.tar.gz"
  local fixtures_package_url="${API_PACKAGES_BASE_URL}/fixtures/${commit_sha}/${fixtures_package}"

  if archive_doesnt_exist "${fixtures_package_url}" > /dev/null 2>&1; then
    return 1
  fi

  echo "We have found frontend fixtures at ${fixtures_package_url}!"
  read_curl_package "${fixtures_package_url}" | extract_package
}

# Resolves a pipeline ID to its commit SHA through the GitLab API.
resolve_pipeline_sha() {
  local pipeline_id="$1"

  curl --fail --silent --retry 3 "${API_BASE_URL}/pipelines/${pipeline_id}" 2>/dev/null |
    ruby -rjson -e 'puts (JSON.parse($stdin.read)["sha"] rescue "")'
}

download_from_pipeline() {
  local pipeline_id="$1"

  echo "Resolving commit for pipeline ${pipeline_id}..."
  local commit_sha
  commit_sha="$(resolve_pipeline_sha "${pipeline_id}")"

  if [ -z "${commit_sha}" ]; then
    echoerr "Could not resolve a commit for pipeline ${pipeline_id}."
    exit 1
  fi

  echo "Looking for frontend fixtures for pipeline ${pipeline_id} (commit ${commit_sha})..."
  if ! download_fixtures_for_sha "${commit_sha}"; then
    echoerr "No fixtures found for pipeline ${pipeline_id}. Did you run the 'upload-frontend-fixtures-on-demand' job?"
    exit 1
  fi
}

download_from_local_history() {
  local branch="$1"
  local max_commits_count="$2"

  for commit_sha in $(git rev-list "${branch}" --max-count="${max_commits_count}"); do
    echo "Looking for frontend fixtures for commit ${commit_sha}..."

    if download_fixtures_for_sha "${commit_sha}"; then
      break
    fi
  done
}

branch="HEAD"
max_commits_count=50
pipeline_id=""

while [ $# -gt 0 ]; do
  case "$1" in
    --branch)
      shift
      branch="$1"
      ;;
    --max-commits)
      shift
      max_commits_count="$1"
      ;;
    --pipeline)
      shift
      pipeline_id="$1"
      ;;
     *)
      print_help
      exit
      ;;
  esac
  shift
done

if [ -n "${pipeline_id}" ]; then
  download_from_pipeline "${pipeline_id}"
else
  download_from_local_history "${branch}" "${max_commits_count}"
fi
