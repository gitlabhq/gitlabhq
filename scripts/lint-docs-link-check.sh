#!/usr/bin/env bash
set -eo pipefail

INFO_COLOR_SET="\e[1;32m"
WARN_COLOR_SET="\e[1;33m"
ERROR_COLOR_SET="\e[1;31m"
COLOR_RESET="\e[0m"

# shellcheck disable=2059
if command -v lychee > /dev/null; then
  printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Lychee found! Checking documentation links...\n"
  if lychee --offline --no-progress --include-fragments doc; then
    printf "${INFO_COLOR_SET}INFO${COLOR_RESET} Documentation link test passed!\n"
  else
    printf "${ERROR_COLOR_SET}ERROR${COLOR_RESET} Documentation link test failed!\n"
    exit 1
  fi
else
  printf "${WARN_COLOR_SET}WARN${COLOR_RESET} Lychee not found! For more information, see <https://lychee.cli.rs/installation/>.\n"
fi
