---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Agent for Kubernetes **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223061) in GitLab 13.4.
> - Support for `grpcs` [introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/7) in GitLab 13.6.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300960) in GitLab 13.10, KAS became available on GitLab.com under `wss://kas.gitlab.com` through an Early Adopter Program.
> - Introduced in GitLab 13.11, the GitLab Agent became available to every project on GitLab.com.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Renamed](https://gitlab.com/groups/gitlab-org/-/epics/7167) from "GitLab Kubernetes Agent" to "GitLab Agent for Kubernetes" in GitLab 14.6.

The [GitLab Agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) ("Agent", for short)
is an active in-cluster component for connecting Kubernetes clusters to GitLab safely to support cloud-native deployment, management, and monitoring.

The Agent is installed into the cluster through code, providing you with a fast, safe, stable, and scalable solution.

With GitOps, you can manage containerized clusters and applications from a Git repository that:

- Is the single source of truth of your system.
- Is the single place where you operate your system.
- Is a single resource to monitor your system.

By combining GitLab, Kubernetes, and GitOps, it results in a robust infrastructure:

- GitLab as the GitOps operator.
- Kubernetes as the automation and convergence system.
- GitLab CI/CD as the Continuous Integration and Continuous Deployment engine.

Beyond that, you can use all the features offered by GitLab as
the all-in-one DevOps platform for your product and your team.

## Agent's features

By using the Agent, you can:

- Connect GitLab with a Kubernetes cluster behind a firewall or a
Network Address Translation (NAT).
- Have real-time access to API endpoints in your cluster from GitLab CI/CD.
- Use GitOps to configure your cluster through the [Agent's repository](repository.md).
- Perform pull-based or push-based GitOps deployments.
- Configure [Network Security Alerts](#kubernetes-network-security-alerts)
based on [Container Network Policies](../../application_security/policies/index.md#container-network-policy).
- Track objects applied to your cluster through [inventory objects](../../infrastructure/clusters/deploy/inventory_object.md).
- Use the [CI/CD Tunnel](ci_cd_tunnel.md) to access Kubernetes clusters
from GitLab CI/CD jobs while keeping the cluster's APIs safe and unexposed
to the internet.
- [Deploy the GitLab Runner in a Kubernetes cluster](https://docs.gitlab.com/runner/install/kubernetes-agent.html).

See the [Agent roadmap](https://gitlab.com/groups/gitlab-org/-/epics/3329) to track its development.

To contribute to the Agent, see the [Agent's development documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc).

## Agent's GitOps workflow **(PREMIUM)**

The Agent uses multiple GitLab projects to provide a flexible workflow
that can suit various needs. This diagram shows these repositories and the main
actors involved in a deployment:

```mermaid
sequenceDiagram
  participant D as Developer
  participant A as Application code repository
  participant M as Manifest repository
  participant K as GitLab Agent
  participant C as Agent configuration repository
  loop Regularly
    K-->>C: Grab the configuration
  end
  D->>+A: Pushing code changes
  A->>M: Updating manifest
  loop Regularly
    K-->>M: Watching changes
    M-->>K: Pulling and applying changes
  end
```

For more details, refer to our [architecture documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md#high-level-architecture) in the Agent project.

## Install the Agent in your cluster

See how to [install the Agent in your cluster](install/index.md).

## GitOps deployments **(PREMIUM)**

To perform GitOps deployments with the Agent, you need:

- A properly-configured Kubernetes cluster where the Agent is running.
- A [configuration repository](repository.md) that contains a
`config.yaml` file, which tells the Agent the repositories to synchronize
with the cluster.
- A manifest repository that contains manifest files. Any changes to manifest files are applied to the cluster.

You can use a single GitLab project or different projects for the Agent
configuration and manifest files, as follows:

- Single GitLab project (recommended): When you use a single repository to hold
  both the manifest and the configuration files, these projects can be either
  private or public.
- Two GitLab projects: When you use two different GitLab projects (one for
  manifest files and another for configuration files), the manifests project must
  be public, while the configuration project can be either private or public.

Support for separated private manifest and configuration repositories is tracked in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/220912).

## Kubernetes Network Security Alerts **(ULTIMATE)**

The GitLab Agent also provides an integration with Cilium. This integration provides a simple way to
generate network policy-related alerts and to surface those alerts in GitLab.

There are several components that work in concert for the Agent to generate the alerts:

- A working Kubernetes cluster.
- Cilium integration through either of these options:
  - Installation through [cluster management template](../../project/clusters/protect/container_network_security/quick_start_guide.md#use-the-cluster-management-template-to-install-cilium).
  - Enablement of [hubble-relay](https://docs.cilium.io/en/v1.8/concepts/overview/#hubble) on an
    existing installation.
- One or more network policies through any of these options:
  - Use the [Container Network Policy editor](../../application_security/policies/index.md#container-network-policy-editor) to create and manage policies.
  - Use an [AutoDevOps](../../application_security/policies/index.md#container-network-policy) configuration.
  - Add the required labels and annotations to existing network policies.
- A configuration repository with [Cilium configured in `config.yaml`](repository.md#surface-network-security-alerts-from-cluster-to-gitlab)

The setup process follows the same [Agent's installation steps](install/index.md),
with the following differences:

- When you define a configuration repository, you must do so with [Cilium settings](repository.md#surface-network-security-alerts-from-cluster-to-gitlab).
- You do not need to specify the `gitops` configuration section.

## Remove an agent

You can remove an agent using the [GitLab UI](#remove-an-agent-through-the-gitlab-ui) or through the [GraphQL API](#remove-an-agent-with-the-gitlab-graphql-api).

### Remove an agent through the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323055) in GitLab 14.7.

To remove an agent from the UI:

1. Go to your agent's configuration repository.
1. From your project's sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select your agent from the table, and then in the **Options** column, click the vertical ellipsis
(**{ellipsis_v}**) button and select **Delete agent**.

### Remove an agent with the GitLab GraphQL API

1. Get the `<cluster-agent-token-id>` from a query in the interactive GraphQL explorer.
For GitLab.com, go to <https://gitlab.com/-/graphql-explorer> to open GraphQL Explorer.
For self-managed GitLab instances, go to `https://gitlab.example.com/-/graphql-explorer`, replacing `gitlab.example.com` with your own instance's URL.

   ```graphql
   query{
     project(fullPath: "<full-path-to-agent-configuration-project>") {
       clusterAgent(name: "<agent-name>") {
         id
         tokens {
           edges {
             node {
               id
             }
           }
         }
       }
     }
   }
   ```

1. Remove an agent record with GraphQL by deleting the `clusterAgentToken`.

   ```graphql
   mutation deleteAgent {
     clusterAgentDelete(input: { id: "<cluster-agent-id>" } ) {
       errors
     }
   }

   mutation deleteToken {
     clusterAgentTokenDelete(input: { id: "<cluster-agent-token-id>" }) {
       errors
     }
   }
   ```

1. Verify whether the removal occurred successfully. If the output in the Pod logs includes `unauthenticated`, it means that the agent was successfully removed:

   ```json
   {
       "level": "warn",
       "time": "2021-04-29T23:44:07.598Z",
       "msg": "GetConfiguration.Recv failed",
       "error": "rpc error: code = Unauthenticated desc = unauthenticated"
   }
   ```

1. Delete the Agent in your cluster:

   ```shell
   kubectl delete -n gitlab-kubernetes-agent -f ./resources.yml
   ```

## Migrating to the GitLab Agent from the legacy certificate-based integration

Find out how to [migrate to the GitLab Agent for Kubernetes](../../infrastructure/clusters/migrate_to_gitlab_agent.md) from the certificate-based integration depending on the features you use.

## Troubleshooting

If you face any issues while using the Agent, read the
service logs with the following command:

```shell
kubectl logs -f -l=app=gitlab-kubernetes-agent -n gitlab-kubernetes-agent
```

GitLab administrators can additionally view the [GitLab Agent Server logs](../../../administration/clusters/kas.md#troubleshooting).

### Agent logs

#### Transport: Error while dialing failed to WebSocket dial

```json
{
  "level": "warn",
  "time": "2020-11-04T10:14:39.368Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://gitlab-kas:443/-/kubernetes-agent\\\": dial tcp: lookup gitlab-kas on 10.60.0.10:53: no such host\""
}
```

This error is shown if there are some connectivity issues between the address
specified as `kas-address`, and your Agent pod. To fix it, make sure that you
specified the `kas-address` correctly.

```json
{
  "level": "error",
  "time": "2021-06-25T21:15:45.335Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc= \"transport: Error while dialing failed to WebSocket dial: expected handshake response status code 101 but got 301\""
}
```

This error occurs if the `kas-address` doesn't include a trailing slash. To fix it, make sure that the
`wss` or `ws` URL ends with a trailing slash, such as `wss://GitLab.host.tld:443/-/kubernetes-agent/`
or `ws://GitLab.host.tld:80/-/kubernetes-agent/`.

#### ValidationError(Deployment.metadata)

```json
{
  "level": "info",
  "time": "2020-10-30T08:56:54.329Z",
  "msg": "Synced",
  "project_id": "root/kas-manifest001",
  "resource_key": "apps/Deployment/kas-test001/nginx-deployment",
  "sync_result": "error validating data: [ValidationError(Deployment.metadata): unknown field \"replicas\" in io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta, ValidationError(Deployment.metadata): unknown field \"selector\" in io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta, ValidationError(Deployment.metadata): unknown field \"template\" in io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta]"
}
```

This error is shown if a manifest file is malformed, and Kubernetes can't
create specified objects. Make sure that your manifest files are valid. You
may try using them to create objects in Kubernetes directly for more troubleshooting.

#### Error while dialing failed to WebSocket dial: failed to send handshake request

```json
{
  "level": "warn",
  "time": "2020-10-30T09:50:51.173Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent\\\": net/http: HTTP/1.x transport connection broken: malformed HTTP response \\\"\\\\x00\\\\x00\\\\x06\\\\x04\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x05\\\\x00\\\\x00@\\\\x00\\\"\""
}
```

This error is shown if you configured `wss` as `kas-address` on the agent side,
but KAS on the server side is not available via `wss`. To fix it, make sure the
same schemes are configured on both sides.

It's not possible to set the `grpc` scheme due to the issue
[It is not possible to configure KAS to work with `grpc` without directly editing GitLab KAS deployment](https://gitlab.com/gitlab-org/gitlab/-/issues/276888). To use `grpc` while the
issue is in progress, directly edit the deployment with the
`kubectl edit deployment gitlab-kas` command, and change `--listen-websocket=true` to `--listen-websocket=false`. After running that command, you should be able to use
`grpc://gitlab-kas.<YOUR-NAMESPACE>:8150`.

#### Decompressor is not installed for grpc-encoding

```json
{
  "level": "warn",
  "time": "2020-11-05T05:25:46.916Z",
  "msg": "GetConfiguration.Recv failed",
  "error": "rpc error: code = Unimplemented desc = grpc: Decompressor is not installed for grpc-encoding \"gzip\""
}
```

This error is shown if the version of the agent is newer that the version of KAS.
To fix it, make sure that both `agentk` and KAS use the same versions.

#### Certificate signed by unknown authority

```json
{
  "level": "error",
  "time": "2021-02-25T07:22:37.158Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent/\\\": x509: certificate signed by unknown authority\""
}
```

This error is shown if your GitLab instance is using a certificate signed by an internal CA that
is unknown to the agent. One approach to fixing it is to present the CA certificate file to the agent
via a Kubernetes `configmap` and mount the file in the agent `/etc/ssl/certs` directory from where it
will be picked up automatically.

For example, if your internal CA certificate is `myCA.pem`:

```plaintext
kubectl -n gitlab-kubernetes-agent create configmap ca-pemstore --from-file=myCA.pem
```

Then in `resources.yml`:

```yaml
    spec:
      serviceAccountName: gitlab-kubernetes-agent
      containers:
      - name: agent
        image: "registry.gitlab.com/gitlab-org/cluster-integration/gitlab-agent/agentk:<version>"
        args:
        - --token-file=/config/token
        - --kas-address
        - wss://kas.host.tld:443 # replace this line with the line below if using Omnibus GitLab or GitLab.com.
        # - wss://gitlab.host.tld:443/-/kubernetes-agent/
        # - wss://kas.gitlab.com # for GitLab.com users, use this KAS.
        # - grpc://host.docker.internal:8150 # use this attribute when connecting from Docker.
        volumeMounts:
        - name: token-volume
          mountPath: /config
        - name: ca-pemstore-volume
          mountPath: /etc/ssl/certs/myCA.pem
          subPath: myCA.pem
      volumes:
      - name: token-volume
        secret:
          secretName: gitlab-kubernetes-agent-token
      - name: ca-pemstore-volume
        configMap:
          name: ca-pemstore
          items:
          - key: myCA.pem
            path: myCA.pem
```

Alternatively, you can mount the certificate file at a different location and include it using the
`--ca-cert-file` agent parameter:

```yaml
      containers:
      - name: agent
        image: "registry.gitlab.com/gitlab-org/cluster-integration/gitlab-agent/agentk:<version>"
        args:
        - --ca-cert-file=/tmp/myCA.pem
        - --token-file=/config/token
        - --kas-address
        - wss://kas.host.tld:443 # replace this line with the line below if using Omnibus GitLab or GitLab.com.
        # - wss://gitlab.host.tld:443/-/kubernetes-agent/
        # - wss://kas.gitlab.com # for GitLab.com users, use this KAS.
        # - grpc://host.docker.internal:8150 # use this attribute when connecting from Docker.
        volumeMounts:
        - name: token-volume
          mountPath: /config
        - name: ca-pemstore-volume
          mountPath: /tmp/myCA.pem
          subPath: myCA.pem
```
