#!/bin/bash

#
# General utils
#

function log() {
  echo -e "\033[1;32m$1\033[0m"
}

function warn() {
  echo -e "\033[1;33m$1\033[0m"
}

function log_info() {
  echo -e "\033[1;35m$1\033[0m"
}

function log_with_header() {
  length=$(echo "$1" | awk '{print length}')
  delimiter=$(printf -- "${2:-=}%.0s" $(seq $length))

  log_info "$delimiter"
  log_info "$1"
  log_info "$delimiter"
}

function save_install_logs() {
  log_with_header "Events of namespace ${NAMESPACE}"
  kubectl get events --output wide --namespace ${NAMESPACE}

  for pod in $(kubectl get pods --no-headers --namespace ${NAMESPACE} --output jsonpath={.items[*].metadata.name}); do
    log_with_header "Description of pod ${pod}"
    kubectl describe pod ${pod} --namespace ${NAMESPACE}

    for container in $(kubectl get pods ${pod} --no-headers --namespace ${NAMESPACE} --output jsonpath={.spec.initContainers[*].name}); do
      kubectl logs ${pod} --namespace ${NAMESPACE} --container ${container} >"${container}.log"
    done

    for container in $(kubectl get pods ${pod} --no-headers --namespace ${NAMESPACE} --output jsonpath={.spec.containers[*].name}); do
      kubectl logs ${pod} --namespace ${NAMESPACE} --container ${container} >"${container}.log"
    done
  done
}
