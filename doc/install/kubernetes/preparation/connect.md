# Connecting your computer to a cluster

In order to deploy software and settings to a cluster, you must connect and authenticate to it.

* [GKE cluster](#connect-to-gke-cluster)
* [EKS cluster](#connect-to-eks-cluster)
* [Local minikube cluster](#connect-to-local-minikube-cluster)

## Connect to GKE cluster

The command for connection to the cluster can be obtained from the [Google Cloud Platform Console](https://console.cloud.google.com/kubernetes/list) by the individual cluster.

Look for the **Connect** button in the clusters list page.

**Or**

Use the command below, filling in your cluster's informtion:

```
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-id>
```

## Connect to EKS cluster

For the most up to date instructions, follow the Amazon EKS documentation on [connecting to a cluster](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-configure-kubectl).

## Connect to local minikube cluster

If you are doing local development, you can use `minikube` as your
local cluster. If `kubectl cluster-info` is not showing `minikube` as the current
cluster, use `kubectl config set-cluster minikube` to set the active cluster.
