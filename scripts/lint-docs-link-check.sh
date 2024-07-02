#!/usr/bin/env bash
set -eo pipefail

COLOR_ERROR="\e[31m"
COLOR_INFO="\e[32m"
COLOR_WARN="\e[33m"
COLOR_RESET="\e[39m"

# shellcheck disable=2059
if command -v lychee > /dev/null; then
  printf "${COLOR_INFO}INFO: Lychee found! Checking documentation links...${COLOR_RESET}\n"
  if lychee --offline --no-progress --include-fragments doc; then
    printf "${COLOR_INFO}INFO: Documentation link test passed!${COLOR_RESET}\n"
  else
    printf "${COLOR_ERROR}ERROR: Documentation link test failed!${COLOR_RESET}\n"
    exit 1
  fi
else
  printf "${COLOR_WARN}WARN: Lychee not found! For more information, see <https://lychee.cli.rs/installation/>.${COLOR_RESET}\n"
fi
