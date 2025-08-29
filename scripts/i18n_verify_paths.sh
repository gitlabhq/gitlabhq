#!/usr/bin/env bash

# Script to verify that all localized documentation files have matching English originals
# Exit codes:
#   0 - All localized files have matching English originals
#   1 - One or more localized files are missing English originals
#   2 - Found files with unexpected path format

set -euo pipefail

echo "Checking if localized documentation files have matching English originals..."

# Track different types of issues
FAILED_ROUTES=()
UNEXPECTED_PATHS=()

check_file_exists() {
  local locale_file=$1
  local original_file=$2
  
  if [[ ! -f "$original_file" ]]; then
    echo "Error: Original English file does not exist: $original_file" >&2
    echo "For localized file: $locale_file" >&2
    FAILED_ROUTES+=("$original_file → $locale_file")
    return 1
  else
    echo "Verified: $locale_file → $original_file"
    return 0
  fi
}

FAILED=0

echo "Checking for localized pages without English equivalents..."
while IFS= read -r -d '' locale_file; do
  if [[ "$locale_file" =~ ^doc-locale/[^/]+/(.+)$ ]]; then
    file_path="${BASH_REMATCH[1]}"
  else
    echo "Warning: Unexpected path format: $locale_file" >&2
    UNEXPECTED_PATHS+=("$locale_file")
    continue  # Skip this file but track it
  fi
  
  original_file="doc/$file_path"
  
  if ! check_file_exists "$locale_file" "$original_file"; then
    FAILED=1
  fi
done < <(find doc-locale -type f -name "*.md" -print0)

# Check for unexpected path formats first
if [[ ${#UNEXPECTED_PATHS[@]} -gt 0 ]]; then
  echo -e "\n❌ Path format verification failed: Found ${#UNEXPECTED_PATHS[@]} files with unexpected path format:\n" >&2
  echo -e "===== UNEXPECTED PATH FORMATS =====" >&2
  echo -e "Expected: doc-locale/<language_code>/<path>" >&2
  echo -e "Found:" >&2
  for path in "${UNEXPECTED_PATHS[@]}"; do
    echo "  - $path" >&2
  done
  echo -e "=====================================\n" >&2
  echo -e "Please ensure all files follow the expected directory structure.\n" >&2
  exit 2
fi

# Then check for missing English originals
if [[ $FAILED -ne 0 ]]; then
  echo -e "\n❌ Path verification failed: Found ${#FAILED_ROUTES[@]} localized files without matching English originals.\n" >&2
  echo -e "===== MISSING ENGLISH ORIGINALS =====\n" >&2
  echo -e "MISSING ENGLISH PATH => LOCALIZED VERSION" >&2
  echo -e "----------------------------------------" >&2
  for route in "${FAILED_ROUTES[@]}"; do
    echo "$route" >&2
  done
  echo -e "\n=====================================" >&2
  echo -e "Please ensure all localized content has corresponding English files.\n" >&2
  exit 1
else
  echo -e "\n✅ Verification successful! All localized files have matching English originals."
fi
