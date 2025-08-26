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
  printf "\n❌❌❌ ${BRed}Duo workflows smoke test failed!${Color_Off} ❌❌❌\n"
  if [ "${REVEAL_RUBOCOP_TODO:-0}" -ne 0 ]; then
    printf "\n${BRed}- If the failure was due to rubocop, try setting REVEAL_RUBOCOP_TODO=0 to ignore TODOs${Color_Off}\n"
  fi

  printf "\n${BRed}- If the failure was in a feature spec, those are sometimes flaky. Try running again, or run the test in isolation${Color_Off}\n"

  exit "${exit_status}"
}

function print_start_message {
  trap onexit_err ERR

  printf "${BCyan}\nStarting Duo Workflows smoke test...${Color_Off}\n\n"
}

function run_rubocop {
  trap onexit_err ERR

  printf "${BBlue}Running RuboCop${Color_Off}. Use SKIP_RUBOCOP=1 to skip this check, REVEAL_RUBOCOP_TODO=1 to see todos.\n\n"

  files_for_rubocop=()

  while IFS='' read -r file; do
    files_for_rubocop+=("$file")
  done < <(git ls-files -- '*/duo_workflows/*.rb' '*/duo_workflow/*.rb')

  REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-0} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"
}

function run_rspec {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec specs${Color_Off}. Use SKIP_RSPEC=1 to skip this check\n\n"

  printf "Running rspec command:\n\n"

  git ls-files -- '*/duo_workflows/*_spec.rb' '*/duo_workflow/*_spec.rb' | xargs bin/rspec -fd
}

function run_jest {
  trap onexit_err ERR

  printf "Running Jest, use SKIP_JEST=1 to skip this check\n"
  printf "\n\n${BBlue}Running 'yarn check --integrity' and 'yarn install' if needed${Color_Off}\n\n"

  yarn check --integrity || yarn install

  printf "\n\n${BBlue}Running Duo workflows frontend Jest specs${Color_Off}\n\n"
  git ls-files -- '*/ai/*_spec.js'  | xargs yarn jest
}

function print_success_message {
  printf "\n✅✅✅ ${BGreen}All executed linters/specs passed successfully!${Color_Off} ✅✅✅\n"
}

function main {
  trap onexit_err ERR

  # Ensure we were not invoked via a non-bash shell which overrode the /bin/bash shebang
  [ -n "${BASH_VERSION:-}" ] || { printf "\n❌❌❌ ${BRed}Please run with bash${Color_Off} ❌❌❌\n" >&2; exit 1; }

  # cd to gitlab root directory
  cd "$(dirname "${BASH_SOURCE[0]}")"/../..

  # ensure mise is activated for gitlab directory (if we were invoked from a different directory)
  command -v mise >/dev/null 2>&1 || { printf "\n❌❌❌ ${BRed}mise is required, please install it${Color_Off} ❌❌❌\n" >&2; exit 1; }
  eval "$(mise activate bash)"

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
