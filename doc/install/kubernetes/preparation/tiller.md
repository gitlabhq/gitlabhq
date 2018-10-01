# Configuring and initializing Helm Tiller

To make use of Helm, you must have a [Kubernetes][k8s-io] cluster. Ensure you can
access your cluster using `kubectl`.

Helm consists of two parts, the `helm` client and a `tiller` server inside Kubernetes.

NOTE: **Note:**
If you are not able to run Tiller in your cluster, for example on OpenShift, it
is possible to use [Tiller locally](https://gitlab.com/charts/gitlab/tree/master/doc/helm#local-tiller)
and avoid deploying it into the cluster. This should only be used when Tiller
cannot be normally deployed.

## Initialize Helm and Tiller

Tiller is deployed into the cluster and interacts with the Kubernetes API to deploy your applications. If role based access control (RBAC) is enabled, Tiller will need to be [granted permissions](#preparing-for-helm-with-rbac) to allow it to talk to the Kubernetes API.

If RBAC is not enabled, skip to [initalizing Helm](#initialize-helm).

If you are not sure whether RBAC is enabled in your cluster, or to learn more, read through our [RBAC documentation](rbac.md).

## Preparing for Helm with RBAC

Helm's Tiller will need to be granted permissions to perform operations. These instructions grant cluster wide permissions, however for more advanced deployments [permissions can be restricted to a single namespace](https://docs.helm.sh/using_helm/#example-deploy-tiller-in-a-namespace-restricted-to-deploying-resources-only-in-that-namespace). To grant access to the cluster, we will create a new `tiller` service account and bind it to the `cluster-admin` role.

Create a file `rbac-config.yaml` with the following contents:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

Next we need to connect to the cluster and upload the RBAC config.

### Upload the RBAC config

Some clusters require authentication to use `kubectl` to create the Tiller roles.

#### Upload the RBAC config as an admin user (GKE)

For GKE, you need to grab the admin credentials:

```
gcloud container clusters describe <cluster-name> --zone <zone> --project <project-id> --format='value(masterAuth.password)'
```

This command will output the admin password. We need the password to authenticate with `kubectl` and create the role.

```
kubectl --username=admin --password=xxxxxxxxxxxxxx create -f rbac-config.yaml
```

#### Upload the RBAC config (Other clusters)

For other clusters like Amazon EKS, you can directly upload the RBAC configuration.

```
kubectl create -f rbac-config.yaml
```

## Initialize Helm

Deploy Helm Tiller with a service account:

```
helm init --service-account tiller
```

If your cluster previously had Helm/Tiller installed,
run the following to ensure that the deployed version of Tiller matches the local Helm version:

```
helm init --upgrade --service-account tiller
```

### Patching Helm Tiller for Amazon EKS

Helm Tiller requires a flag to be enabled to work properly on Amazon EKS:

```
kubectl -n kube-system patch deployment tiller-deploy -p '{"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}'
```

[helm]: https://helm.sh
[helm-using]: https://docs.helm.sh/using_helm
[k8s-io]: https://kubernetes.io/
[gcp-k8s]: https://console.cloud.google.com/kubernetes/list
