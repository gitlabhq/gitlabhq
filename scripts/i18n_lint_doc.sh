#!/usr/bin/env bash
set -o pipefail

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_RESET="\e[39m"

cd "$(dirname "$0")/.." || exit 1
printf "${COLOR_GREEN}INFO: Linting i18n documents at path $(pwd)...${COLOR_RESET}\n"
ERRORCODE=0

# Set defaults for documentation paths
MD_DOC_PATH='doc-locale/{*,**/*}.md'
MD_DOC_PATH_VALE='doc-locale/'

# Run options if files specified on command line
if [ -n "$1" ]; then
  MD_DOC_PATH="$@"
  MD_DOC_PATH_VALE="$@"
  printf "${COLOR_GREEN}INFO: Checking specified files: ${MD_DOC_PATH}${COLOR_RESET}\n"
fi

# 1. Run Markdownlint
printf "${COLOR_GREEN}INFO: Running Markdownlint on i18n files...${COLOR_RESET}\n"
(cd doc-locale && markdownlint-cli2 --config .markdownlint/.markdownlint-cli2.yaml '**/*.md') || {
  printf "${COLOR_YELLOW}WARNING: Markdownlint found issues in i18n files, but continuing...${COLOR_RESET}\n"
  ((ERRORCODE++))
}

# 2. Run Vale
printf "${COLOR_GREEN}INFO: Running Vale on i18n files...${COLOR_RESET}\n"
vale --minAlertLevel error --filter='.Name matches "gitlab_docs"' ${MD_DOC_PATH_VALE} || {
  printf "${COLOR_YELLOW}WARNING: Vale found issues in i18n files, but continuing...${COLOR_RESET}\n"
  ((ERRORCODE++))
}

# Report results
if [ "$ERRORCODE" -ne 0 ]; then
  printf "\n${COLOR_RED}ERROR: i18n lint checks failed!${COLOR_RESET}\n"
  exit 1
else
  printf "\n${COLOR_GREEN}SUCCESS: All i18n lint checks passed${COLOR_RESET}\n"
  exit 0
fi
