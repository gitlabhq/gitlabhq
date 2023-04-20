#!/usr/bin/env bash

# We created this because we could not monitor quotas easily in GCP monitoring (see
# https://gitlab.com/gitlab-org/quality/engineering-productivity-infrastructure/-/issues/37)
#
# If this functionality ever becomes available, please replace this script with GCP monitoring!

function k8s_resource_count() {
  local resource_name="${1}"

  kubectl get -A "${resource_name}" 2> /dev/null | wc -l | xargs
}

# ~13 services per review-app - ~230 review apps
SERVICES_COUNT_THRESHOLD=3000
REVIEW_APPS_COUNT_THRESHOLD=200

# One review app currently deploys 4 PVCs
PVCS_COUNT_THRESHOLD=$((REVIEW_APPS_COUNT_THRESHOLD * 4))

exit_with_error=false

# In the current GKE cluster configuration, we should never go higher than 4096 services per cluster.
services_count=$(kubectl get services -A | wc -l | xargs)
if [ "${services_count}" -gt "${SERVICES_COUNT_THRESHOLD}" ]; then
  >&2 echo "❌ [ERROR] Services are above ${SERVICES_COUNT_THRESHOLD} (currently at ${services_count})"
  exit_with_error=true
fi

review_apps_count=$(helm ls -A | wc -l | xargs)
if [ "${review_apps_count}" -gt "${REVIEW_APPS_COUNT_THRESHOLD}" ]; then
  >&2 echo "❌ [ERROR] Review apps count are above ${REVIEW_APPS_COUNT_THRESHOLD} (currently at ${review_apps_count})"
  exit_with_error=true
fi

namespaces_count=$(kubectl get namespaces -A | wc -l | xargs)
if [ "$(echo $(($namespaces_count - $review_apps_count)) | sed 's/-//')" -gt 30 ]; then
  >&2 echo "❌ [ERROR] Difference between namespaces and deployed review-apps is above 30 (${namespaces_count} namespaces and ${review_apps_count} review-apps)"
  exit_with_error=true
fi

pvcs_count=$(kubectl get pvc -A | wc -l | xargs)
if [ "${pvcs_count}" -gt "${PVCS_COUNT_THRESHOLD}" ]; then
  >&2 echo "❌ [ERROR] PVCs are above ${PVCS_COUNT_THRESHOLD} (currently at ${pvcs_count})"
  exit_with_error=true
fi

if [ "${exit_with_error}" = true ] ; then
  exit 1
fi

echo -e "\nShow k8s resources count: "
cat > k8s-resources-count.out <<COMMANDS
  $(k8s_resource_count backendconfigs.cloud.google.com) backendconfigs.cloud.google.com
  $(k8s_resource_count capacityrequests.internal.autoscaling.gke.io) capacityrequests.internal.autoscaling.gke.io
  $(k8s_resource_count capacityrequests.internal.autoscaling.k8s.io) capacityrequests.internal.autoscaling.k8s.io
  $(k8s_resource_count certificaterequests.cert-manager.io) certificaterequests.cert-manager.io
  $(k8s_resource_count certificates.cert-manager.io) certificates.cert-manager.io
  $(k8s_resource_count challenges.acme.cert-manager.io) challenges.acme.cert-manager.io
  $(k8s_resource_count configmaps) configmaps
  $(k8s_resource_count containerwatcherstatuses.containerthreatdetection.googleapis.com) containerwatcherstatuses.containerthreatdetection.googleapis.com
  $(k8s_resource_count controllerrevisions.apps) controllerrevisions.apps
  $(k8s_resource_count cronjobs.batch) cronjobs.batch
  $(k8s_resource_count csistoragecapacities.storage.k8s.io) csistoragecapacities.storage.k8s.io
  $(k8s_resource_count daemonsets.apps) daemonsets.apps
  $(k8s_resource_count deployments.apps) deployments.apps
  $(k8s_resource_count endpoints) endpoints
  $(k8s_resource_count frontendconfigs.networking.gke.io) frontendconfigs.networking.gke.io
  $(k8s_resource_count horizontalpodautoscalers.autoscaling) horizontalpodautoscalers.autoscaling
  $(k8s_resource_count ingressclasses) ingressclasses
  $(k8s_resource_count ingresses.networking.k8s.io) ingresses.networking.k8s.io
  $(k8s_resource_count issuers.cert-manager.io) issuers.cert-manager.io
  $(k8s_resource_count jobs.batch) jobs.batch
  $(k8s_resource_count leases.coordination.k8s.io) leases.coordination.k8s.io
  $(k8s_resource_count limitranges) limitranges
  $(k8s_resource_count managedcertificates.networking.gke.io) managedcertificates.networking.gke.io
  $(k8s_resource_count networkpolicies.networking.k8s.io) networkpolicies.networking.k8s.io
  $(k8s_resource_count orders.acme.cert-manager.io) orders.acme.cert-manager.io
  $(k8s_resource_count persistentvolumeclaims) persistentvolumeclaims
  $(k8s_resource_count poddisruptionbudgets.policy) poddisruptionbudgets.policy
  $(k8s_resource_count pods) pods
  $(k8s_resource_count podtemplates) podtemplates
  $(k8s_resource_count replicasets.apps) replicasets.apps
  $(k8s_resource_count replicationcontrollers) replicationcontrollers
  $(k8s_resource_count resourcequotas) resourcequotas
  $(k8s_resource_count rolebindings.rbac.authorization.k8s.io) rolebindings.rbac.authorization.k8s.io
  $(k8s_resource_count roles.rbac.authorization.k8s.io) roles.rbac.authorization.k8s.io
  $(k8s_resource_count scalingpolicies.scalingpolicy.kope.io) scalingpolicies.scalingpolicy.kope.io
  $(k8s_resource_count secrets) secrets
  $(k8s_resource_count serviceaccounts) serviceaccounts
  $(k8s_resource_count serviceattachments.networking.gke.io) serviceattachments.networking.gke.io
  $(k8s_resource_count servicenetworkendpointgroups.networking.gke.io) servicenetworkendpointgroups.networking.gke.io
  $(k8s_resource_count services) services
  $(k8s_resource_count statefulsets.apps) statefulsets.apps
  $(k8s_resource_count updateinfos.nodemanagement.gke.io) updateinfos.nodemanagement.gke.io
  $(k8s_resource_count volumesnapshots.snapshot.storage.k8s.io) volumesnapshots.snapshot.storage.k8s.io
COMMANDS

sort --reverse --numeric-sort < k8s-resources-count.out
