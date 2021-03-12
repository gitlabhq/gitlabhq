#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# The yarn run command we'd like to run
command="$1"
# The file types we'd like to target, use something like '(js|vue)'
file_types="$2"

# Removing first two arguments
shift
shift

# Read all staged non-deleted files into an array
staged_files=()
while IFS= read -r line; do
    staged_files+=( "$line" )
done < <( git diff --diff-filter=d --cached --name-only | { grep -E ".$file_types$" || true; })

if [ "${#staged_files[@]}" == "0" ]; then
    echo "No staged '$file_types' files"
else
    echo "Running $command on ${#staged_files[@]} staged '$file_types' files"
    yarn run "$command" "$@" "${staged_files[@]}"
fi
