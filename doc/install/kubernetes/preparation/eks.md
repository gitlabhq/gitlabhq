# Running GitLab on EKS

There are a few nuances to Amazon EKS which are important to be aware of, when deploying GitLab.

## Persistent volume management

There are two methods to manage volume claims on Kubernetes:
1. Manually creating each persistent volume (recommended on EKS)
1. Utilizing dynamic provisioning to automatically create the persistent volumes

### Manual provisioning of volumes (Recommended)

Manually creating the volumes allows you to control the zone of each volume, as well as all other details supported by the underlying storage.

Follow our documentation on [manually creating persistent volumes](https://gitlab.com/charts/gitlab/blob/master/doc/installation/storage.md#manually-creating-static-volumes).

### Dynamic provisioning of volumes

Dynamic provisioning utilizes a Kubernetes provisioner, like `aws-ebs`, to automatically create persistent volumes to fulfill each claim.

With EKS, there are a few important details to keep in mind:

1. Clusters are required to span multiple AZ's
1. Kubernetes volume provisioners create volumes across zones without regard to which pod they belong to. This leads to scenarios where a pod with multiple volumes being unable to start due to the volumes being in different zones.
1. There is no default Storage Class.

The easiest way to solve this and still utilize dynamic provisioning is to utilize, or create, a Storage Class that is locked to a specific zone.

> **Note**: Restricting volumes to specific zone will cause GitLab and any other application using this Storage Class to only reside in that zone. For multiple zone support, utilize [manually provisioned volumes](#manual-provisioning-of-volumes).

To create the storage class, download and edit Amazon EKS's [sample Storage Class](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html) and add the following parameter:

```yaml
parameters:
  zone: <desired-zone>
```

Then [specify the Storage Class](https://gitlab.com/charts/gitlab/blob/master/doc/installation/storage.md#using-a-custom-storage-class) name when deploying GitLab.

## External access to GitLab

By default, GitLab will an deploy an ingress which will create an associated Elastic Load Balancer. Since the DNS names of ELB's cannot be known ahead of time, it is difficult to utilize Let's Encrypt to automatically provision HTTPS certificates.

We recommend [using your own certificates](https://gitlab.com/charts/gitlab/blob/master/doc/installation/tls.md#option-2-use-your-own-wildcard-certificate), and then mapping your desired DNS name to the created ELB using a CNAME record.
