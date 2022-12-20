#!/usr/bin/env bash

echo '=> Generating code quality artifact...'
echo

# Generate code quality artifact for Vale warnings only on changed files.
# Only works on merged results pipelines, so first checks if a merged results CI variable is present.
# If not present, runs on all files.

if [ -z "${CI_MERGE_REQUEST_TARGET_BRANCH_SHA}" ]
then
  MD_DOC_PATH=${MD_DOC_PATH:-doc}
  echo "Merge request pipeline (detached) detected. Testing all files."
else
  MERGE_BASE=$(git merge-base "${CI_MERGE_REQUEST_TARGET_BRANCH_SHA}" "${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}")
  MD_DOC_PATH=$(git diff --diff-filter=d --name-only "${MERGE_BASE}..${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}" -- 'doc/*.md')
  if [ -n "${MD_DOC_PATH}" ]
  then
    echo -e "Merged results pipeline detected. Testing only the following files: ${MD_DOC_PATH}"
  fi
fi

echo "vale --output=doc/.vale/vale-json.tmpl --minAlertLevel warning ${MD_DOC_PATH} > gl-code-quality-report-docs.json"
vale --output=doc/.vale/vale-json.tmpl --minAlertLevel warning ${MD_DOC_PATH} > gl-code-quality-report-docs.json
