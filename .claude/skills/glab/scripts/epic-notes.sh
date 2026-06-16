#!/usr/bin/env bash
# Fetch all notes (comments) on a group-level epic, handling pagination.
#
# Usage:
#   epic-notes.sh <group-path> <epic-iid> [page-size]
#
# Arguments:
#   group-path  Group fullPath, plain slashes: "gitlab-org" or "gitlab-org/foundations"
#   epic-iid    Epic display number (iid), e.g. 16428
#   page-size   Discussions per page (default: 100). Most epics fit in one page.
#
# Examples:
#   epic-notes.sh gitlab-org 16428
#   epic-notes.sh gitlab-org/foundations 15
#   epic-notes.sh gitlab-org 16428 20   # force pagination for testing
#
# Output: a JSON array of all notes, e.g.
#   [{"id":"gid://...","body":"...","author":{"username":"..."},"createdAt":"..."}]
#
# Requires: glab (authenticated), jq

set -Eeuo pipefail

GROUP_PATH="${1:?Usage: epic-notes.sh <group-path> <epic-iid> [page-size]}"
EPIC_IID="${2:?Usage: epic-notes.sh <group-path> <epic-iid> [page-size]}"
PAGE_SIZE="${3:-100}"

# Resolve directory of this script to find the .graphql template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$SKILL_DIR/assets/graphql/epic-notes.graphql"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template not found at $TEMPLATE" >&2
  exit 1
fi

QUERY="$(cat "$TEMPLATE")"

cursor=""
all_notes='[]'
_err=$(mktemp)
trap 'rm -f "$_err"' EXIT

while true; do
  # Pass values as GraphQL variables: no string interpolation, no escaping traps.
  # Use -f for String-typed variables (glab -F coerces numeric-looking values to
  # Int, which fails String! validation) and -F for the Int pageSize. cursor is
  # omitted on the first page (defaults to null in the query).
  args=(-f "groupPath=${GROUP_PATH}" -f "epicIid=${EPIC_IID}" -F "pageSize=${PAGE_SIZE}")
  if [[ -n "$cursor" ]]; then
    args+=(-f "cursor=${cursor}")
  fi

  if ! response=$(glab api graphql "${args[@]}" -f "query=${QUERY}" 2>"$_err"); then
    echo "ERROR from glab: $(cat "$_err")" >&2
    exit 1
  fi

  # Extract notes from this page
  page_notes=$(echo "$response" | jq '
    [.data.group.workItem.widgets[]
      | select(.type == "NOTES")
      | .discussions.nodes[]
      | .notes.nodes[]
    ]')

  all_notes=$(jq -n --argjson acc "$all_notes" --argjson new "$page_notes" '$acc + $new')

  has_next=$(echo "$response" | jq -r '
    .data.group.workItem.widgets[]
    | select(.type == "NOTES")
    | .discussions.pageInfo.hasNextPage')

  cursor=$(echo "$response" | jq -r '
    .data.group.workItem.widgets[]
    | select(.type == "NOTES")
    | .discussions.pageInfo.endCursor // ""')

  if [[ "$has_next" != "true" ]]; then
    break
  fi
done

echo "$all_notes" | jq '.'
