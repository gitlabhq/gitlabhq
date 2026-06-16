#!/usr/bin/env bash
# Verify that .agents/skills mirrors .claude/skills exactly.
#
# The canonical Claude Code skills live under .claude/skills/. The
# .agents/skills path is a symlink pointing at the same content, so
# AGENTS.md-aware tools (OpenCode, etc.) see the identical skill set
# without a separate copy. This check guards against silent drift:
# someone replacing the symlink with a real directory, an in-place
# edit on one side only, or a partial copy.
#
# Exit non-zero on any mismatch and print what diverged.

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
claude_dir="${REPO_ROOT}/.claude/skills"
agents_dir="${REPO_ROOT}/.agents/skills"

fail() {
  echo "skills-parity: $1" >&2
  exit 1
}

[ -d "${claude_dir}" ] || fail ".claude/skills/ does not exist"
[ -e "${agents_dir}" ] || fail ".agents/skills does not exist"

# Fast path: symlink resolving to the canonical dir is the expected state.
if [ -L "${agents_dir}" ]; then
  resolved="$(cd "$(dirname "${agents_dir}")" && cd "$(readlink "${agents_dir}")" 2>/dev/null && pwd -P)"
  canonical="$(cd "${claude_dir}" && pwd -P)"
  if [ "${resolved}" = "${canonical}" ]; then
    exit 0
  fi
  fail ".agents/skills is a symlink but does not resolve to .claude/skills (resolved=${resolved:-<broken>})"
fi

# Slow path: .agents/skills is a real directory. Confirm parity by
# comparing the set of skills and the byte size of each SKILL.md.
list_skills() {
  # Print one "<name> <bytes>" line per <name>/SKILL.md found under the
  # given root. Sorted, so we can diff. Uses BSD/GNU-portable stat.
  local root="$1"
  find "${root}" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | while read -r path; do
    local name size
    name="$(basename "$(dirname "${path}")")"
    size="$(wc -c <"${path}" | tr -d ' ')"
    printf '%s %s\n' "${name}" "${size}"
  done | sort
}

claude_listing="$(list_skills "${claude_dir}")"
agents_listing="$(list_skills "${agents_dir}")"

if [ "${claude_listing}" != "${agents_listing}" ]; then
  echo "skills-parity: .claude/skills and .agents/skills differ" >&2
  echo "  diff (-.claude/skills  +.agents/skills):" >&2
  diff <(printf '%s\n' "${claude_listing}") <(printf '%s\n' "${agents_listing}") >&2 || true
  echo "  fix: restore the symlink with" >&2
  echo "    rm -rf .agents/skills && ln -s ../.claude/skills .agents/skills" >&2
  exit 1
fi
