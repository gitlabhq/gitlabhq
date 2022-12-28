#!/usr/bin/env bash

# shellcheck disable=SC2059

set -o errexit # AKA -e - exit immediately on errors (http://mywiki.wooledge.org/BashFAQ/105)

# https://stackoverflow.com/a/28938235
BCyan='\033[1;36m' # Bold Cyan
BRed='\033[1;31m' # Bold Red
Color_Off='\033[0m' # Text Reset

function onexit_err() {
  local exit_status=${1:-$?}
  printf "\n❌❌❌ ${BRed}GLFM spec tests failed!${Color_Off} ❌❌❌\n"
  exit "${exit_status}"
}
trap onexit_err ERR
set -o errexit

printf "${BCyan}"
printf "\nThis script is not yet implemented!\n"
printf "\nSee https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#run-spec-testssh-script for more details.\n\n"
printf "${Color_Off}"
