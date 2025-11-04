#!/usr/bin/env bash
# shellcheck disable=2059
set -o pipefail

ERROR_COLOR_SET="\e[1;31m"
INFO_COLOR_SET="\e[1;32m"
COLOR_RESET="\e[0m"

# Directories for projects that are included on the GitLab Docs website in addition to the 'gitlab' project
EXTERNAL_DOCS_PROJECTS="omnibus charts runner operator"

cd "$(dirname "$0")/.." || exit 1
printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Linting '$(pwd)' as $(whoami)...\n"
ERRORCODE=0

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for files with cURL short options...\n"
FILES_WITH_CURL_SHORT_OPTIONS=$(grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/)
if [ "${FILES_WITH_CURL_SHORT_OPTIONS}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} cURL short options found! Use long options in these files instead (for example, --header instead of -H):\n"
  printf "  ${FILES_WITH_CURL_SHORT_OPTIONS}\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/restful_api_styleguide/#curl-commands\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)' for CHANGELOG.md with duplicate entries...\n"
DUPLICATE_CHANGELOG_VERSIONS=$(grep --extended-regexp '^## .+' CHANGELOG.md | sed -E 's| \(.+\)||' | sort -r | uniq -d)
if [ "${DUPLICATE_CHANGELOG_VERSIONS}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Duplicate versions found! Check these versions in CHANGELOG.md:\n"
  printf "  ${DUPLICATE_CHANGELOG_VERSIONS}\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for files with executable permissions...\n"
EXECUTABLE_PERMISSIONS_FILES=$(find doc -type f -perm 755)
if [ "${EXECUTABLE_PERMISSIONS_FILES}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Executable permissions found! Use 'chmod 644' on these files:\n"
  printf "  ${EXECUTABLE_PERMISSIONS_FILES}\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for README.md files...\n"
README_FILES=$(find doc -name "README.md")
if [ "${README_FILES}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} README.md files found! Rename these files:\n"
  printf "  ${README_FILES}\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/site_architecture/folder_structure/#work-with-directories-and-files\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for directory names containing dashes...\n"
DIRECTORY_NAMES_WITH_DASHES=$(find doc -type d -name "*-*")
if [ "${DIRECTORY_NAMES_WITH_DASHES}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Directory names with dashes found! Use underscores instead of dashes for these directory names:\n"
  printf "  ${DIRECTORY_NAMES_WITH_DASHES}\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/site_architecture/folder_structure/#work-with-directories-and-files\n\n"
  ((ERRORCODE++))
fi

# Number of filenames with dashes as of 2025-10-14
FILE_NUMBER_DASHES=22
FILENAMES_WITH_DASHES=$(find doc -type f -name "*-*.md" | wc -l)
printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for filenames containing dashes...\n"
if [ "${FILENAMES_WITH_DASHES}" -ne $FILE_NUMBER_DASHES ]
then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} The number of filenames containing dashes has changed! Use underscores instead of dashes for filenames.\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} If removing a file with a filename containing dashes, update the variable FILE_NUMBER_DASHES in scripts/lint-doc.sh.\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/site_architecture/folder_structure/#work-with-directories-and-files\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for directory names containing an uppercase letter...\n"
DIRECTORY_NAMES_WITH_UPPERCASE=$(find doc -type d -name "*[[:upper:]]*")
if [ "${DIRECTORY_NAMES_WITH_UPPERCASE}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Directory names with an uppercase letter found! Use lowercase instead for these directories:\n"
  printf "  ${DIRECTORY_NAMES_WITH_UPPERCASE}\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/site_architecture/folder_structure/#work-with-directories-and-files\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for images without a milestone in the filename...\n"
VERSIONLESS_IMAGES=$(find doc -name "*.png" | grep -Ev '_v[0-9][0-9]?_.+\.png$')
if [ "${VERSIONLESS_IMAGES}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Images without a milestone in the filename found! Append a milestone ('_vXX_Y') to the filename of these images:\n"
  printf "  ${VERSIONLESS_IMAGES}\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/styleguide/#image-requirements\n\n"
  ((ERRORCODE++))
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking '$(pwd)/doc' for filenames containing an uppercase letter...\n"
FILENAMES_WITH_UPPERCASE=$(find doc -type f -name "*[[:upper:]]*.md")
if [ "${FILENAMES_WITH_UPPERCASE}" != "" ]; then
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Filenames with an uppercase letter found! Use lowercase letters instead for these filenames:\n"
  printf "  ${FILENAMES_WITH_UPPERCASE}\n"
  printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} For more information, see https://docs.gitlab.com/development/documentation/site_architecture/folder_structure/#work-with-directories-and-files\n\n"
  ((ERRORCODE++))
fi

# Run Vale and Markdownlint only on changed files. Only works on merged results
# pipelines, so first checks if a merged results CI/CD variable is present. If not present,
# runs test on all files.
if [ -n "$1" ]; then
  MD_DOC_PATH="$@"
  MD_DOC_PATH_VALE="$@"
  printf "${INFO_COLOR_SET}INFO${COLOR_RESET} List of files specified on command line. Running Markdownlint and Vale for only those files...\n"
elif [ -n "${CI_MERGE_REQUEST_IID}" ]; then
  DOC_CHANGES_FILE=$(mktemp)
  ruby -r './tooling/lib/tooling/find_changes' -e "Tooling::FindChanges.new(
      from: :api,
      changed_files_pathname: '${DOC_CHANGES_FILE}',
      file_filter: ->(file) { !file['deleted_file'] && file['new_path'] =~ %r{\A(?:doc/(.*\.md|\.markdownlint|\.vale)|\.vale\.ini|\.markdownlint-cli2.yaml|scripts/lint-doc\.sh|\.gitlab/ci/docs\.gitlab-ci\.yml)} },
      only_new_paths: true
    ).execute"
  if grep -qE "\.vale|\.markdownlint|lint-doc\.sh|docs\.gitlab-ci\.yml" < $DOC_CHANGES_FILE; then
    MD_DOC_PATH=${MD_DOC_PATH:-'doc/{*,**/*}.md'}
    MD_DOC_PATH_VALE=${MD_DOC_PATH_VALE:-'doc/'}
    printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Vale, Markdownlint, lint-doc.sh, or pipeline configuration changed. Testing all files.\n"
  else
    MD_DOC_PATH=$(cat $DOC_CHANGES_FILE)
    MD_DOC_PATH_VALE=$(cat $DOC_CHANGES_FILE)
    if [ -n "${MD_DOC_PATH}" ]; then
      printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Merge request pipeline detected. Testing only the following files:\n${MD_DOC_PATH}\n"
    fi
  fi
  rm $DOC_CHANGES_FILE
else
  MD_DOC_PATH=${MD_DOC_PATH:-'doc/{*,**/*}.md'}
  MD_DOC_PATH_VALE=${MD_DOC_PATH_VALE:-'doc/'}
  printf "${INFO_COLOR_SET}INFO${COLOR_RESET} No merge request pipeline detected. Running Markdownlint and Vale on all files...\n"
fi

function run_locally_or_in_container() {
  local cmd=$1
  local args=$2
  local files=$3
  local registry_url="registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/lint-markdown:alpine-3.21-vale-3.11.2-markdownlint2-0.17.2-lychee-0.18.1"

  if hash "${cmd}" 2>/dev/null; then
    printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Found locally installed ${cmd}! Running...\n"
    $cmd $args $files
  # When using software like Rancher Desktop, both nerdctl and docker binaries are available
  # but only one is configured. To check which one to use, we need to probe each runtime
  elif (hash nerdctl 2>/dev/null) && (nerdctl info > /dev/null 2>&1); then
    printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Found nerdctl! Using linting image to run ${cmd}...\n"
    nerdctl run -t -v "${PWD}:/gitlab" -w /gitlab --rm ${registry_url} ${cmd} ${args}
  elif (hash docker 2>/dev/null) && (docker info > /dev/null 2>&1); then
    printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Found docker! Using linting image to run ${cmd}...\n"
    docker run -t -v "${PWD}:/gitlab" -w /gitlab --rm ${registry_url} ${cmd} ${args}
  else
    printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} ${cmd} not found! Install ${cmd} locally, or install a container runtime (docker or nerdctl) and try again.\n"
    ((ERRORCODE++))
  fi

  if [ $? -ne 0 ]; then
    printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} ${cmd} failed with errors!\n"
    ((ERRORCODE++))
  fi
}

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Linting markdown style...\n"
if [ -z "${MD_DOC_PATH}" ]; then
  printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Merge request pipeline detected, but no markdown files found. Skipping.\n"
else
  if ! markdownlint-cli2 ${MD_DOC_PATH}; then
    printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Markdownlint failed with errors!\n"
    ((ERRORCODE++))
  fi
fi

printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Looking for Vale to lint prose, either installed locally or available in documentation linting image...\n"
run_locally_or_in_container 'vale' "--minAlertLevel error --output=doc/.vale/vale.tmpl" "${MD_DOC_PATH_VALE}"

# Check for restricted directory names that would conflict with other project's docs
printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Checking for restricted directory names...\n"
for dir in $EXTERNAL_DOCS_PROJECTS; do
  if [ -d "doc/$dir" ]; then

    printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Found restricted directory name '${dir}' in doc/ directory!\n"
    printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} This directory name conflicts with existing documentation repositories.\n"
    ((ERRORCODE++))
    break
  fi
done

if [ "$ERRORCODE" -ne 0 ]; then
  printf "\n${ERROR_COLOR_SET}ERROR${COLOR_RESET} lint tests failed! Review the log carefully to see full listing.\n"
  exit 1
else
  printf "\n${INFO_COLOR_SET}INFO${COLOR_RESET} Linting passed.\n"
  exit 0
fi
