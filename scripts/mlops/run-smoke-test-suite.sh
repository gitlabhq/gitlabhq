#!/usr/bin/env bash

# shellcheck disable=SC2059

BCyan='\033[1;36m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BBlue='\033[1;34m'
Color_Off='\033[0m'

set -o errexit
set -o pipefail
trap onexit_err ERR

# Exit handling
function onexit_err() {
  local exit_status=${1:-$?}
  printf "\n❌❌❌ ${BRed}MLOps smoke test failed!${Color_Off} ❌❌❌\n"
  if [ "${REVEAL_RUBOCOP_TODO}" -ne 0 ]; then
    printf "\n${BRed}- If the failure was due to rubocop, try setting REVEAL_RUBOCOP_TODO=0 to ignore TODOs${Color_Off}\n"
  fi

  printf "\n${BRed}- If the failure was in a feature spec, those sometimes are flaky, try running it focused${Color_Off}\n"

  exit "${exit_status}"
}

function print_start_message {
  trap onexit_err ERR

  printf "${BCyan}\nStarting MLOps smoke test...${Color_Off}\n\n"
}

function run_rubocop {
  trap onexit_err ERR

  printf "${BBlue}Running RuboCop${Color_Off}\n\n"

  files_for_rubocop=()

  while IFS='' read -r file; do
    files_for_rubocop+=("$file")
  done < <(git ls-files -- '**/ml/**/*.rb')

  REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-1} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"
}

function run_rspec {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec specs${Color_Off}\n\n"

  printf "Running rspec command:\n\n"

  git ls-files -- '**/ml/**/*_spec.rb'  | xargs bin/rspec -fd
}

function run_jest {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running MLOps frontend Jest specs${Color_Off}\n\n"
  git ls-files -- '**/ml/**/*_spec.js'  | xargs yarn jest
}


function print_success_message {
  printf "\n✅✅✅ ${BGreen}All executed linters/specs passed successfully!${Color_Off} ✅✅✅\n"
}

function main {
  trap onexit_err ERR

  # cd to gitlab root directory
  cd "$(dirname "${BASH_SOURCE[0]}")"/../..

  print_start_message

  # Run linting before tests
  [ -z "${SKIP_RUBOCOP}" ] && run_rubocop

  # Test sections are sorted roughly in increasing order of execution time, in order to get the fastest feedback on failures.
  [ -z "${SKIP_RSPEC}" ] && run_rspec
  [ -z "${SKIP_JEST}" ] && run_jest

  # Convenience ENV vars to run focused sections, copy and paste as a prefix to script command, and remove the one(s) you want to run focused
  # SKIP_RUBOCOP=1 SKIP_RSPEC=1 SKIP_JEST=1
 
  print_success_message
}

main "$@"
