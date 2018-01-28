#!/usr/bin/env bash

cd "$(dirname "$0")/.."

# Use long options (e.g. --header instead of -H) for curl examples in documentation.
echo 'Checking for curl short options...'
grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/ >/dev/null 2>&1
if [ $? == 0 ]
then
  echo '✖ ERROR: Short options for curl should not be used in documentation!
         Use long options (e.g., --header instead of -H):' >&2
  grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/
  exit 1
fi

# Ensure that the CHANGELOG.md does not contain duplicate versions
DUPLICATE_CHANGELOG_VERSIONS=$(grep --extended-regexp '^## .+' CHANGELOG.md | sed -E 's| \(.+\)||' | sort -r | uniq -d)
echo 'Checking for CHANGELOG.md duplicate entries...'
if [ "${DUPLICATE_CHANGELOG_VERSIONS}" != "" ]
then
  echo '✖ ERROR: Duplicate versions in CHANGELOG.md:' >&2
  echo "${DUPLICATE_CHANGELOG_VERSIONS}" >&2
  exit 1
fi

# Make sure no files in doc/ are executable
EXEC_PERM_COUNT=$(find doc/ app/ -type f -perm 755 | wc -l)
echo 'Checking for executable permissions...'
if [ "${EXEC_PERM_COUNT}" -ne 0 ]
then
  echo '✖ ERROR: Executable permissions should not be used in documentation! Use `chmod 644` to the files in question:' >&2
  find doc/ app/ -type f -perm 755
  exit 1
fi

echo "✔ Linting passed"
exit 0
