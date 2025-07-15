#!/usr/bin/env bash
set -e

echo "Checking if localized documentation files have matching English originals..."
FAILED_ROUTES=()
check_file_exists() {
  local locale_file=$1
  local original_file=$2
  
  if [ ! -f "$original_file" ]; then
    echo "Error: Original English file does not exist: $original_file"
    echo "For localized file: $locale_file"
    FAILED_ROUTES+=("$original_file → $locale_file")
    return 1
  else
    echo "Verified: $locale_file → $original_file"
    return 0
  fi
}

FAILED=0

echo "Checking for localized pages without English equivalents..."
while IFS= read -r locale_file; do
  lang_code=$(echo "$locale_file" | sed 's|doc-locale/\([^/]*\)/.*|\1|')
  file_path=$(echo "$locale_file" | sed "s|doc-locale/$lang_code/||")
  
  original_file="doc/$file_path"
  
  if ! check_file_exists "$locale_file" "$original_file"; then
    FAILED=1
  fi
done < <(find doc-locale -type f -name "*.md" -print0 | tr '\0' '\n')

if [ $FAILED -ne 0 ]; then
  echo -e "\n❌ Path verification failed: Found ${#FAILED_ROUTES[@]} localized files without matching English originals.\n"
  echo -e "===== MISSING ENGLISH ORIGINALS =====\n"
  echo -e "MISSING ENGLISH PATH => LOCALIZED VERSION"
  echo -e "----------------------------------------"
  for route in "${FAILED_ROUTES[@]}"; do
    echo "$route"
  done
  echo -e "\n====================================="
  echo -e "Please ensure all localized content has corresponding English files.\n"
  exit 1
else
  echo -e "\n✅ Verification successful! All localized files have matching English originals."
fi
