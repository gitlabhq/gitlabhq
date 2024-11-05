#!/bin/bash

if ! command -v sg &> /dev/null; then
  printf "Command not found: sg\nPlease install ast-grep first: https://ast-grep.github.io/guide/quick-start.html\n"
  exit 1
fi

# Check if the path to the folder is provided
if [ -z "$1" ]; then
  echo "Missing folder to the Vuex store. Usage: $0 <path_to_folder>"
  exit 1
fi

SCRIPT_PATH=$(realpath $0)
CODEMODS_PATH=$(dirname $SCRIPT_PATH)
FOLDER_PATH=$1
PARTS=("actions" "getters" "mutations")

for item in "${PARTS[@]}"; do
  FULL_PATH="${FOLDER_PATH}/${item}.js"

  if [[ -f "$FULL_PATH" ]]; then
    while ! sg scan "$FULL_PATH" --rule "$CODEMODS_PATH/body.yml" --report-style short; do
      sg scan "$FULL_PATH" --rule "$CODEMODS_PATH/body.yml" -U
    done

    sg scan "$FULL_PATH" --rule "$CODEMODS_PATH/$item.yml" -U

    echo "$FULL_PATH migrated successfully."
  else
    echo "$FULL_PATH doesn't exist, skipping."
  fi
done

echo "Migration completed. Please verify each file manually."
