#!/usr/bin/env bash
#
# Run the Remote Development smoke test suite.
#
# Usage: [ENV_VARS] ./scripts/remote_development/run-smoke-test-suite.sh [--help|-h]
#
# Environment variables:
#   ONLY_RUBOCOP=1        Run only rubocop
#   ONLY_RSPEC_FP=1       Run only FP specs
#   ONLY_RSPEC_FAST=1     Run only fast specs
#   ONLY_JEST=1           Run only jest specs
#   ONLY_RSPEC_NON_FAST=1 Run only non-fast specs
#   ONLY_RSPEC_FEATURE=1  Run only feature specs
#
#   SKIP_RUBOCOP=1        Skip rubocop
#   SKIP_RSPEC_FP=1       Skip FP specs
#   SKIP_RSPEC_FAST=1     Skip fast specs
#   SKIP_JEST=1           Skip jest specs
#   SKIP_RSPEC_NON_FAST=1 Skip non-fast specs
#   SKIP_RSPEC_FEATURE=1  Skip feature specs
#
# Examples:
#   ONLY_RSPEC_FAST=1 ONLY_RSPEC_NON_FAST=1 ./scripts/remote_development/run-smoke-test-suite.sh
#   SKIP_RSPEC_FEATURE=1 SKIP_JEST=1 ./scripts/remote_development/run-smoke-test-suite.sh
#
# Note on Rubocop:
#   By default, rubocop runs with REVEAL_RUBOCOP_TODO=1 and will fail even for violations
#   ignored via '.rubocop_todo/...'. This encourages proactive resolution of newly introduced
#   rubocop rule violations. To temporarily ignore TODOs, set REVEAL_RUBOCOP_TODO=0.
#
# Why is this script written in bash and has its logic duplicated across multiple features?
#
#   1. Bash handles interleaved STDOUT/STDERR streams correctly, preserving proper sequencing
#      and color output from nested subprocesses. This is difficult to achieve in Ruby.
#   2. We intentionally keep these scripts simple, linear, and minimal. Abstracting or DRYing
#      them up would lead to complexity creep: rewriting in Ruby, adding tests, creating gems,
#      and eventually building a whole framework. We avoid that path.
#   3. Each feature area can customize their script independently without coordination.
#
#   See: https://gitlab.com/gitlab-org/gitlab/-/issues/560531#note_2681672640
#        https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202481#note_2706447700
#

# shellcheck disable=SC2059

BCyan='\033[1;36m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BBlue='\033[1;34m'
Color_Off='\033[0m'

set -o errexit
set -o nounset
set -o pipefail
trap onexit_err ERR

# Exit handling
function onexit_err() {
  local exit_status=${1:-$?}
  printf "\n❌❌❌ ${BRed}Remote Development smoke test failed!${Color_Off} ❌❌❌\n"
  if [ "${REVEAL_RUBOCOP_TODO:-1}" -ne 0 ]; then
    printf "\n${BRed}- If the failure was due to rubocop, try setting REVEAL_RUBOCOP_TODO=0 to ignore TODOs${Color_Off}\n"
  fi

  printf "\n${BRed}- If the failure was in a feature spec, those sometimes are flaky, try running it focused${Color_Off}\n"
  printf "\n${BRed}- If the failure was jest and may be due to fixtures, run 'bin/rake frontend:fixtures' and try again${Color_Off}\n"

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
  done < <(git ls-files -- '**/remote_development/*.rb' '**/remote_development/**/*.rb' '**/gitlab/fp/*.rb' '**/gitlab/fp/**/*.rb' '*_rop_*.rb' '*railway_oriented_programming*.rb' '*_result_matchers*.rb')

  REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-1} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"
}

function run_rspec_fp {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec FP specs${Color_Off}\n\n"

  files_for_rspec_fp=()

  while IFS='' read -r file; do
      files_for_rspec_fp+=("$file")
  done < <(git ls-files -- '**/gitlab/fp/*_spec.rb' '**/gitlab/fp/**/*_spec.rb')


  bin/rspec "${files_for_rspec_fp[@]}"
}

function run_rspec_fast {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec fast specs${Color_Off}\n\n"

  files_for_rspec_fast=()

  while IFS='' read -r file; do
      files_for_rspec_fast+=("$file")
  done < <(git grep -l -E '^require .fast_spec_helper' -- '**/remote_development/*_spec.rb' '**/remote_development/**/*_spec.rb')

  if [ ${#files_for_rspec_fast[@]} -eq 0 ]; then
    printf "No fast specs found, skipping.\n"
    return
  fi

  printf "Running rspec fast command:\n\n"
  printf "bin/rspec "
  printf "%s " "${files_for_rspec_fast[@]}"
  printf "\n\n"

  bin/rspec "${files_for_rspec_fast[@]}"
}

function run_jest {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running 'yarn check --integrity' and 'yarn install' if needed${Color_Off}\n\n"
  yarn check --integrity || yarn install

  printf "\n\n${BBlue}Running Remote Development frontend Jest specs${Color_Off}\n\n"
  yarn jest ee/spec/frontend/workspaces
}

function run_rspec_non_fast {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec non-fast specs${Color_Off}\n\n"

  files_for_rspec_non_fast=()

  # Note that we do NOT exclude the fast_spec_helper specs here, because sometimes specs may pass
  # when run with fast_spec_helper, but fail when run with the full spec_helper. This happens when
  # they are run as part of a larger suite of mixed fast and slow files, for example, in CI jobs.
  # Running all fast and slow specs here ensures that we catch those cases.
  while IFS='' read -r file; do
      files_for_rspec_non_fast+=("$file")
  done < <(git ls-files -- '**/remote_development/*_spec.rb' '**/remote_development/**/*_spec.rb' | grep -v 'qa/qa' | grep -v '/features/')

  files_for_rspec_non_fast+=(
      "ee/spec/graphql/ee/resolvers/clusters/agents_resolver_spec.rb"
      "ee/spec/graphql/types/query_type_spec.rb"
      "ee/spec/graphql/ee/types/subscription_type_spec.rb"
      "ee/spec/models/ee/clusters/agent_spec.rb"
      "ee/spec/requests/api/internal/kubernetes_spec.rb"
      "spec/graphql/types/subscription_type_spec.rb"
      "spec/support_specs/matchers/result_matchers_spec.rb"
  )

  printf "Running rspec non-fast command:\n\n"
  printf "bin/rspec --format documentation "
  printf "%s " "${files_for_rspec_non_fast[@]}"
  printf "\n\n"

  bin/rspec --format documentation "${files_for_rspec_non_fast[@]}"
}

function run_rspec_feature {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec feature specs${Color_Off}\n\n"
  files_for_rspec_feature=()
  while IFS='' read -r file; do
      files_for_rspec_feature+=("$file")
  done < <(git ls-files -- '**/remote_development/*_spec.rb' '**/remote_development/**/*_spec.rb' | grep -v 'qa/qa' | grep '/features/')

  bin/rspec --format documentation -r spec_helper "${files_for_rspec_feature[@]}"
}

function print_success_message {
  printf "\n✅✅✅ ${BGreen}All executed linters/specs passed successfully!${Color_Off} ✅✅✅\n"
}

function print_usage {
  awk 'NR==1{next} /^$/{exit} /^#/{gsub(/^# ?/,""); print}' "${BASH_SOURCE[0]}"
  exit 0
}

function should_run {
  local section=$1
  local only_var="ONLY_${section}"
  local skip_var="SKIP_${section}"

  # If any ONLY_* var is set, run only those sections; otherwise use SKIP_* behavior
  if [ -n "${ONLY_RUBOCOP:-}${ONLY_RSPEC_FP:-}${ONLY_RSPEC_FAST:-}${ONLY_JEST:-}${ONLY_RSPEC_NON_FAST:-}${ONLY_RSPEC_FEATURE:-}" ]; then
    [ -n "${!only_var:-}" ]
  else
    [ -z "${!skip_var:-}" ]
  fi
}

function main {
  trap onexit_err ERR

  case "${1:-}" in --help|-h) print_usage ;; esac

  # Ensure we were not invoked via a non-bash shell which overrode the /bin/bash shebang
  [ -n "${BASH_VERSION:-}" ] || { printf "\n❌❌❌ ${BRed}Please run with bash${Color_Off} ❌❌❌\n" >&2; exit 1; }

  # cd to gitlab root directory
  cd "$(dirname "${BASH_SOURCE[0]}")"/../..

  # ensure mise is activated for gitlab directory (if we were invoked from a different directory)
  command -v mise >/dev/null 2>&1 || { printf "\n❌❌❌ ${BRed}mise is required, please install it${Color_Off} ❌❌❌\n" >&2; exit 1; }
  eval "$(mise activate bash)"

  print_start_message

  # Run linting before tests
  should_run RUBOCOP && run_rubocop

  # Test sections are sorted roughly in increasing order of execution time, in order to get the fastest feedback on failures.
  should_run RSPEC_FP && run_rspec_fp
  should_run RSPEC_FAST && run_rspec_fast
  should_run JEST && run_jest
  should_run RSPEC_NON_FAST && run_rspec_non_fast
  should_run RSPEC_FEATURE && run_rspec_feature

  print_success_message
}

main "$@"
