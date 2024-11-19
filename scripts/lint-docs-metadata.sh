#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_RESET="\e[39m"
VERBOSE=false
CHECK_ALL=true

FAILING_FILES=0
TOTAL_FILES=0

# Parse arguments
for arg in "$@"; do
  case $arg in

  --verbose)
    VERBOSE=true
    ;;
  --help | -h)
    cat <<EOF
usage: lint-docs-metadata.sh [--help][--verbose] <file...>

If no files are provided, all markdown files in doc/ are checked.
EOF
    exit 0
    ;;
  *)
    CHECK_ALL=false
    ;;

  esac
done

function check_file {
  local file
  file="$1"
  TOTAL_FILES=$((TOTAL_FILES + 1))
  if [ "$(head -n1 "$file")" != "---" ]; then
    printf "${COLOR_RED}ERROR: Documentation metadata missing in %s.${COLOR_RESET}\n" "$file" >&2
    FAILING_FILES=$((FAILING_FILES + 1))
  elif [ "$VERBOSE" == "true" ]; then
    printf "${COLOR_GREEN}INFO: Documentation metadata found in %s.${COLOR_RESET}\n" "$file"
  fi
}

function check_all_files {
  while IFS= read -r -d '' file; do
    check_file "$file"
  done < <(find "doc" -name "*.md" -type f -print0)
}

if [[ "$CHECK_ALL" = "true" ]]; then
  # shellcheck disable=SC2059
  printf "${COLOR_GREEN}INFO: No files supplied! Checking all markdown files in doc/...${COLOR_RESET}\n"
  check_all_files
else
  # Takes a list of Markdown files as a parameter
  for file in "$@"; do
    # Skipping parameters
    [[ $file = --* ]] && continue
    check_file "$file"
  done
fi

if [ "$FAILING_FILES" -gt 0 ]; then
  # shellcheck disable=SC2059
  printf "\n${COLOR_RED}ERROR: Documentation metadata is missing in ${FAILING_FILES} of ${TOTAL_FILES} documentation files.${COLOR_RESET} For more information, see https://docs.gitlab.com/ee/development/documentation/metadata.html.\n" >&2
  exit 1
else
  # shellcheck disable=SC2059
  printf "${COLOR_GREEN}INFO: Documentation metadata found in ${TOTAL_FILES} documentation files.${COLOR_RESET}\n"
  exit 0
fi
