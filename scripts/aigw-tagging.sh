#!/usr/bin/env bash

set -e

if [ -z "$CI_COMMIT_TAG" ]; then
  echo "Error: CI_COMMIT_TAG is not set"
  exit 1
fi

if [[ "$CI_COMMIT_TAG" != *.0-ee ]]; then
  echo "Exiting: Skipping since this is a patch version"
  exit 0
fi

if [ -z "$AIGW_TAGGING_ACCESS_TOKEN" ]; then
  echo "Error: AIGW_TAGGING_ACCESS_TOKEN is not set"
  exit 1
fi

# Extract VERSION from CI_COMMIT_TAG (format: v{MAJOR}.{MINOR}.{PATCH}-ee)
VERSION=$(echo "$CI_COMMIT_TAG" | sed 's/^v\([0-9]*\)\.\([0-9]*\)\..*-ee$/\1-\2/')
BRANCH_NAME="stable-${VERSION}-ee"
PROJECT_ID="39903947"
API_BASE="https://gitlab.com/api/v4"

echo "Processing tag: $CI_COMMIT_TAG"
echo "Extracted version: $VERSION"
echo "Target branch: $BRANCH_NAME"

# Check if branch exists
echo "Checking if branch $BRANCH_NAME exists..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --header "PRIVATE-TOKEN: $AIGW_TAGGING_ACCESS_TOKEN" \
  "$API_BASE/projects/$PROJECT_ID/repository/branches/$BRANCH_NAME")

if [ "$HTTP_STATUS" = "404" ]; then
  echo "Creating branch: $BRANCH_NAME"
  BRANCH_RESPONSE=$(curl -X POST -s \
    --header "PRIVATE-TOKEN: $AIGW_TAGGING_ACCESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"branch\": \"$BRANCH_NAME\", \"ref\": \"main\"}" \
    "$API_BASE/projects/$PROJECT_ID/repository/branches")

  if echo "$BRANCH_RESPONSE" | grep -q '"name".*"'$BRANCH_NAME'"'; then
    echo "Branch $BRANCH_NAME created successfully"
  else
    echo "Error creating branch: $BRANCH_RESPONSE"
    exit 1
  fi
else
  echo "Branch $BRANCH_NAME already exists (HTTP status: $HTTP_STATUS)"
fi

echo "Creating tag self-hosted-$CI_COMMIT_TAG on branch $BRANCH_NAME..."
TAG_RESPONSE=$(curl -X POST -s \
  --header "PRIVATE-TOKEN: $AIGW_TAGGING_ACCESS_TOKEN" \
  "$API_BASE/projects/$PROJECT_ID/repository/tags?tag_name=self-hosted-$CI_COMMIT_TAG&ref=$BRANCH_NAME")

if echo "$TAG_RESPONSE" | grep -q '"name".*"self-hosted-'$CI_COMMIT_TAG'"'; then
  echo "Tag self-hosted-$CI_COMMIT_TAG created successfully"
else
  echo "Error creating tag: $TAG_RESPONSE"
  exit 1
fi
