#!/usr/bin/env bash

# shellcheck disable=SC2059

BCyan='\033[1;36m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BBlue='\033[1;34m'
Color_Off='\033[0m'

# Exit handling
function onexit_err() {
  local exit_status=${1:-$?}
  printf "\n❌❌❌ ${BRed}Remote Development smoke test failed!${Color_Off} ❌❌❌\n"
  if [ "${REVEAL_RUBOCOP_TODO}" -ne 0 ]; then
    printf "\n(If the failure was due to rubocop, set REVEAL_RUBOCOP_TODO=0 to ignore TODOs)\n"
  fi
  exit "${exit_status}"
}
trap onexit_err ERR
set -o errexit

function print_start_message {
  printf "${BCyan}\nStarting Remote Development smoke test...${Color_Off}\n\n"
}

function run_rubocop {
  printf "${BBlue}Running RuboCop${Color_Off}\n\n"
  files_for_rubocop=()
  while IFS= read -r -d '' file; do
    files_for_rubocop+=("$file")
  done < <(find . -path './**/remote_development/*.rb' -print0)
  REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-1} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"
}

function run_rspec_fast {
  printf "\n\n${BBlue}Running backend RSpec fast specs${Color_Off}\n\n"

  # NOTE: We do not use `--tag rd_fast` here, because `rd_fast_spec_helper` has a check to ensure that all the
  #       files which require it are tagged with `rd_fast`.

  files_for_fast=()
  while IFS= read -r file; do
      files_for_fast+=("$file")
  done < <(find ee/spec -path '**/remote_development/*_spec.rb' -exec grep -lE 'require_relative.*rd_fast_spec_helper' {} +)

  bin/rspec "${files_for_fast[@]}"
}

function run_jest {
  printf "\n\n${BBlue}Running Remote Development frontend Jest specs${Color_Off}\n\n"
  yarn jest ee/spec/frontend/remote_development
}

function run_rspec_rails {
  printf "\n\n${BBlue}Running backend RSpec non-fast specs${Color_Off}\n\n"
  files_for_rails=()
  while IFS= read -r file; do
      files_for_rails+=("$file")
  done < <(find ee/spec -path '**/remote_development/*_spec.rb' | grep -v 'qa/qa' | grep -v '/features/')

  files_for_rails+=(
      "ee/spec/graphql/types/query_type_spec.rb"
      "ee/spec/graphql/types/subscription_type_spec.rb"
      "ee/spec/requests/api/internal/kubernetes_spec.rb"
      "spec/graphql/types/subscription_type_spec.rb"
      "spec/lib/result_spec.rb"
      "spec/support_specs/matchers/result_matchers_spec.rb"
  )

  bin/rspec -r spec_helper --tag ~rd_fast "${files_for_rails[@]}"
}

function run_rspec_feature {
  printf "\n\n${BBlue}Running backend RSpec feature specs${Color_Off}\n\n"
  files_for_feature=()
  while IFS= read -r file; do
      files_for_feature+=("$file")
  done < <(find ee/spec -path '**/remote_development/*_spec.rb' | grep -v 'qa/qa' | grep '/features/')

  bin/rspec -r spec_helper "${files_for_feature[@]}"
}

function print_success_message {
  printf "\n✅✅✅ ${BGreen}All executed linters/specs passed successfully!${Color_Off} ✅✅✅\n"
}

function main {
  # cd to gitlab root directory
  cd "$(dirname "${BASH_SOURCE[0]}")"/../..

  print_start_message

  # Run linting before tests
  [ -z "${SKIP_RUBOCOP}" ] && run_rubocop

  # Test sections are sorted roughly in increasing order of execution time.
  [ -z "${SKIP_FAST}" ] && run_rspec_fast
  [ -z "${SKIP_JEST}" ] && run_jest
  [ -z "${SKIP_RAILS}" ] && run_rspec_rails
  [ -z "${SKIP_FEATURE}" ] && run_rspec_feature

  print_success_message
}

main "$@"
