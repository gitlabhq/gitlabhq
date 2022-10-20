#!/usr/bin/env bash

set -euo pipefail

for file in "$@"
do
  yarn run -s jsonlint -p "$file" | perl -pe 'chomp if eof' | diff "$file" -
done
