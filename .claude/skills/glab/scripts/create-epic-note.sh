#!/usr/bin/env bash
# Post a comment on a group-level epic.
#
# Usage:
#   create-epic-note.sh <group-id> <epic-iid> "comment body"
#
# Arguments:
#   group-id    Numeric group ID (get with: glab api "groups/my-group%2Fpath" | jq '.id')
#   epic-iid    Epic display number (iid), e.g. 16428
#   body        Comment text (quoted). Any content is safe — newlines, backticks,
#               $, and em dashes are passed as a GraphQL variable, not interpolated.
#
# Examples:
#   create-epic-note.sh 9970 16428 "This needs more context before we proceed."
#   create-epic-note.sh 12627982 15 "Fifth week kickoff looks good!"
#
# Output: JSON with the created note's id, body, author, and createdAt
#
# Requires: glab (authenticated), jq

set -Eeuo pipefail

GROUP_ID="${1:?Usage: create-epic-note.sh <group-id> <epic-iid> \"body\"}"
EPIC_IID="${2:?Usage: create-epic-note.sh <group-id> <epic-iid> \"body\"}"
BODY="${3:?Usage: create-epic-note.sh <group-id> <epic-iid> \"body\"}"

# Resolve directory of this script to find the .graphql template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$SKILL_DIR/assets/graphql/create-note.graphql"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template not found at $TEMPLATE" >&2
  exit 1
fi

_err=$(mktemp)
trap 'rm -f "$_err"' EXIT

# Get the epic's internal (global) ID — the createNote mutation requires it
if ! EPIC_DATA=$(glab api "groups/${GROUP_ID}/epics/${EPIC_IID}" 2>"$_err"); then
  echo "ERROR fetching epic: $(cat "$_err")" >&2
  exit 1
fi

EPIC_INTERNAL_ID=$(echo "$EPIC_DATA" | jq -r '.id')
if [[ "$EPIC_INTERNAL_ID" == "null" || -z "$EPIC_INTERNAL_ID" ]]; then
  echo "ERROR: could not extract epic internal id from API response" >&2
  exit 1
fi
NOTEABLE_ID="gid://gitlab/Epic/${EPIC_INTERNAL_ID}"

# Pass noteableId and body as GraphQL variables. Use -f (raw string) rather than
# -F: glab's -F coerces numeric-looking values to Int, which fails String!/
# NoteableID! validation for a body like "42". This avoids every escaping trap
# that string interpolation hits: newlines, backticks, $, and non-ASCII
# characters (e.g. em dashes) are sent verbatim.
if ! response=$(glab api graphql \
  -f noteableId="$NOTEABLE_ID" \
  -f body="$BODY" \
  -f query="$(cat "$TEMPLATE")" 2>"$_err"); then
  echo "ERROR from glab: $(cat "$_err")" >&2
  exit 1
fi

# Check for GraphQL errors
errors=$(echo "$response" | jq -r '.data.createNote.errors // [] | .[]' 2>/dev/null || true)
if [[ -n "$errors" ]]; then
  echo "ERROR from GraphQL: $errors" >&2
  exit 1
fi

echo "$response" | jq '.data.createNote.note'
