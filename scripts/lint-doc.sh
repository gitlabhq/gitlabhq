#!/usr/bin/env bash

cd "$(dirname "$0")/.."

# Use long options (e.g. --header instead of -H) for curl examples in documentation.
grep --perl-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/
if [ $? == 0 ]
then
  echo '✖ ERROR: Short options should not be used in documentation!' >&2
  exit 1
fi

echo "✔ Linting passed"
exit 0

