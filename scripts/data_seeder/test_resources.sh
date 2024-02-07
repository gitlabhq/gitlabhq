#!/usr/bin/env bash
# this script ...
# - sparse clones the gitlab repo (with a specific ref) only targeting the spec and ee/spec directories.
# - moves the spec and ee/spec directories to the gitlab-rails service directory within Docker.
set -euo pipefail

ref=${REF:-master}
tmp=$(mktemp -d)
git clone --single-branch --branch "$ref" https://gitlab.com/gitlab-org/gitlab.git --no-checkout --depth 1 "${tmp}"
cd "${tmp}"
git sparse-checkout init --cone; git sparse-checkout add spec ee/spec; git checkout
echo "Checked out ${ref}"
mv spec /opt/gitlab/embedded/service/gitlab-rails; mv ee/spec /opt/gitlab/embedded/service/gitlab-rails/ee
