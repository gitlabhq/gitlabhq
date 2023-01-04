---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting the GitLab agent for Kubernetes

When you are using the GitLab agent for Kubernetes, you might experience issues you need to troubleshoot.

You can start by viewing the service logs:

```shell
kubectl logs -f -l=app=gitlab-agent -n gitlab-agent
```

If you are a GitLab administrator, you can also view the [GitLab agent server logs](../../../administration/clusters/kas.md#troubleshooting).

## Transport: Error while dialing failed to WebSocket dial

```json
{
  "level": "warn",
  "time": "2020-11-04T10:14:39.368Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://gitlab-kas:443/-/kubernetes-agent\\\": dial tcp: lookup gitlab-kas on 10.60.0.10:53: no such host\""
}
```

This error occurs when there are connectivity issues between the `kas-address`
and your agent pod. To fix this issue, make sure the `kas-address` is accurate.

```json
{
  "level": "error",
  "time": "2021-06-25T21:15:45.335Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc= \"transport: Error while dialing failed to WebSocket dial: expected handshake response status code 101 but got 301\""
}
```

This error occurs when the `kas-address` doesn't include a trailing slash. To fix this issue, make sure that the
`wss` or `ws` URL ends with a trailing slash, like `wss://GitLab.host.tld:443/-/kubernetes-agent/`
or `ws://GitLab.host.tld:80/-/kubernetes-agent/`.

## ValidationError(Deployment.metadata)

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

This error occurs when a manifest file is malformed and Kubernetes can't
create the specified objects. Make sure that your manifest files are valid.

For additional troubleshooting, try to use the manifest files to create objects in Kubernetes directly.

## Error while dialing failed to WebSocket dial: failed to send handshake request

```json
{
  "level": "warn",
  "time": "2020-10-30T09:50:51.173Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent\\\": net/http: HTTP/1.x transport connection broken: malformed HTTP response \\\"\\\\x00\\\\x00\\\\x06\\\\x04\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x05\\\\x00\\\\x00@\\\\x00\\\"\""
}
```

This error occurs when you configured `wss` as `kas-address` on the agent side,
but the agent server is not available at `wss`. To fix this issue, make sure the
same schemes are configured on both sides.

## Decompressor is not installed for grpc-encoding

```json
{
  "level": "warn",
  "time": "2020-11-05T05:25:46.916Z",
  "msg": "GetConfiguration.Recv failed",
  "error": "rpc error: code = Unimplemented desc = grpc: Decompressor is not installed for grpc-encoding \"gzip\""
}
```

This error occurs when the version of the agent is newer that the version of the agent server (KAS).
To fix it, make sure that both `agentk` and the agent server are the same version.

## Certificate signed by unknown authority

```json
{
  "level": "error",
  "time": "2021-02-25T07:22:37.158Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent/\\\": x509: certificate signed by unknown authority\""
}
```

This error occurs when your GitLab instance is using a certificate signed by an internal
certificate authority that is unknown to the agent.

To fix this issue, you can present the CA certificate file to the agent
by using a Kubernetes `configmap` and mount the file in the agent `/etc/ssl/certs` directory from where it
will be picked up automatically.

For example, if your internal CA certificate is `myCA.pem`:

```plaintext
kubectl -n gitlab-agent create configmap ca-pemstore --from-file=myCA.pem
```

Then in `resources.yml`:

```yaml
    spec:
      serviceAccountName: gitlab-agent
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
          secretName: gitlab-agent-token
      - name: ca-pemstore-volume
        configMap:
          name: ca-pemstore
          items:
          - key: myCA.pem
            path: myCA.pem
```

Alternatively, you can mount the certificate file at a different location and specify it for the
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

## Project not found

```json
{
  "level ":"error ",
  "time ":"2022-01-05T15:18:11.331Z",
  "msg ":"GetObjectsToSynchronize.Recv failed ",
  "mod_name ":"gitops ",
  "error ":"rpc error: code = NotFound desc = project not found ",
}
```

This error occurs when the project where you keep your manifests is not public. To fix it, make sure your project is public or your manifest files
are stored in the repository where the agent is configured.

## Failed to perform vulnerability scan on workload: jobs.batch already exists

```json
{
  "level": "error",
  "time": "2022-06-22T21:03:04.769Z",
  "msg": "Failed to perform vulnerability scan on workload",
  "mod_name": "starboard_vulnerability",
  "error": "running scan job: creating job: jobs.batch \"scan-vulnerabilityreport-b8d497769\" already exists"
}
```

The GitLab agent performs vulnerability scans by creating a job to scan each workload. If a scan
is interrupted, these jobs may be left behind and will need to be cleaned up before more jobs can
be run. You can clean up these jobs by running:

```shell
kubectl delete jobs -l app.kubernetes.io/managed-by=starboard -n gitlab-agent
```

[We're working on making the cleanup of these jobs more robust.](https://gitlab.com/gitlab-org/gitlab/-/issues/362016)

## Inventory policy prevented actuation (strategy: Apply, status: Empty, policy: MustMatch)

```json
{
  "error":"inventory policy prevented actuation (strategy: Apply, status: Empty, policy: MustMatch)",
  "group":"networking.k8s.io",
  "kind":"Deployment",
  "name":"resource-name",
  "namespace":"namespace",
  "status":"Skipped",
  "timestamp":"2022-10-29T15:34:21Z",
  "type":"apply"
}
```

This error occurs when the GitLab agent tries to update an object and the object doesn't have the required annotations. To fix this error, you can:

- Add the required annotations manually.
- Delete the object and let the agent recreate it.
- Change your [`inventory_policy`](../../infrastructure/clusters/deploy/inventory_object.md#inventory_policy-options) setting.

## Parse error during installation

When you install the agent, you might encounter an error that states:

```shell
Error: parse error at (gitlab-agent/templates/observability-secret.yaml:1): unclosed action
```

This error is typically caused by an incompatible version of Helm. To resolve the issue, ensure that you are using a version of Helm [compatible with your version of Kubernetes](index.md#supported-cluster-versions).
