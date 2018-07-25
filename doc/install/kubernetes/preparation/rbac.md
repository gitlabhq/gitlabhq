# Role Based Access Control

Until Kubernetes 1.7, there were no permissions within a cluster. With the launch of 1.7, there is now a role based access control system ([RBAC](https://kubernetes.io/docs/admin/authorization/rbac/)) which determines what services can perform actions within a cluster.

RBAC affects a few different aspects of GitLab:
* [Installation of GitLab using Helm](tiller.md#preparing-for-helm-with-rbac)
* Prometheus monitoring
* GitLab Runner

## Checking that RBAC is enabled

Try listing the current cluster roles, if it fails then `RBAC` is disabled

This command will output `false` if `RBAC` is disabled and `true` otherwise

`kubectl get clusterroles > /dev/null 2>&1 && echo true || echo false`
