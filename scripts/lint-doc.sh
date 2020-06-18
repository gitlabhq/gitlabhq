#!/usr/bin/env bash

cd "$(dirname "$0")/.."
echo "=> Linting documents at path $(pwd) as $(whoami)..."
echo
ERRORCODE=0

# Use long options (e.g. --header instead of -H) for curl examples in documentation.
echo '=> Checking for cURL short options...'
echo
grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/ >/dev/null 2>&1
if [ $? -eq 0 ]
then
  echo '✖ ERROR: Short options for curl should not be used in documentation!
         Use long options (e.g., --header instead of -H):' >&2
  grep --extended-regexp --recursive --color=auto 'curl (.+ )?-[^- ].*' doc/
  ((ERRORCODE++))
fi

# Ensure that the CHANGELOG.md does not contain duplicate versions
DUPLICATE_CHANGELOG_VERSIONS=$(grep --extended-regexp '^## .+' CHANGELOG.md | sed -E 's| \(.+\)||' | sort -r | uniq -d)
echo '=> Checking for CHANGELOG.md duplicate entries...'
echo
if [ "${DUPLICATE_CHANGELOG_VERSIONS}" != "" ]
then
  echo '✖ ERROR: Duplicate versions in CHANGELOG.md:' >&2
  echo "${DUPLICATE_CHANGELOG_VERSIONS}" >&2
  ((ERRORCODE++))
fi

# Make sure no files in doc/ are executable
EXEC_PERM_COUNT=$(find doc/ -type f -perm 755 | wc -l)
echo "=> Checking $(pwd)/doc for executable permissions..."
echo
if [ "${EXEC_PERM_COUNT}" -ne 0 ]
then
  echo '✖ ERROR: Executable permissions should not be used in documentation! Use `chmod 644` to the files in question:' >&2
  find doc/ -type f -perm 755
  ((ERRORCODE++))
fi

# Do not use 'README.md', instead use 'index.md'
# Number of 'README.md's as of 2020-05-28
NUMBER_READMES=45
FIND_READMES=$(find doc/ -name "README.md" | wc -l)
echo '=> Checking for new README.md files...'
echo
if [ ${FIND_READMES} -ne $NUMBER_READMES ]
then
  echo
  echo '  ✖ ERROR: New README.md file(s) detected, prefer index.md over README.md.' >&2
  echo '  https://docs.gitlab.com/ee/development/documentation/styleguide.html#work-with-directories-and-files'
  echo
  ((ERRORCODE++))
fi

MD_DOC_PATH=${MD_DOC_PATH:-doc}

function run_locally_or_in_docker() {
  local cmd=$1
  local args=$2

  if hash ${cmd} 2>/dev/null
  then
    $cmd $args
  elif hash docker 2>/dev/null
  then
    docker run -t -v ${PWD}:/gitlab -w /gitlab --rm registry.gitlab.com/gitlab-org/gitlab-docs:lint ${cmd} ${args}
  else
    echo
    echo "  ✖ ERROR: '${cmd}' not found. Install '${cmd}' or Docker to proceed." >&2
    echo
    ((ERRORCODE++))
  fi

  if [ $? -ne 0 ]
  then
    echo
    echo "  ✖ ERROR: '${cmd}' failed with errors." >&2
    echo
    ((ERRORCODE++))
  fi
}

echo '=> Linting markdown style...'
echo
run_locally_or_in_docker 'markdownlint' "--config .markdownlint.json ${MD_DOC_PATH}"

echo '=> Linting prose...'
run_locally_or_in_docker 'vale' "--minAlertLevel error ${MD_DOC_PATH}"

if [ $ERRORCODE -ne 0 ]
then
  echo "✖ ${ERRORCODE} lint test(s) failed. Review the log carefully to see full listing."
  exit 1
else
  echo "✔ Linting passed"
  exit 0
fi
