#!/usr/bin/env bash

# This script prepares your local development environment for working on the
# GitLab Rails application. It assumes you have already set up GDK and have
# the initial system dependencies installed (e.g. via brew on macOS or apt on
# Debian/Ubuntu), including git, gpg, and a C/C++ toolchain.

set -euo pipefail

# ---------------------------------------------------------
# Run this script after cloning the gitlab repository to
# install language runtimes via mise, Ruby gems, JS packages,
# and git hooks via lefthook.
# ---------------------------------------------------------

cd "$(dirname "${BASH_SOURCE[0]}")/.."

warn() {
  printf '%s\n' "${1-}" >&2
  printf '%s\n' "See https://docs.gitlab.com/development/contributing/first_contribution/ for setup guidance." >&2
}

# ---- mise ----------------------------------------------------------------

if command -v mise >/dev/null; then
  echo "mise installed..."
elif command -v rtx >/dev/null; then
  warn "WARNING: 'rtx' has been renamed to 'mise'; please replace 'rtx' with 'mise'"
  exit 1
elif [[ -n ${ASDF_DIR-} ]]; then
  warn "WARNING: 'asdf' is no longer supported; please uninstall and replace with 'mise'"
  exit 1
else
  warn "mise is not installed. Install it from https://mise.jdx.dev and re-run this script."
  exit 1
fi

# Detect Rosetta 2 (Apple Silicon running x86_64 emulation)
if [[ $(uname -m) == "arm64" ]] && [[ $(uname -p) == "x86_64" ]]; then
  echo "This shell is running in Rosetta emulating x86_64. Please use a native arm64 shell." >&2
  exit 1
fi

# Detect ancient versions of bash
if ((BASH_VERSINFO[0] < 4)); then
  echo "WARNING: You're running bash < v4.0.0. Please upgrade to a newer version." >&2
fi

# ---- Homebrew dependencies -----------------------------------------------

if [[ "$(uname -s)" == "Darwin" ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo "Checking development dependencies from Brewfile..."
    brew bundle check || brew bundle install
  else
    warn "Homebrew is not installed. You may need to ensure manually that dependencies from $(pwd)/Brewfile are available."
    exit 1
  fi
fi

echo "Installing tool versions from .tool-versions via mise..."
mise plugins update -q
mise install

# Activate mise so that the installed tools are on PATH for the steps below
: "${PROMPT_COMMAND:=}"
# Allow clean mise re-activation if this script is run via "mise exec --"
unset __MISE_DIFF __MISE_SESSION __MISE_ORIG_PATH
eval "$(mise activate bash)"

# ---- Ruby / Bundler ------------------------------------------------------

echo "Running bundle install..."
bundle install

# ---- JavaScript / Yarn ---------------------------------------------------

echo "Running yarn install..."
yarn install --frozen-lockfile

# ---- Git hooks / lefthook ------------------------------------------------

if bundle exec lefthook check-install; then
  echo "Installing git hooks via lefthook..."
  bundle exec lefthook install
else
  warn "Git hooks already installed via lefthook. Skipping."
fi

echo ""
echo "Development environment ready."
