# Multiple GitLab Instances

glab auto-detects the GitLab host from your git remote. `GITLAB_HOST` is only needed
outside a git repository or for one-off cross-instance commands.

## Auto-detection

When you run any `glab` command inside a git repository — including `glab api` and
`glab api graphql` — glab reads the `origin` remote URL and targets the correct host,
scheme, and port automatically. No `GITLAB_HOST` needed.

```bash
# In a repo cloned from ops.gitlab.net — no GITLAB_HOST needed
glab mr list
glab api "projects/gitlab-com%2Fgl-infra%2Fconfig-mgmt/issues/1"
glab api graphql -f query='{ currentUser { username } }'

# In a GDK repo cloned from http://gdk.test:3000 — also auto-detected
glab issue list
glab api "projects/mygroup%2Fmyproject/issues"
```

## Non-origin Remotes

By default, glab reads the `origin` remote. If `origin` points at one instance and you
want glab to target a different remote (e.g. a `gdk` secondary remote pointing at a local
GDK instance), configure the remote alias. This setting is per-repo (written to
`.git/config`); use `--global` to apply it across all repos.

```bash
# Keep origin → gitlab.com, add gdk as a secondary remote
git remote add gdk http://gdk.test:3000/group/project.git

# Tell glab to use the gdk remote for host detection (per-repo)
glab config set remote_alias gdk

# Or globally, for all repos
glab config set --global remote_alias gdk
```

Reset to default by running `glab config set remote_alias origin`.

## When `GITLAB_HOST` Is Required

Use `GITLAB_HOST` when:

- **Outside a git repository** — no remote to detect from
- **One-off commands** — targeting a specific instance without changing `remote_alias`

`GITLAB_HOST` accepts a hostname or a full URL. For standard HTTPS hosts you may omit the
scheme (`GITLAB_HOST=ops.gitlab.net`). For HTTP or non-standard ports, include both the
scheme and the port (`GITLAB_HOST=http://gdk.test:3000`).

```bash
# Standard HTTPS — scheme optional
GITLAB_HOST=ops.gitlab.net glab api "groups/gitlab-com%2Fgl-infra/epics"

# HTTP with non-standard port (e.g. GDK) — scheme and port required
GITLAB_HOST=http://gdk.test:3000 glab issue list
GITLAB_HOST=http://127.0.0.1:3000 glab mr list -R mygroup/myproject
```

## Resolving the Hostname

When you need `GITLAB_HOST` and are not sure which value to use, derive the full origin
from context:

| Input form | Derivation |
| --- | --- |
| Browser URL (`https://ops.gitlab.net/group/project/-/issues/1`) | Origin = scheme + host (`https://ops.gitlab.net`) |
| SCP-style SSH remote (`git@ops.gitlab.net:group/project.git`) | SSH implies HTTPS; origin = `https://ops.gitlab.net` |
| URL-style SSH remote (`ssh://git@gdk.test:2222/group/project.git`) | SSH port ≠ API port; extract hostname only — scheme and API port must be known separately (e.g. `http://gdk.test:3000` for a local GDK instance) |
| HTTPS remote (`https://ops.gitlab.net/group/project.git`) | Origin = scheme + host (`https://ops.gitlab.net`) |
| HTTP remote with port (`http://gdk.test:3000/group/project.git`) | Origin = `http://gdk.test:3000` |
| Local path to a git repo | Run `git -C /path/to/repo remote get-url origin`, then parse |
| Current directory | Run `git remote get-url origin`, then parse |
| Bare project or group path (`org/project`) | Ambiguous — if inside a repo, auto-detection already applies; if outside, set `GITLAB_HOST` to your intended instance |

Shell one-liners for parsing:

```bash
# HTTPS or HTTP remote (with or without port) → full origin
git remote get-url origin | sed -E 's|(https?://[^/]*).*|\1|'
# https://gitlab.com/org/project.git    →  https://gitlab.com
# http://gdk.test:3000/org/project.git  →  http://gdk.test:3000

# SCP-style SSH remote → HTTPS origin
git remote get-url origin | sed -E 's|git@([^:]*):.*|https://\1|'
# git@ops.gitlab.net:org/project.git    →  https://ops.gitlab.net

# URL-style SSH remote → hostname only (SSH port ≠ API port; prepend correct scheme + API port manually)
git remote get-url origin | sed -E 's|ssh://git@([^:/]+)(:[0-9]+)?/.*|\1|'
# ssh://git@gdk.test:2222/group/project.git  →  gdk.test
# Then construct GITLAB_HOST manually, e.g.: GITLAB_HOST=http://gdk.test:3000
```
