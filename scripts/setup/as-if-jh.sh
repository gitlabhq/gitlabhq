#!/bin/sh

prepare_jh_branch() {
  set -eu # https://explainshell.com/explain?cmd=set+-eu

  JH_BRANCH="$(./scripts/setup/find-jh-branch.rb)"
  export JH_BRANCH

  echoinfo "JH_BRANCH: ${JH_BRANCH}"
}

download_jh_path() {
  set -eu # https://explainshell.com/explain?cmd=set+-eu

  for path in "$@"; do
    # https://www.shellcheck.net/wiki/SC3043
    # shellcheck disable=SC3043
    local output="${path}.tar.gz"

    echoinfo "Downloading ${path}"

    curl --location --output "${output}" --header "Private-Token: ${ADD_JH_FILES_TOKEN}" --get --data-urlencode "sha=${JH_BRANCH}" --data-urlencode "path=${path}" "https://gitlab.com/api/v4/projects/${GITLAB_JH_MIRROR_PROJECT}/repository/archive"

    tar -zxf "${output}" --strip-component 1
    rm "${output}"
  done
}
