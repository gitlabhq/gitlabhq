#!/usr/bin/env bash

#
# Downloads the most recent frontend fixtures for the current commit, going up the commit parent
# chain up to max-commits commits (defaults to 50 commits).
#

source scripts/packages/helpers.sh

print_help() {
  echo "Usage: scripts/frontend/download_fixtures.sh [--branch <branch-name>] [--max-commits <number>]"
  echo
  echo "Looks for a frontend fixture package in the package registry for commits on a local branch."
  echo
  echo "If --branch isn't specified, the script will use the current branch as a commit reference."
  echo "If --max-commits isn't specified, the default is 50 commits."

  return
}

branch="HEAD"
max_commits_count=50

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
     *)
      print_help
      exit
      ;;
  esac
  shift
done

for commit_sha in $(git rev-list ${branch} --max-count="${max_commits_count}"); do
  API_PACKAGES_BASE_URL=https://gitlab.com/api/v4/projects/278964/packages/generic
  FIXTURES_PACKAGE="fixtures-${commit_sha}.tar.gz"
  FIXTURES_PACKAGE_URL="${API_PACKAGES_BASE_URL}/fixtures/${commit_sha}/${FIXTURES_PACKAGE}"

  echo "Looking for frontend fixtures for commit ${commit_sha}..."

  if ! archive_doesnt_exist "${FIXTURES_PACKAGE_URL}" > /dev/null 2>&1; then
    echo "We have found frontend fixtures at ${FIXTURES_PACKAGE_URL}!"

    read_curl_package "${FIXTURES_PACKAGE_URL}" | extract_package

    break
  fi
done
