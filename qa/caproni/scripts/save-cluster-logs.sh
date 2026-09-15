#!/usr/bin/env bash
# Shim: caproni logs is edit-mode only, so this shells out to kubectl
# No set -e: after_script runs when things already broke

set -uo pipefail

NAMESPACE="${NAMESPACE:-gitlab}"
LOG_DIR="${LOG_DIR:-${CI_PROJECT_DIR:-.}/qa/tmp/cluster-logs}"

# From this script's location: after_script starts in an unknown directory
CAPRONI_CONFIG="${CAPRONI_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/caproni.yaml}"
caproni() { command caproni -c "${CAPRONI_CONFIG}" "$@"; }

mkdir -p "${LOG_DIR}"

echo "Saving cluster diagnostics to ${LOG_DIR}"

# stderr split off: caproni warnings would read like cluster errors
caproni kubectl -n "${NAMESPACE}" get events --sort-by=.metadata.creationTimestamp \
  >"${LOG_DIR}/events.log" 2>>"${LOG_DIR}/caproni-stderr.log" || true
caproni kubectl -n "${NAMESPACE}" get pods -o wide \
  >"${LOG_DIR}/pods.log" 2>>"${LOG_DIR}/caproni-stderr.log" || true
caproni kubectl -n "${NAMESPACE}" describe pods \
  >"${LOG_DIR}/pods-describe.log" 2>>"${LOG_DIR}/caproni-stderr.log" || true

pods=$(caproni kubectl -n "${NAMESPACE}" get pods -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) || pods=""

for pod in ${pods}; do
  containers=$(caproni kubectl -n "${NAMESPACE}" get pod "${pod}" \
    -o jsonpath='{.spec.initContainers[*].name} {.spec.containers[*].name}' 2>/dev/null) || continue

  for container in ${containers}; do
    caproni kubectl -n "${NAMESPACE}" logs "${pod}" -c "${container}" --tail=-1 \
      >"${LOG_DIR}/${pod}.${container}.log" 2>>"${LOG_DIR}/caproni-stderr.log" || true
  done
done

echo "Saved logs for $(find "${LOG_DIR}" -name '*.log' | wc -l | tr -d ' ') containers and reports"
