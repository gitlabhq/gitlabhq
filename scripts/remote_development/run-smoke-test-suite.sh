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

# NOTE: For some reason this test started causing the following spec file in the list to blow up with
#       "Failed to write to log, write log/workhorse-test.log: file already closed". Just removing
#       it for now.
# ee/spec/graphql/api/workspace_spec.rb

bin/spring rspec -r spec_helper \
ee/spec/features/remote_development/workspaces_spec.rb \
ee/spec/finders/remote_development/workspaces_finder_spec.rb \
ee/spec/graphql/types/query_type_spec.rb \
ee/spec/graphql/types/remote_development/workspace_type_spec.rb \
ee/spec/graphql/types/subscription_type_spec.rb \
ee/spec/lib/remote_development/agent_config/main_integration_spec.rb \
ee/spec/lib/remote_development/unmatched_result_error_spec.rb \
ee/spec/lib/remote_development/workspaces/create/create_processor_spec.rb \
ee/spec/lib/remote_development/workspaces/create/devfile_processor_spec.rb \
ee/spec/lib/remote_development/workspaces/create/devfile_validator_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/actual_state_calculator_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/agent_info_parser_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/agent_info_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/desired_config_generator_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/params_parser_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/reconcile_processor_scenarios_spec.rb \
ee/spec/lib/remote_development/workspaces/reconcile/reconcile_processor_spec.rb \
ee/spec/lib/remote_development/workspaces/states_spec.rb \
ee/spec/lib/remote_development/workspaces/update/authorizer_spec.rb \
ee/spec/lib/remote_development/workspaces/update/main_integration_spec.rb \
ee/spec/lib/remote_development/workspaces/update/main_spec.rb \
ee/spec/lib/remote_development/workspaces/update/updater_spec.rb \
ee/spec/models/remote_development/remote_development_agent_config_spec.rb \
ee/spec/models/remote_development/workspace_spec.rb \
ee/spec/requests/api/graphql/mutations/remote_development/workspaces/create_spec.rb \
ee/spec/requests/api/graphql/mutations/remote_development/workspaces/update_spec.rb \
ee/spec/requests/api/graphql/remote_development/current_user_workspaces_spec.rb \
ee/spec/requests/api/graphql/remote_development/workspace_by_id_spec.rb \
ee/spec/requests/api/graphql/remote_development/workspaces_by_ids_spec.rb \
ee/spec/requests/api/internal/kubernetes_spec.rb \
ee/spec/services/remote_development/agent_config/update_service_spec.rb \
ee/spec/services/remote_development/workspaces/create_service_spec.rb \
ee/spec/services/remote_development/workspaces/reconcile_service_spec.rb \
ee/spec/services/remote_development/workspaces/update_service_spec.rb \
spec/graphql/types/subscription_type_spec.rb \
spec/lib/result_spec.rb \
spec/support_specs/matchers/result_matchers_spec.rb

printf "\n✅✅✅ ${BGreen}All Remote Development specs passed successfully!${Color_Off} ✅✅✅\n"
