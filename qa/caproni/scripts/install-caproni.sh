#!/usr/bin/env bash
# TODO: replace with mise, which this repo already uses

set -euo pipefail

# Falls back to the CI file so laptops use the same version
if [[ -z "${CAPRONI_VERSION:-}" ]]; then
  repo_root="${CI_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
  CAPRONI_VERSION=$(awk -F'"' '/^  CAPRONI_VERSION:/ {print $2}' \
    "${repo_root}/.gitlab/ci/qa-common/variables.gitlab-ci.yml")
fi
: "${CAPRONI_VERSION:?could not determine CAPRONI_VERSION}"

CAPRONI_PROJECT_ID="gitlab-org%2Fcaproni"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

case "$(uname -m)" in
  x86_64 | amd64) arch="x86_64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

tarball="caproni_${CAPRONI_VERSION}_Linux_${arch}.tar.gz"
# The packages API percent-encodes dots
encode() { printf '%s' "$1" | sed 's/\./%2E/g'; }
base_url="https://gitlab.com/api/v4/projects/${CAPRONI_PROJECT_ID}/packages/generic/caproni/$(encode "${CAPRONI_VERSION}")"

workdir=$(mktemp -d)
trap 'rm -rf "${workdir}"' EXIT

echo "Downloading caproni ${CAPRONI_VERSION} (${arch})"
curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
  --output "${workdir}/${tarball}" "${base_url}/$(encode "${tarball}")"
curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
  --output "${workdir}/checksums.txt" "${base_url}/$(encode 'checksums.txt')"

echo "Verifying checksum"
(cd "${workdir}" && grep " ${tarball}\$" checksums.txt | sha256sum --check --strict -)

tar -xzf "${workdir}/${tarball}" -C "${workdir}" caproni
install -m 0755 "${workdir}/caproni" "${INSTALL_DIR}/caproni"

caproni version
