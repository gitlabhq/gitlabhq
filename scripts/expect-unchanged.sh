#!/bin/sh

set -o errexit
set -o nounset

file_name=$1
git diff --exit-code "${file_name}" || (
  echo "Expected ${file_name} to be unchanged. Did you forget to commit it?"
  exit 1
)
