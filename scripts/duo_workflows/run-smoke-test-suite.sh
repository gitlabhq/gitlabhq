#!/usr/bin/env bash
#
# Run the Duo Workflows smoke test suite.
#
# Usage: [ENV_VARS] ./scripts/duo_workflows/run-smoke-test-suite.sh [--help|-h]
#
# Environment variables:
#   ONLY_RUBOCOP=1  Run only rubocop
#   ONLY_RSPEC=1    Run only rspec specs
#   ONLY_JEST=1     Run only jest specs
#
#   SKIP_RUBOCOP=1  Skip rubocop
#   SKIP_RSPEC=1    Skip rspec specs
#   SKIP_JEST=1     Skip jest specs
#
# Examples:
#   ONLY_RSPEC=1 ./scripts/duo_workflows/run-smoke-test-suite.sh
#   SKIP_JEST=1 ./scripts/duo_workflows/run-smoke-test-suite.sh
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
  printf "\n❌❌❌ ${BRed}Duo workflows smoke test failed!${Color_Off} ❌❌❌\n"
  if [ "${REVEAL_RUBOCOP_TODO:-0}" -ne 0 ]; then
    printf "\n${BRed}- If the failure was due to rubocop, try setting REVEAL_RUBOCOP_TODO=0 to ignore TODOs${Color_Off}\n"
  fi

  printf "\n${BRed}- If the failure was in a feature spec, those are sometimes flaky. Try running again, or run the test in isolation${Color_Off}\n"
  printf "\n${BRed}- If the failure was jest and may be due to fixtures, run 'bin/rake frontend:fixtures' and try again${Color_Off}\n"

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
  done < <(git ls-files -- '*/duo_workflows*.rb' '*/duo_workflow*.rb')

  REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-0} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"
}

function run_rspec {
  trap onexit_err ERR

  printf "\n\n${BBlue}Running backend RSpec specs${Color_Off}. Use SKIP_RSPEC=1 to skip this check\n\n"

  printf "Running rspec command:\n\n"

  git ls-files -- '*/duo_workflows*_spec.rb' '*/duo_workflow*_spec.rb' | xargs bin/rspec -fd
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

function print_usage {
  awk 'NR==1{next} /^$/{exit} /^#/{gsub(/^# ?/,""); print}' "${BASH_SOURCE[0]}"
  exit 0
}

function should_run {
  local section=$1
  local only_var="ONLY_${section}"
  local skip_var="SKIP_${section}"

  # If any ONLY_* var is set, run only those sections; otherwise use SKIP_* behavior
  if [ -n "${ONLY_RUBOCOP:-}${ONLY_RSPEC:-}${ONLY_JEST:-}" ]; then
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
  should_run RSPEC && run_rspec
  should_run JEST && run_jest

  print_success_message
}

main "$@"
