#!/usr/bin/env bash

# This script triggers a merge train job to sync an EE stable branch to its
# corresponding CE stable branch.

set -e

if [[ "$MERGE_TRAIN_TRIGGER_TOKEN" == '' ]]
then
    echo 'The variable MERGE_TRAIN_TRIGGER_TOKEN must be set to a non-empy value'
    exit 1
fi

if [[ "$MERGE_TRAIN_TRIGGER_URL" == '' ]]
then
    echo 'The variable MERGE_TRAIN_TRIGGER_URL must be set to a non-empy value'
    exit 1
fi

if [[ "$CI_COMMIT_REF_NAME" == '' ]]
then
    echo 'The variable CI_COMMIT_REF_NAME must be set to a non-empy value'
    exit 1
fi

if [[ "$SOURCE_PROJECT" == '' ]]
then
    echo 'The variable SOURCE_PROJECT must be set to a non-empy value'
    exit 1
fi

if [[ "$TARGET_PROJECT" == '' ]]
then
    echo 'The variable TARGET_PROJECT must be set to a non-empy value'
    exit 1
fi

curl -X POST \
    -F token="$MERGE_TRAIN_TRIGGER_TOKEN" \
    -F ref=master \
    -F "variables[MERGE_FOSS]=1" \
    -F "variables[SOURCE_BRANCH]=$CI_COMMIT_REF_NAME" \
    -F "variables[TARGET_BRANCH]=${CI_COMMIT_REF_NAME/-ee/}" \
    -F "variables[SOURCE_PROJECT]=$SOURCE_PROJECT" \
    -F "variables[TARGET_PROJECT]=$TARGET_PROJECT" \
    "$MERGE_TRAIN_TRIGGER_URL"
