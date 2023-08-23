#!/usr/bin/env bash

# This script runs a suite of non-E2E specs related to the Remote Development category, as
# a pre-commit/pre-push "Smoke Test" to catch any broken tests without having to wait
# on CI to catch them. Note that there are some shared/common specs related to
# Remote Development which are not included in this suite.
# https://en.wikipedia.org/wiki/Smoke_testing_(software)

# shellcheck disable=SC2059

set -o errexit # AKA -e - exit immediately on errors (http://mywiki.wooledge.org/BashFAQ/105)

# https://stackoverflow.com/a/28938235
BCyan='\033[1;36m' # Bold Cyan
BRed='\033[1;31m' # Bold Red
BGreen='\033[1;32m' # Bold Green
BBlue='\033[1;34m' # Bold Blue
Color_Off='\033[0m' # Text Reset

function onexit_err() {
  local exit_status=${1:-$?}
  printf "\n❌❌❌ ${BRed}Remote Development specs failed!${Color_Off} ❌❌❌\n"
  exit "${exit_status}"
}
trap onexit_err ERR
set -o errexit

printf "${BCyan}"
printf "\nStarting Remote Development specs.\n\n"
printf "${Color_Off}"

printf "${BBlue}Running Remote Development backend specs${Color_Off}\n\n"

bin/rspec -r spec_helper \
$(find . -path './**/remote_development/*_spec.rb' | grep -v 'qa/qa') \
ee/spec/graphql/types/query_type_spec.rb \
ee/spec/graphql/types/subscription_type_spec.rb \
ee/spec/requests/api/internal/kubernetes_spec.rb \
spec/graphql/types/subscription_type_spec.rb \
spec/lib/result_spec.rb \
spec/support_specs/matchers/result_matchers_spec.rb

printf "\n✅✅✅ ${BGreen}All Remote Development specs passed successfully!${Color_Off} ✅✅✅\n"
