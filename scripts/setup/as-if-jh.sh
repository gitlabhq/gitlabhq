#!/bin/sh

set_jh_branch_env_variable() {
  set -eu # https://explainshell.com/explain?cmd=set+-eu

  JH_BRANCH="$(./scripts/setup/find-jh-branch.rb)"
  export JH_BRANCH

  echoinfo "JH_BRANCH: ${JH_BRANCH}"
}

download_jh_files() {
  if [ "${JH_BRANCH}" = "main-jh" ]; then
    download_jh_files_from_api "$@"
  else
    download_jh_files_from_git_clone "$@"
  fi
}

download_jh_files_from_api() {
  set -eu # https://explainshell.com/explain?cmd=set+-eu

  for path in "$@"; do
    # https://www.shellcheck.net/wiki/SC3043
    # shellcheck disable=SC3043
    local output="${path}.tar.gz"

    echoinfo "Downloading ${path} via API"

    # Note: We are limited to 5 downloads/minute on this endpoint.
    # (see https://docs.gitlab.com/ee/api/repositories.html#get-file-archive)
    #
    # If we run this command more than 5 times/minute, we will receive HTTP 429 errors.
    #
    # If this problem happens too often, we might want to either download files from
    # another endpoint, and only download the folders with this endpoint. We could also
    # do a git clone in all cases.
    curl -f --location --output "${output}" --header "Private-Token: ${ADD_JH_FILES_TOKEN}" --get --data-urlencode "sha=${JH_BRANCH}" --data-urlencode "path=${path}" "https://gitlab.com/api/v4/projects/${GITLAB_JH_MIRROR_PROJECT}/repository/archive"

    tar -zxf "${output}" --strip-component 1
    rm "${output}"
  done
}

# The JiHu mirror project is private, so we would need to be authenticated to download files from the API.
#
# When being authenticated and downloading files via the API, we are limited to 5 requests per minute
# (see https://docs.gitlab.com/ee/api/repositories.html#get-file-archive), and we would need to download 6 files
# (3 archives for two branches). This job can also be run in parallel between many pipelines.
download_jh_files_from_git_clone() {
  return_code=0
  git_merge_status_code=0

  echoinfo "Cloning JH mirror repo to download JH files"

  git config --global user.email "${GITLAB_USER_EMAIL}";
  git config --global user.name "${GITLAB_USER_NAME}";

  git clone --filter=tree:0 "${JH_MIRROR_REPOSITORY}" gitlab-jh
  cd gitlab-jh
  git checkout "${JH_BRANCH}"

  git merge main-jh || git_merge_status_code=$?
  if [ "${git_merge_status_code}" -ne 0 ]; then
    git merge --abort || true
    return_code=3
  fi

  mv ${JH_FILES_TO_COMMIT} ./..
  cd ..

  # We explicitly use exit instead of return, otherwise the job would exit with a 1 error code
  exit "${return_code}"
}
