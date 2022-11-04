#!/usr/bin/env bash

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
  printf "\n❌❌❌ ${BRed}GLFM snapshot tests failed!${Color_Off} ❌❌❌\n"
  exit "${exit_status}"
}
trap onexit_err ERR
set -o errexit

printf "${BCyan}"
printf "\nStarting GLFM snapshot example tests. See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#run-snapshot-testssh-script for more details.\n\n"
printf "Set 'FOCUSED_MARKDOWN_EXAMPLES=example_name_1[,...]' for focused examples, with example name(s) from https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#glfm_specificationexample_snapshotsexamples_indexyml.\n"
printf "${Color_Off}"

# NOTE: Unlike the backend markdown_snapshot_spec.rb which has a CE and EE version, there is only
# one version of this spec. This is because the frontend markdown rendering does not require EE-only
# backend features.
printf "\n${BBlue}Running frontend 'yarn jest spec/frontend/content_editor/markdown_snapshot_spec.js'...${Color_Off}\n\n"
yarn jest spec/frontend/content_editor/markdown_snapshot_spec.js
printf "\n${BBlue}'yarn jest spec/frontend/content_editor/markdown_snapshot_spec.js' passed!${Color_Off}\n\n"

printf "\n${BBlue}Running CE backend 'bundle exec rspec spec/requests/api/markdown_snapshot_spec.rb'...${Color_Off}\n\n"
bundle exec rspec spec/requests/api/markdown_snapshot_spec.rb
printf "\n${BBlue}'bundle exec rspec spec/requests/api/markdown_snapshot_spec.rb' passed!${Color_Off}\n\n"

printf "\n${BBlue}Running EE backend 'bundle exec rspec ee/spec/requests/api/markdown_snapshot_spec.rb'...${Color_Off}\n\n"
bundle exec rspec ee/spec/requests/api/markdown_snapshot_spec.rb
printf "\n${BBlue}'bundle exec rspec ee/spec/requests/api/markdown_snapshot_spec.rb' passed!${Color_Off}\n\n"

printf "\n✅✅✅ ${BGreen}All GLFM snapshot example tests passed successfully!${Color_Off} ✅✅✅\n"
