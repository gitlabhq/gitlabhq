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
  printf "\n❌❌❌ ${BRed}Run of fast_spec_helper specs failed!${Color_Off} ❌❌❌\n"
  exit "${exit_status}"
}

function print_start_message {
  trap onexit_err ERR

  printf "${BCyan}\nStarting run of fast_spec_helper specs...${Color_Off}\n"
}

function run_fast_spec_helper_specs {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running specs which use fast_spec_helper and also run fast...${Color_Off}\n\n"

  # TIP: Add '--format=documentation --order=stable' when debugging flaky interaction between specs
  bin/rspec --tag=~uses_fast_spec_helper_but_runs_slow "${fast_spec_helper_specs[@]}"
}

function run_fast_spec_helper_specs_which_are_slow {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running specs which use fast_spec_helper but actually run slow...${Color_Off}\n\n"

  # NOTE: fails_if_sidekiq_not_configured tag is used to skip specs which require special local config for sidekiq
  bin/rspec --tag=uses_fast_spec_helper_but_runs_slow --tag=~fails_if_sidekiq_not_configured "${fast_spec_helper_specs[@]}"
}

function run_all_fast_spec_helper_specs_individually {
  trap onexit_err ERR

  printf "\n\n${BBlue}INDIVIDUALLY running all specs which use fast_spec_helper to ensure they run in isolation (this will be SLOW! Set SPEC_FILE_TO_START_AT to skip known-good spec files)...${Color_Off}\n\n"

  # NOTE: Override `SPEC_FILE_TO_START_AT` to the relative path of a specific file in order to skip specs which are already known to be passing
  SPEC_FILE_TO_START_AT="${SPEC_FILE_TO_START_AT:-${fast_spec_helper_specs[0]}}"

  for spec_file in "${fast_spec_helper_specs[@]}"; do
    if [ "${spec_file}" = "${SPEC_FILE_TO_START_AT}" ]; then
      printf "${BBlue}Starting individual spec runs at SPEC_FILE_TO_START_AT: '${SPEC_FILE_TO_START_AT}'${Color_Off}\n\n"
      START_RUNNING=true
    fi

    if [ -n "${START_RUNNING}" ]; then
      printf "${BBlue}Running spec '${spec_file}' individually:${Color_Off}\n"
      bin/rspec --tag=~fails_if_sidekiq_not_configured "$spec_file"
    fi
  done
}

function print_success_message {
  trap onexit_err ERR

  printf "\n✅✅✅ ${BGreen}All executed fast_spec_helper specs passed successfully!${Color_Off} ✅✅✅\n"
}

function main {
  trap onexit_err ERR

  # cd to gitlab root directory
  cd "$(dirname "${BASH_SOURCE[0]}")"/..

  # See https://github.com/koalaman/shellcheck/wiki/SC2207 for more context on this approach of creating an array
  fast_spec_helper_specs=()
  while IFS='' read -r line; do
      fast_spec_helper_specs+=("$line")
  done < <(git grep -l -E '^require .fast_spec_helper' -- '**/*_spec.rb')

  print_start_message

  if [ -n "${RUN_ALL_FAST_SPECS_INDIVIDUALLY}" ]; then
    run_all_fast_spec_helper_specs_individually
  else
    run_fast_spec_helper_specs
    run_fast_spec_helper_specs_which_are_slow
  fi

  print_success_message
}

main "$@"
