#!/usr/bin/env bash
# Verify that any changed skill bumps its SKILL.md `version:` field.
#
# Shared Claude Code skills live under .claude/skills/<name>/. When a skill's
# contents change, downstream consumers (Claude Code, OpenCode, plugin
# marketplaces) rely on the `version:` field in the skill's SKILL.md
# frontmatter to detect updates. This check guards against editing a skill
# without bumping its version.
#
# Scope: only skills whose SKILL.md carries a `version:` field at the baseline
# are enforced. Skills that never had a version are skipped; a skill that had
# a version at baseline may not silently drop it.
#
# Baseline: the version is compared against the merge-base with origin/master
# (override with BASE_REF, or CI_MERGE_REQUEST_DIFF_BASE_SHA in CI). A skill
# "changed" if any tracked file under its directory differs from the baseline.
# The new version must be strictly greater than the baseline version.
#
# Exit non-zero on any skill that changed without a (forward) version bump.

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cd "${REPO_ROOT}"

skills_dir=".claude/skills"

fail() {
  echo "skills-version-bump: $1" >&2
  exit 1
}

# Determine the baseline ref to diff against:
#   1. An explicit BASE_REF (tests / manual runs).
#   2. CI_MERGE_REQUEST_DIFF_BASE_SHA (GitLab CI merge request pipelines).
#   3. The merge-base with origin/master (local pre-push hook).
if [ -n "${BASE_REF:-}" ]; then
  base="${BASE_REF}"
elif [ -n "${CI_MERGE_REQUEST_DIFF_BASE_SHA:-}" ]; then
  base="${CI_MERGE_REQUEST_DIFF_BASE_SHA}"
else
  base="$(git merge-base origin/master HEAD 2>/dev/null || true)"
fi

if [ -z "${base}" ]; then
  echo "skills-version-bump: could not determine a baseline ref" >&2
  echo "  set BASE_REF, run in an MR pipeline, or fetch origin/master" >&2
  exit 1
fi

# Fail loudly if the baseline tree is unreadable (e.g. an unfetched SHA on a
# shallow clone) rather than silently skipping the check.
if ! git rev-parse --verify --quiet "${base}^{commit}" >/dev/null; then
  fail "baseline ref '${base}' is not readable (unfetched SHA or shallow clone?)"
fi

# Extract the `version:` value from SKILL.md YAML frontmatter, normalizing
# surrounding quotes so `version: "1.2.3"` and `version: 1.2.3` compare equal.
# The search is scoped to the frontmatter block (between the first two `---`
# delimiters) so a stray `version:` in the body cannot be picked up.
extract_version() {
  awk '
    /^---[[:space:]]*$/ { fence++; if (fence == 1) next; if (fence >= 2) exit }
    fence == 1 && /^version:/ {
      sub(/^version:[[:space:]]*/, "")
      print
      exit
    }
  ' | head -n1 | tr -d '[:space:]' | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/"
}

# Version from a SKILL.md on disk. Prints nothing if the file is absent.
version_from_file() {
  local path="$1"
  [ -f "${path}" ] || return 0
  extract_version <"${path}"
}

# Version from a SKILL.md at a git ref. Prints nothing if the file is absent
# at that ref (a genuinely new skill).
version_from_ref() {
  local ref="$1" path="$2" content
  content="$(git show "${ref}:${path}" 2>/dev/null)" || return 0
  printf '%s\n' "${content}" | extract_version
}

# True if $1 is strictly greater than $2 under version sort.
#
# Prefers `sort -V` (GNU coreutils). macOS ships BSD `sort`, which lacks `-V`
# and would otherwise fail this pre-push hook for every macOS developer, so we
# fall back to a numeric field sort on dot-separated components.
version_gt() {
  [ "$1" = "$2" ] && return 1

  local greatest
  if printf '%s\n' "1.0" | sort -V >/dev/null 2>&1; then
    greatest="$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)"
  else
    greatest="$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | tail -n1)"
  fi

  [ "${greatest}" = "$1" ]
}

# All changed files under .claude/skills since the baseline.
changed_files="$(git diff --name-only --diff-filter=d "${base}" -- "${skills_dir}")"

if [ -z "${changed_files}" ]; then
  exit 0
fi

# The set of skill names that have any changed file.
changed_skills="$(printf '%s\n' "${changed_files}" \
  | sed -n "s#^${skills_dir}/\([^/]*\)/.*#\1#p" \
  | sort -u)"

status=0

while IFS= read -r skill; do
  [ -n "${skill}" ] || continue
  skill_md="${skills_dir}/${skill}/SKILL.md"

  base_version=""
  base_version="$(version_from_ref "${base}" "${skill_md}")"

  # New skill with no version history — nothing to enforce against.
  if [ -z "${base_version}" ]; then
    continue
  fi

  current_version=""
  current_version="$(version_from_file "${skill_md}")"

  # The skill had a version at baseline; it must not drop it.
  if [ -z "${current_version}" ]; then
    echo "skills-version-bump: skill '${skill}' changed and removed its 'version:' field (was ${base_version})" >&2
    echo "  restore and bump 'version:' in ${skill_md}" >&2
    status=1
    continue
  fi

  # The version must be bumped forward, not left unchanged or downgraded.
  if ! version_gt "${current_version}" "${base_version}"; then
    echo "skills-version-bump: skill '${skill}' changed but version was not bumped forward (${base_version} -> ${current_version})" >&2
    echo "  bump 'version:' in ${skill_md} to a value greater than ${base_version}" >&2
    status=1
  fi
done <<EOF
${changed_skills}
EOF

exit "${status}"
