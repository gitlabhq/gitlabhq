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
  printf "\n❌❌❌ ${BRed}Remote Development smoke test failed!${Color_Off} ❌❌❌\n"
  if [ "${REVEAL_RUBOCOP_TODO}" -ne 0 ]; then
    printf "\n${BRed}- If the failure was due to rubocop, try setting REVEAL_RUBOCOP_TODO=0 to ignore TODOs${Color_Off}\n"
  fi

  printf "\n${BRed}- If the failure was in a feature spec, those sometimes are flaky, try running it focused${Color_Off}\n"

  exit "${exit_status}"
}

function print_start_message {
  trap onexit_err ERR

  printf "${BCyan}\nStarting Remote Development smoke test...${Color_Off}\n\n"
}

function run_rubocop {
  trap onexit_err ERR

  printf "${BBlue}Running RuboCop${Color_Off}\n\n"

  files_for_rubocop=()

  while IFS='' read -r file; do
    files_for_rubocop+=("$file")
  done < <(git ls-files -- '**/remote_development/*.rb' '**/gitlab/fp/*.rb' '*_rop_*.rb' '*railway_oriented_programming*.rb' '*_result_matchers*.rb')

  REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-1} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"
}

function run_fp {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec FP specs${Color_Off}\n\n"

  files_for_fp=()

  while IFS='' read -r file; do
      files_for_fp+=("$file")
  done < <(git ls-files -- '**/gitlab/fp/*_spec.rb')


  bin/rspec "${files_for_fp[@]}"
}

function run_rspec_fast {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec fast specs${Color_Off}\n\n"

  files_for_fast=()

  while IFS='' read -r file; do
      files_for_fast+=("$file")
  done < <(git grep -l -E '^require .fast_spec_helper' -- '**/remote_development/*_spec.rb')

  printf "Running rspec command:\n\n"
  printf "bin/rspec "
  printf "%s " "${files_for_fast[@]}"
  printf "\n\n"

  bin/rspec "${files_for_fast[@]}"
}

function run_jest {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running Remote Development frontend Jest specs${Color_Off}\n\n"
  yarn jest ee/spec/frontend/workspaces
}

function run_rspec_non_fast {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec non-fast specs${Color_Off}\n\n"

  files_for_non_fast=()

  while IFS='' read -r file; do
      files_for_non_fast+=("$file")
  done < <(git grep -L -E '^require .fast_spec_helper' -- '**/remote_development/*_spec.rb' | grep -v 'qa/qa' | grep -v '/features/')

  files_for_non_fast+=(
      "ee/spec/graphql/resolvers/clusters/agents_resolver_spec.rb"
      "ee/spec/graphql/types/query_type_spec.rb"
      "ee/spec/graphql/types/subscription_type_spec.rb"
      "ee/spec/models/ee/clusters/agent_spec.rb"
      "ee/spec/requests/api/internal/kubernetes_spec.rb"
      "spec/graphql/types/subscription_type_spec.rb"
      "spec/support_specs/matchers/result_matchers_spec.rb"
  )

  printf "Running rspec command:\n\n"
  printf "bin/rspec --format documentation "
  printf "%s " "${files_for_non_fast[@]}"
  printf "\n\n"

  bin/rspec --format documentation "${files_for_non_fast[@]}"
}

function run_rspec_feature {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec feature specs (NOTE: These sometimes are flaky (see https://gitlab.com/gitlab-org/gitlab/-/issues/478601)! If one fails, try running it focused, or just ignore it and let CI run it)...${Color_Off}\n\n"
  files_for_feature=()
  while IFS='' read -r file; do
      files_for_feature+=("$file")
  done < <(git ls-files -- '**/remote_development/*_spec.rb' | grep -v 'qa/qa' | grep '/features/')

  bin/rspec -r spec_helper "${files_for_feature[@]}"
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
  [ -z "${SKIP_FP}" ] && run_fp
  [ -z "${SKIP_FAST}" ] && run_rspec_fast
  [ -z "${SKIP_JEST}" ] && run_jest
  [ -z "${SKIP_NON_FAST}" ] && run_rspec_non_fast
  [ -z "${SKIP_FEATURE}" ] && run_rspec_feature

  # Convenience ENV vars to run focused sections, copy and paste as a prefix to script command, and remove the one(s) you want to run focused
  # SKIP_RUBOCOP=1 SKIP_FP=1 SKIP_FAST=1 SKIP_JEST=1 SKIP_NON_FAST=1 SKIP_FEATURE=1

  print_success_message
}

main "$@"
