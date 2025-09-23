#!/usr/bin/env bash
# Universal language-specific Vale linting script
# Uses environment variables to configure language-specific behavior

set -euo pipefail

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_RESET="\e[39m"

# Check required environment variables
if [ -z "${LANGUAGE_NAME:-}" ]; then
  echo -e "${COLOR_RED}ERROR: LANGUAGE_NAME environment variable is not set${COLOR_RESET}"
  exit 1
fi

if [ -z "${LANGUAGE_CODE:-}" ]; then
  echo -e "${COLOR_RED}ERROR: LANGUAGE_CODE environment variable is not set${COLOR_RESET}"
  exit 1
fi

cd "$(dirname "$0")/.." || exit 1
echo -e "INFO: Running ${LANGUAGE_NAME}-specific Vale linting at path $(pwd)...\n"
echo -e "INFO: Language Code: ${LANGUAGE_CODE}\n"

ERRORCODE=0

echo -e "${COLOR_GREEN}INFO: Running ${LANGUAGE_NAME}-specific Vale rules...${COLOR_RESET}\n"

# Run vale with either specified files or default path
if [ $# -gt 0 ]; then
  vale --config="doc-locale/${LANGUAGE_CODE}/.vale.ini" "$@" || {
    echo -e "${COLOR_RED}ERROR: ${LANGUAGE_NAME} Vale rules found issues in translation files${COLOR_RESET}\n"
    ((ERRORCODE++))
  }
else
  vale --config="doc-locale/${LANGUAGE_CODE}/.vale.ini" "doc-locale/${LANGUAGE_CODE}/" || {
    echo -e "${COLOR_RED}ERROR: ${LANGUAGE_NAME} Vale rules found issues in translation files${COLOR_RESET}\n"
    ((ERRORCODE++))
  }
fi

# Report results
if [ "$ERRORCODE" -ne 0 ]; then
  echo -e "\n${COLOR_RED}ERROR: ${LANGUAGE_NAME} Vale lint checks failed!${COLOR_RESET}\n"
  exit 1
else
  echo -e "\n${COLOR_GREEN}SUCCESS: All ${LANGUAGE_NAME} Vale lint checks passed${COLOR_RESET}\n"
  exit 0
fi
