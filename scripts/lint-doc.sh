#!/usr/bin/env bash
set -o pipefail

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_RESET="\e[39m"

# Projects that are included on the Docs website besides gitlab
EXTERNAL_DOCS_PROJECTS="omnibus charts runner operator"

cd "$(dirname "$0")/.." || exit 1
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Linting documents at path $(pwd) as $(whoami)...${COLOR_RESET}\n"
ERRORCODE=0

# Use long options (e.g. --header instead of -H) for curl examples in documentation.
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for cURL short options...${COLOR_RESET}\n"
if grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/ >/dev/null 2>&1;
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: Short options for curl should not be used in documentation!${COLOR_RESET}"
  printf " Use long options (for example, --header instead of -H):\n" >&2
  grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc
  ((ERRORCODE++))
fi

# Documentation pages need front matter for tracking purposes.
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking documentation for front matter...${COLOR_RESET}\n"
if ! scripts/lint-docs-metadata.sh
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: These documentation pages need front matter!${COLOR_RESET}"
  ((ERRORCODE++))
fi

# Test for non-standard spaces (NBSP, NNBSP, ZWSP) in documentation.
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for non-standard spaces...${COLOR_RESET}\n"
if grep --extended-regexp --binary-file=without-match --recursive '[  ​]' doc/ >/dev/null 2>&1;
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: Non-standard spaces (NBSP, NNBSP, ZWSP) should not be used in documentation!${COLOR_RESET}"
  printf " https://docs.gitlab.com/ee/development/documentation/styleguide/index.html#spaces-between-words\n"
  printf "Replace with standard spaces:\n" >&2
  # Find the spaces, then add color codes with sed to highlight each NBSP or NNBSP in the output.
  # shellcheck disable=SC1018
  grep --extended-regexp --binary-file=without-match --recursive --color=auto '[  ]' doc \
       | sed -e ''/ /s//"$(printf "\033[0;101m \033[0m")"/'' -e ''/ /s//"$(printf "\033[0;101m \033[0m")"/''
  ((ERRORCODE++))
fi

# Ensure that the CHANGELOG.md does not contain duplicate versions
DUPLICATE_CHANGELOG_VERSIONS=$(grep --extended-regexp '^## .+' CHANGELOG.md | sed -E 's| \(.+\)||' | sort -r | uniq -d)
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for CHANGELOG.md duplicate entries...${COLOR_RESET}\n"
if [ "${DUPLICATE_CHANGELOG_VERSIONS}" != "" ]
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: Duplicate versions in CHANGELOG.md:${COLOR_RESET}\n" >&2
  echo "${DUPLICATE_CHANGELOG_VERSIONS}" >&2
  ((ERRORCODE++))
fi

# Make sure no files in doc/ are executable
EXEC_PERM_COUNT=$(find doc/ -type f -perm 755 | wc -l)
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking $(pwd)/doc for executable permissions...${COLOR_RESET}\n"
if [ "${EXEC_PERM_COUNT}" -ne 0 ]
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: Executable permissions should not be used in documentation!${COLOR_RESET} Use 'chmod 644' on these files:\n" >&2
  find doc -type f -perm 755
  ((ERRORCODE++))
fi

# Do not use 'README.md', instead use 'index.md'
# Number of 'README.md's as of 2021-08-17
NUMBER_READMES=0
FIND_READMES=$(find doc/ -name "README.md" | wc -l)
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for new README.md files...${COLOR_RESET}\n"
if [ "${FIND_READMES}" -ne $NUMBER_READMES ]
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: The number of README.md files has changed!${COLOR_RESET} Use index.md instead of README.md.\n" >&2
  printf "If removing a README.md file, update NUMBER_READMES in lint-doc.sh.\n" >&2
  printf "https://docs.gitlab.com/ee/development/documentation/site_architecture/folder_structure.html#work-with-directories-and-files\n"
  ((ERRORCODE++))
fi

# Do not use dashes (-) in directory names, use underscores (_) instead.
# Number of directories with dashes as of 2024-12-28
DIR_NUMBER_DASHES=0
DIR_FIND_DASHES=$(find doc -type d -name "*-*" | wc -l)
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for directory names containing dashes...${COLOR_RESET}\n"
if [ "${DIR_FIND_DASHES}" -ne $DIR_NUMBER_DASHES ]
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: The number of directory names containing dashes has changed!${COLOR_RESET} Use underscores instead of dashes for the directory names.\n" >&2
  printf "If removing a directory containing dashes, update NUMBER_DASHES in lint-doc.sh.\n" >&2
  printf "https://docs.gitlab.com/ee/development/documentation/site_architecture/folder_structure.html#work-with-directories-and-files\n"
   ((ERRORCODE++))
fi

# Do not use dashes (-) in filenames, use underscores (_) instead.
# Number of filenames with dashes as of 2024-12-26
FILE_NUMBER_DASHES=66
FILE_FIND_DASHES=$(find doc -type f -name "*-*.md" | wc -l)
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for filenames containing dashes...${COLOR_RESET}\n"
if [ "${FILE_FIND_DASHES}" -ne $FILE_NUMBER_DASHES ]
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: The number of filenames containing dashes has changed!${COLOR_RESET} Use underscores instead of dashes for the filenames.\n" >&2
  printf "If removing a file containing dashes, update the filename NUMBER_DASHES in lint-doc.sh.\n" >&2
  printf "https://docs.gitlab.com/ee/development/documentation/site_architecture/folder_structure.html#work-with-directories-and-files\n"
   ((ERRORCODE++))
fi

# Do not use uppercase letters in directory and file names, use all lowercase instead.
# (find always returns 0, so we use the grep hack https://serverfault.com/a/225827)
FIND_UPPERCASE_DIRS=$(find doc -type d -name "*[[:upper:]]*")
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for directory names containing an uppercase letter...${COLOR_RESET}\n"
if echo "${FIND_UPPERCASE_DIRS}" | grep . &>/dev/null
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: Found one or more directories with an uppercase letter in their name!${COLOR_RESET} Use lowercase instead of uppercase for the directory names.\n" >&2
  printf "https://docs.gitlab.com/ee/development/documentation/site_architecture/folder_structure.html#work-with-directories-and-files\n" >&2
  echo "${FIND_UPPERCASE_DIRS}"
  ((ERRORCODE++))
fi

FIND_UPPERCASE_FILES=$(find doc -type f -name "*[[:upper:]]*.md")
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for file names containing an uppercase letter...${COLOR_RESET}\n"
if echo "${FIND_UPPERCASE_FILES}" | grep . &>/dev/null
then
  # shellcheck disable=2059
  printf "${COLOR_RED}ERROR: Found one or more file names with an uppercase letter in their name!${COLOR_RESET} Use lowercase instead of uppercase for the file names.\n" >&2
  printf "https://docs.gitlab.com/ee/development/documentation/site_architecture/folder_structure.html#work-with-directories-and-files\n" >&2
  echo "${FIND_UPPERCASE_FILES}"
  ((ERRORCODE++))
fi

FIND_ALL_DOCS_DIRECTORIES=$(find doc -type d)
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for documentation path clashes...${COLOR_RESET}\n"
for directory in $FIND_ALL_DOCS_DIRECTORIES; do
  # Markdown files should not have the same path as a directory with an index.md file in it
  if [[ -f "${directory}.md" ]] && [[ -f "${directory}/index.md" ]]; then
    # shellcheck disable=2059
    printf "${COLOR_YELLOW}WARNING: File ${directory}.md clashes with file ${directory}/index.md!${COLOR_RESET} "
    printf "For more information, see https://gitlab.com/gitlab-org/gitlab-docs/-/issues/1792.\n"
  fi
done

# Run Vale and Markdownlint only on changed files. Only works on merged results
# pipelines, so first checks if a merged results CI variable is present. If not present,
# runs test on all files.
if [ -n "$1" ]
then
  MD_DOC_PATH="$@"
  MD_DOC_PATH_VALE="$@"
  # shellcheck disable=2059
  printf "${COLOR_GREEN}INFO: List of files specified on command line. Running Markdownlint and Vale for only those files...${COLOR_RESET}\n"
elif [ -n "${CI_MERGE_REQUEST_IID}" ]
then
  DOC_CHANGES_FILE=$(mktemp)
  ruby -r './tooling/lib/tooling/find_changes' -e "Tooling::FindChanges.new(
      from: :api,
      changed_files_pathname: '${DOC_CHANGES_FILE}',
      file_filter: ->(file) { !file['deleted_file'] && file['new_path'] =~ %r{doc/.*\.md|\.vale|\.markdownlint|lint-doc\.sh|docs\.gitlab-ci\.yml} },
      only_new_paths: true
    ).execute"
  if grep -E "\.vale|\.markdownlint|lint-doc\.sh|docs\.gitlab-ci\.yml" < $DOC_CHANGES_FILE
  then
    MD_DOC_PATH=${MD_DOC_PATH:-'doc/{*,**/*}.md'}
    MD_DOC_PATH_VALE=${MD_DOC_PATH_VALE:-'doc/'}
    # shellcheck disable=2059
    printf "${COLOR_GREEN}INFO: Vale, Markdownlint, lint-doc.sh, or pipeline configuration changed. Testing all files.${COLOR_RESET}\n"
  else
    MD_DOC_PATH=$(cat $DOC_CHANGES_FILE)
    MD_DOC_PATH_VALE=$(cat $DOC_CHANGES_FILE)
    if [ -n "${MD_DOC_PATH}" ]
    then
      # shellcheck disable=2059
      printf "${COLOR_GREEN}INFO: Merge request pipeline detected. Testing only the following files:${COLOR_RESET}\n${MD_DOC_PATH}\n"
    fi
  fi
  rm $DOC_CHANGES_FILE
else
  MD_DOC_PATH=${MD_DOC_PATH:-'doc/{*,**/*}.md'}
  MD_DOC_PATH_VALE=${MD_DOC_PATH_VALE:-'doc/'}
  # shellcheck disable=2059
  printf "${COLOR_GREEN}INFO: No merge request pipeline detected. Running Markdownlint and Vale on all files...${COLOR_RESET}\n"
fi

function run_locally_or_in_container() {
  local cmd=$1
  local args=$2
  local files=$3
  local registry_url="registry.gitlab.com/gitlab-org/gitlab-docs/lint-markdown:alpine-3.20-vale-3.9.3-markdownlint2-0.17.1-lychee-0.18.0"

  if hash "${cmd}" 2>/dev/null
  then
    # shellcheck disable=2059
    printf "${COLOR_GREEN}INFO: Found locally-installed ${cmd}! Running...${COLOR_RESET}\n"
    $cmd $args $files
  # When using software like Rancher Desktop, both nerdctl and docker binaries are available
  # but only one is configured. To check which one to use, we need to probe each runtime
  elif (hash nerdctl 2>/dev/null) && (nerdctl info > /dev/null 2>&1)
  then
    # shellcheck disable=2059
    printf "${COLOR_GREEN}INFO: Found nerdctl! Using linting image to run ${cmd}...${COLOR_RESET}\n"
    nerdctl run -t -v "${PWD}:/gitlab" -w /gitlab --rm ${registry_url} ${cmd} ${args}
  elif (hash docker 2>/dev/null) && (docker info > /dev/null 2>&1)
  then
    # shellcheck disable=2059
    printf "${COLOR_GREEN}INFO: Found docker! Using linting image to run ${cmd}...${COLOR_RESET}\n"
    docker run -t -v "${PWD}:/gitlab" -w /gitlab --rm ${registry_url} ${cmd} ${args}
  else
    # shellcheck disable=2059
    printf "${COLOR_RED}ERROR: '${cmd}' not found!${COLOR_RESET} Install '${cmd}' locally, or install a container runtime (docker or nerdctl) and try again.\n" >&2
    ((ERRORCODE++))
  fi

  if [ $? -ne 0 ]
  then
    # shellcheck disable=2059
    printf "${COLOR_RED}ERROR: '${cmd}' failed with errors!${COLOR_RESET}\n" >&2
    ((ERRORCODE++))
  fi
}

# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Linting markdown style...${COLOR_RESET}\n"
if [ -z "${MD_DOC_PATH}" ]
then
  # shellcheck disable=2059
  printf "${COLOR_GREEN}INFO: Merge request pipeline detected, but no markdown files found. Skipping.${COLOR_RESET}\n"
else
  if ! yarn markdownlint ${MD_DOC_PATH};
  then
    # shellcheck disable=2059
    printf "${COLOR_RED}ERROR: Markdownlint failed with errors!${COLOR_RESET}\n" >&2
    ((ERRORCODE++))
  fi
fi

# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Looking for Vale to lint prose, either installed locally or available in documentation linting image...${COLOR_RESET}\n"
run_locally_or_in_container 'vale' "--minAlertLevel error --output=doc/.vale/vale.tmpl" "${MD_DOC_PATH_VALE}"

# Check for restricted directory names that would conflict with other project's docs
# shellcheck disable=2059
printf "${COLOR_GREEN}INFO: Checking for restricted directory names...${COLOR_RESET}\n"
for dir in $EXTERNAL_DOCS_PROJECTS; do
  if [ -d "doc/$dir" ]; then
    # shellcheck disable=2059
    printf "${COLOR_RED}ERROR: Found restricted directory name '${dir}' in doc/ directory.${COLOR_RESET}\n"
    printf "This directory name conflicts with existing documentation repositories.\n" >&2
    ((ERRORCODE++))
    break
  fi
done

if [ "$ERRORCODE" -ne 0 ]
then
  # shellcheck disable=2059
  printf "\n${COLOR_RED}ERROR: lint test(s) failed! Review the log carefully to see full listing.${COLOR_RESET}\n"
  exit 1
else
  # shellcheck disable=2059
  printf "\n${COLOR_GREEN}INFO: Linting passed.${COLOR_RESET}\n"
  exit 0
fi
