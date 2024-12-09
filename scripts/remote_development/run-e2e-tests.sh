#!/usr/bin/env zsh

# frozen_string_literal: true

# This is a convenience script to run the Remote Development category E2E spec(s) against a local
# GDK environment. It sets default values for the necessary environment variables, but allows
# them to be overridden.
#
# For details on how to run this, see the documentation comments at the top of
# qa/qa/specs/features/ee/browser_ui/3_create/remote_development/with_prerequisite_done/workspace_actions_with_prerequisite_done_spec.rb

DEFAULT_PASSWORD='5iveL!fe'

export WEBDRIVER_HEADLESS="${WEBDRIVER_HEADLESS:-0}"
export GITLAB_USERNAME="${GITLAB_USERNAME:-root}"
export GITLAB_INITIAL_ROOT_PASSWORD="${GITLAB_INITIAL_ROOT_PASSWORD:-${DEFAULT_PASSWORD}}"
export GITLAB_QA_ACCESS_TOKEN="${GITLAB_QA_ACCESS_TOKEN:-${PERSONAL_ACCESS_TOKEN}}"
export DEVFILE_PROJECT="${DEVFILE_PROJECT:-Gitlab Org / Gitlab Shell}"
export AGENT_NAME="${AGENT_NAME:-remotedev}"
export TEST_INSTANCE_URL="${TEST_INSTANCE_URL:-http://gdk.test:3000}"

if [[ -z "${GITLAB_QA_ACCESS_TOKEN}" ]]; then
  echo
  echo "NOTE: GITLAB_QA_ACCESS_TOKEN is not set. This causes the E2E spec to create a personal access token for the logged in user, which results in a slower test run."
  echo "      This can be skipped by passing the environment variable GITLAB_QA_ACCESS_TOKEN (or PERSONAL_ACCESS_TOKEN) with a valid PAT for the test instance."
  echo
fi

echo "WEBDRIVER_HEADLESS: ${WEBDRIVER_HEADLESS}"
echo "GITLAB_USERNAME: ${GITLAB_USERNAME}"
echo "DEVFILE_PROJECT: ${DEVFILE_PROJECT}"
echo "AGENT_NAME: ${AGENT_NAME}"
echo "TEST_INSTANCE_URL: ${TEST_INSTANCE_URL}"

working_directory="$(git rev-parse --show-toplevel)/qa"

#  This test is currently quarantined as its only used for local testing, so we have to use the '--tag quarantine'
(cd "$working_directory" && \
  bundle && \
  bundle exec bin/qa Test::Instance::All "$TEST_INSTANCE_URL" -- \
  --tag quarantine qa/specs/features/ee/browser_ui/3_create/remote_development/with_prerequisite_done/workspace_actions_with_prerequisite_done_spec.rb)
