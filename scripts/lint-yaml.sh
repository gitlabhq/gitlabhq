#!/usr/bin/env bash

set -euo pipefail

if ! command -v yamllint > /dev/null; then
  echo "ERROR: yamllint is not installed. For more information, see https://yamllint.readthedocs.io/en/stable/index.html."
  exit 1
fi

yamllint --strict -f colored "$@"
