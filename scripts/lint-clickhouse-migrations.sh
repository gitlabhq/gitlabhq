#!/usr/bin/env bash

set -euo pipefail

FILE="db/click_house/main.sql"

if [ ! -f "$FILE" ]; then
  # Return early if the file does not exist.
  exit 0
fi

# Find lines containing a password declaration, but filter out the allowed
# placeholder password. If any lines remain, it means a hardcoded password is present.
# The `|| true` is to prevent the script from exiting if grep finds no matches.
HARDCODED_PASS_LINES=$(grep "PASSWORD '" "$FILE" | grep -v "PASSWORD '\$DICTIONARY_PASSWORD'" || true)

if [ -n "$HARDCODED_PASS_LINES" ]; then
    echo "ERROR: Hardcoded password found in $FILE. Please use 'PASSWORD '\$DICTIONARY_PASSWORD'' for dictionary passwords." >&2
    echo "The following lines contain hardcoded passwords:" >&2
    echo "$HARDCODED_PASS_LINES" >&2
    exit 1
fi

exit 0
