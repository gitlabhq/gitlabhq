---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Crossplane configuration **(FREE)**

After [installing](applications.md#install-crossplane-using-gitlab-cicd) Crossplane, you must configure it for use.
The process of configuring Crossplane includes:

1. [Configure RBAC permissions](#configure-rbac-permissions).
1. [Configure Crossplane with a cloud provider](#configure-crossplane-with-a-cloud-provider).
1. [Configure managed service access](#configure-managed-service-access).
1. [Set up Resource classes](#setting-up-resource-classes).
1. Use [Auto DevOps configuration options](#auto-devops-configuration-options).
1. [Connect to the PostgreSQL instance](#connect-to-the-postgresql-instance).

To allow Crossplane to provision cloud services such as PostgreSQL, the cloud provider
stack must be configured with a user account. For example:

- A service account for GCP.
- An IAM user for AWS.

Some important notes:

- This guide uses GCP as an example, but the processes for AWS and Azure are similar.
- Crossplane requires the Kubernetes cluster to be VPC native with Alias IPs enabled,
  so the IP addresses of the pods can be routed within the GCP network.

First, declare some environment variables with configuration for use in this guide:

```shell
export PROJECT_ID=crossplane-playground # the GCP project where all resources reside.
export NETWORK_NAME=default # the GCP network where your GKE is provisioned.
export REGION=us-central1 # the GCP region where the GKE cluster is provisioned.
```

## Configure RBAC permissions

For GitLab-managed clusters, role-based access control (RBAC) is configured automatically.

For non-GitLab managed clusters, ensure that the service account for the token
provided can manage resources in the `database.crossplane.io` API group:

1. Save the following YAML as `crossplane-database-role.yaml`:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: crossplane-database-role
     labels:
       rbac.authorization.k8s.io/aggregate-to-edit: "true"
   rules:
     - apiGroups:
         - database.crossplane.io
       resources:
         - postgresqlinstances
       verbs:
         - get
         - list
         - create
         - update
         - delete
         - patch
         - watch
   ```

1. Apply the cluster role to the cluster:

   ```shell
   kubectl apply -f crossplane-database-role.yaml
   ```

## Configure Crossplane with a cloud provider

See [Configure Your Cloud Provider Account](https://crossplane.github.io/docs/v0.4/cloud-providers.html)
to configure the installed cloud provider stack with a user account.

The Secret, and the Provider resource referencing the Secret, must be
applied to the `gitlab-managed-apps` namespace in the guide. Make sure you change that
while following the process.

## Configure Managed Service Access

Next, configure connectivity between the PostgreSQL database and the GKE cluster
by either:

- Using Crossplane as demonstrated below.
- Directly in the GCP console by
  [configuring private services access](https://cloud.google.com/vpc/docs/configure-private-services-access).

1. Run the following command, which creates a `network.yaml` file, and configures
   `GlobalAddress` and connection resources:

   ```plaintext
   cat > network.yaml <<EOF
   ---
   # gitlab-ad-globaladdress defines the IP range that will be allocated
   # for cloud services connecting to the instances in the given Network.

   apiVersion: compute.gcp.crossplane.io/v1alpha3
   kind: GlobalAddress
   metadata:
     name: gitlab-ad-globaladdress
   spec:
     providerRef:
       name: gcp-provider
     reclaimPolicy: Delete
     name: gitlab-ad-globaladdress
     purpose: VPC_PEERING
     addressType: INTERNAL
     prefixLength: 16
     network: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
   ---
   # gitlab-ad-connection is what allows cloud services to use the allocated
   # GlobalAddress for communication. Behind the scenes, it creates a VPC peering
   # to the network that those service instances actually live.

   apiVersion: servicenetworking.gcp.crossplane.io/v1alpha3
   kind: Connection
   metadata:
     name: gitlab-ad-connection
   spec:
     providerRef:
       name: gcp-provider
     reclaimPolicy: Delete
     parent: services/servicenetworking.googleapis.com
     network: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
     reservedPeeringRangeRefs:
       - name: gitlab-ad-globaladdress
   EOF
   ```

1. Apply the settings specified in the file with the following command:

   ```shell
   kubectl apply -f network.yaml
   ```

1. Verify the creation of the network resources, and that both resources are ready and synced.

   ```shell
   kubectl describe connection.servicenetworking.gcp.crossplane.io gitlab-ad-connection
   kubectl describe globaladdress.compute.gcp.crossplane.io gitlab-ad-globaladdress
   ```

## Setting up Resource classes

Use resource classes to define a configuration for the required managed service.
This example defines the PostgreSQL Resource class:

1. Run the following command, which define a `gcp-postgres-standard.yaml` resource
   class containing a default `CloudSQLInstanceClass` with labels:

   ```plaintext
   cat > gcp-postgres-standard.yaml <<EOF
   apiVersion: database.gcp.crossplane.io/v1beta1
   kind: CloudSQLInstanceClass
   metadata:
     name: cloudsqlinstancepostgresql-standard
     labels:
       gitlab-ad-demo: "true"
   specTemplate:
     writeConnectionSecretsToNamespace: gitlab-managed-apps
     forProvider:
       databaseVersion: POSTGRES_11_7
       region: $REGION
       settings:
         tier: db-custom-1-3840
         dataDiskType: PD_SSD
         dataDiskSizeGb: 10
         ipConfiguration:
           privateNetwork: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
     # this should match the name of the provider created in the above step
     providerRef:
       name: gcp-provider
     reclaimPolicy: Delete
   ---
   apiVersion: database.gcp.crossplane.io/v1beta1
   kind: CloudSQLInstanceClass
   metadata:
     name: cloudsqlinstancepostgresql-standard-default
     annotations:
       resourceclass.crossplane.io/is-default-class: "true"
   specTemplate:
     writeConnectionSecretsToNamespace: gitlab-managed-apps
     forProvider:
       databaseVersion: POSTGRES_11_7
       region: $REGION
       settings:
         tier: db-custom-1-3840
         dataDiskType: PD_SSD
         dataDiskSizeGb: 10
         ipConfiguration:
           privateNetwork: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
     # this should match the name of the provider created in the above step
     providerRef:
       name: gcp-provider
     reclaimPolicy: Delete
   EOF
   ```

1. Apply the resource class configuration with the following command:

   ```shell
   kubectl apply -f gcp-postgres-standard.yaml
   ```

1. Verify creation of the Resource class with the following command:

   ```shell
   kubectl get cloudsqlinstanceclasses
   ```

The Resource Classes allow you to define classes of service for a managed service.
We could create another `CloudSQLInstanceClass` which requests for a larger or a
faster disk. It could also request for a specific version of the database.

## Auto DevOps Configuration Options

You can run the Auto DevOps pipeline with either of the following options:

- Setting the Environment variables `AUTO_DEVOPS_POSTGRES_MANAGED` and
  `AUTO_DEVOPS_POSTGRES_MANAGED_CLASS_SELECTOR` to provision PostgreSQL using Crossplane.
- Overriding values for the Helm chart:
  - Set `postgres.managed` to `true`, which selects a default resource class.
    Mark the resource class with the annotation
    `resourceclass.crossplane.io/is-default-class: "true"`. The CloudSQLInstanceClass
    `cloudsqlinstancepostgresql-standard-default` is used to satisfy the claim.
  - Set `postgres.managed` to `true` with `postgres.managedClassSelector`
    providing the resource class to choose, based on labels. In this case, the
    value of `postgres.managedClassSelector.matchLabels.gitlab-ad-demo="true"`
    selects the CloudSQLInstance class `cloudsqlinstancepostgresql-standard`
    to satisfy the claim request.

The Auto DevOps pipeline should provision a PostgresqlInstance when it runs successfully.

To verify the PostgreSQL instance was created, run this command. When the `STATUS`
field of the PostgresqlInstance changes to `BOUND`, it's successfully provisioned:

```shell
$ kubectl get postgresqlinstance

NAME            STATUS   CLASS-KIND              CLASS-NAME                            RESOURCE-KIND      RESOURCE-NAME                               AGE
staging-test8   Bound    CloudSQLInstanceClass   cloudsqlinstancepostgresql-standard   CloudSQLInstance   xp-ad-demo-24-staging-staging-test8-jj55c   9m
```

The endpoint of the PostgreSQL instance, and the user credentials, are present in
a secret called `app-postgres` within the same project namespace. You can verify the
secret with the following command:

```shell
$ kubectl describe secret app-postgres

Name:         app-postgres
Namespace:    xp-ad-demo-24-staging
Labels:       <none>
Annotations:  crossplane.io/propagate-from-name: 108e460e-06c7-11ea-b907-42010a8000bd
              crossplane.io/propagate-from-namespace: gitlab-managed-apps
              crossplane.io/propagate-from-uid: 10c79605-06c7-11ea-b907-42010a8000bd

Type:  Opaque

Data
====
privateIP:                            8 bytes
publicIP:                             13 bytes
serverCACertificateCert:              1272 bytes
serverCACertificateCertSerialNumber:  1 bytes
serverCACertificateCreateTime:        24 bytes
serverCACertificateExpirationTime:    24 bytes
username:                             8 bytes
endpoint:                             8 bytes
password:                             27 bytes
serverCACertificateCommonName:        98 bytes
serverCACertificateInstance:          41 bytes
serverCACertificateSha1Fingerprint:   40 bytes
```

## Connect to the PostgreSQL instance

Follow this [GCP guide](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine) if you
would like to connect to the newly provisioned PostgreSQL database instance on CloudSQL.
