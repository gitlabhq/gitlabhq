#!/usr/bin/env bash
#
# Finds lines matching "> [!<type>] <text>" in localized markdown files
# and splits them into two lines, restoring the GLFM alert-box format
# that Phrase TMS sometimes flattens during translation.
#
set -euo pipefail

process_file() {
  local file="$1"
  [ -f "$file" ] || return 0
  local result
  # First pass (per-line): split a fully flattened "> [!note] text" line into
  # the marker and a "> text" line.
  # Second pass (whole-file): when the marker is already on its own line but the
  # following content line is missing its "> " prefix, add it. The negative
  # lookahead leaves already-correct lines (next line starts with ">") and blank
  # lines untouched, so Case 1's output is never re-processed.
  result=$(perl -CSD -pe '
    s/^(\s*)(>\s*\[!(?:note|flag|warning|disclaimer|tip|caution)\]) ?(\S.*)$/$1$2\n$1> $3/ui;
  ' "$file" | perl -CSD -0777 -pe '
    s/^([ \t]*)(>[ \t]*\[!(?:note|flag|warning|disclaimer|tip|caution)\])[ \t]*\n(?![ \t]*>)[ \t]*(\S.*)$/$1$2\n$1> $3/uigm;
  ')
  if [ "$result" != "$(cat "$file")" ]; then
    printf '%s\n' "$result" > "$file"
    echo "Updated: $file"
  fi
}

run_ci_mode() {
  : "${CI_MERGE_REQUEST_DIFF_BASE_SHA:?required in CI mode}"
  : "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:?required in CI mode}"
  : "${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH:?required in CI mode}"
  : "${GITLAB_ARGO_BOT_TOKEN:?required in CI mode}"

  git checkout "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"

  # Two-dot diff: compares trees at BASE and HEAD directly, without resolving
  # a merge base. Required because the job runs on a shallow clone whose two
  # depth-20 fetches don't reach a common ancestor.
  local diff_output
  diff_output=$(git diff --name-only --diff-filter=ACMR \
    "${CI_MERGE_REQUEST_DIFF_BASE_SHA}..HEAD" \
    -- 'doc-locale/*.md' 'doc-locale/**/*.md')

  if [ -z "$diff_output" ]; then
    echo "No changed markdown files under doc-locale/."
    return 0
  fi

  mapfile -t files <<< "$diff_output"

  echo "Processing ${#files[@]} changed file(s):"
  printf '  %s\n' "${files[@]}"

  for f in "${files[@]}"; do process_file "$f"; done

  if git diff --quiet; then
    echo "No alert-box fixes needed."
    return 0
  fi

  git config user.email "gitlab-argo-bot@gitlab.com"
  git config user.name "GitLab Argo Bot"
  git add -- "${files[@]}"
  git commit -m "Docs(i18n): auto-fix GLFM alert-box"
  # Push to the MR source project (fork or same project) rather than origin,
  # which on fork MRs points to the CI/target project.
  git push "https://oauth2:${GITLAB_ARGO_BOT_TOKEN}@gitlab.com/${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH}.git" \
    "HEAD:${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" || {
    echo "Failed to push changes" >&2
    exit 1
  }
}

case "${1:-}" in
  --ci)
    run_ci_mode
    ;;
  --files)
    shift
    [ $# -gt 0 ] || { echo "No files provided after --files." >&2; exit 0; }
    for f in "$@"; do process_file "$f"; done
    ;;
  *)
    target="${1:-doc-locale}"
    [ -d "$target" ] || { echo "Directory not found: $target" >&2; exit 1; }
    while IFS= read -r -d '' f; do
      process_file "$f"
    done < <(find "$target" -type f -name '*.md' ! -path '*/.markdownlint/*' -print0)
    ;;
esac

echo "Done."
