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
  result=$(perl -CSD -pe '
    s/^(\s*)(>\s*\[!(?:note|flag|warning|disclaimer|tip|caution)\]) ?(\S.*)$/$1$2\n$1> $3/ui;
  ' "$file")
  if [ "$result" != "$(cat "$file")" ]; then
    printf '%s\n' "$result" > "$file"
    echo "Updated: $file"
  fi
}

run_ci_mode() {
  : "${CI_MERGE_REQUEST_DIFF_BASE_SHA:?required in CI mode}"
  : "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:?required in CI mode}"
  : "${CI_PROJECT_PATH:?required in CI mode}"
  : "${GITLAB_ARGO_BOT_TOKEN:?required in CI mode}"

  git checkout "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"

  mapfile -t files < <(
    git diff --name-only --diff-filter=ACMR \
      "${CI_MERGE_REQUEST_DIFF_BASE_SHA}...HEAD" \
      -- 'doc-locale/*.md' 'doc-locale/**/*.md'
  )

  if [ ${#files[@]} -eq 0 ]; then
    echo "No changed markdown files under doc-locale/."
    return 0
  fi

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
  git remote set-url origin "https://oauth2:${GITLAB_ARGO_BOT_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git" || {
    echo "Failed to set git remote URL" >&2
    exit 1
  }
  git push origin "HEAD:${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" || {
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
