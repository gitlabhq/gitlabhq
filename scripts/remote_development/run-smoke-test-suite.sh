#!/usr/bin/env bash

# This script runs a suite of non-E2E specs related to the Remote Development category, as
# a pre-commit/pre-push "Smoke Test" to catch any broken tests without having to wait
# on CI to catch them. Note that there are some shared/common specs related to
# Remote Development which are not included in this suite.
# https://en.wikipedia.org/wiki/Smoke_testing_(software)

# shellcheck disable=SC2059

set -o errexit # AKA -e - exit immediately on errors (http://mywiki.wooledge.org/BashFAQ/105)

###########
## Setup ##
###########

# https://stackoverflow.com/a/28938235
BCyan='\033[1;36m' # Bold Cyan
BRed='\033[1;31m' # Bold Red
BGreen='\033[1;32m' # Bold Green
BBlue='\033[1;34m' # Bold Blue
Color_Off='\033[0m' # Text Reset

function onexit_err() {
  local exit_status=${1:-$?}
  printf "\n❌❌❌ ${BRed}Remote Development smoke test failed!${Color_Off} ❌❌❌\n"

  if [ ${REVEAL_RUBOCOP_TODO} -ne 0 ]; then
    printf "\n(If the failure was due to rubocop, set REVEAL_RUBOCOP_TODO=0 to ignore TODOs)\n"
  fi

  exit "${exit_status}"
}
trap onexit_err ERR
set -o errexit

#####################
## Invoke commands ##
#####################

printf "${BCyan}\nStarting Remote Development smoke test...\n\n${Color_Off}"

#############
## RUBOCOP ##
#############

printf "${BBlue}Running RuboCop for Remote Development and related files${Color_Off}\n\n"

# TODO: Also run rubocop for the other non-remote-development files once they are passing rubocop
#       with REVEAL_RUBOCOP_TODO=1
while IFS= read -r -d '' file; do
  files_for_rubocop+=("$file")
done < <(find . -path './**/remote_development/*.rb' -print0)

REVEAL_RUBOCOP_TODO=${REVEAL_RUBOCOP_TODO:-1} bundle exec rubocop --parallel --force-exclusion --no-server "${files_for_rubocop[@]}"

##########
## JEST ##
##########

printf "\n\n${BBlue}Running Remote Development frontend Jest specs${Color_Off}\n\n"

yarn jest ee/spec/frontend/remote_development

#######################
## RSPEC NON-FEATURE ##
#######################

printf "\n\n${BBlue}Running Remote Development and related backend RSpec non-selenium specs${Color_Off}\n\n"

while IFS= read -r file; do
    files_for_rspec+=("$file")
done < <(find . -path './**/remote_development/*_spec.rb' | grep -v 'qa/qa' | grep -v '/features/')

files_for_rspec+=(
    "ee/spec/graphql/types/query_type_spec.rb"
    "ee/spec/graphql/types/subscription_type_spec.rb"
    "ee/spec/requests/api/internal/kubernetes_spec.rb"
    "spec/graphql/types/subscription_type_spec.rb"
    "spec/lib/result_spec.rb"
    "spec/support_specs/matchers/result_matchers_spec.rb"
)
bin/rspec -r spec_helper "${files_for_rspec[@]}"

###################
## RSPEC FEATURE ##
###################

printf "\n\n${BBlue}Running Remote Development and related backend RSpec feature specs${Color_Off}\n\n"

while IFS= read -r file; do
    files_for_rspec_selenium+=("$file")
done < <(find . -path './**/remote_development/*_spec.rb' | grep -v 'qa/qa' | grep '/features/')

printf "\n${BRed}SKIPPING FEATURE SPECS, THEY ARE CURRENTLY BROKEN. SEE https://gitlab.slack.com/archives/C3JJET4Q6/p1702638503864429 and https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140015${Color_Off} ❌❌❌\n"
# bin/rspec -r spec_helper "${files_for_rspec_selenium[@]}"

###########################
## Print success message ##
###########################

printf "\n✅✅✅ ${BGreen}All Remote Development specs passed successfully!${Color_Off} ✅✅✅\n"
