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
export GITLAB_PASSWORD="${GITLAB_PASSWORD:-${DEFAULT_PASSWORD}}"
export DEVFILE_PROJECT="${DEVFILE_PROJECT:-Gitlab Org / Gitlab Shell}"
export AGENT_NAME="${AGENT_NAME:-remotedev}"
export TEST_INSTANCE_URL="${TEST_INSTANCE_URL:-http://gdk.test:3000}"

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
