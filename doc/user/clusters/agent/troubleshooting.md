---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting the GitLab agent for Kubernetes

When you are using the GitLab agent for Kubernetes, you might experience issues you need to troubleshoot.

You can start by viewing the service logs:

```shell
kubectl logs -f -l=app=gitlab-agent -n gitlab-kubernetes-agent
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

This error is shown if there are some connectivity issues between the address
specified as `kas-address`, and your agent pod. To fix it, make sure that you
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

This error is shown if a manifest file is malformed, and Kubernetes can't
create specified objects. Make sure that your manifest files are valid. You
may try using them to create objects in Kubernetes directly for more troubleshooting.

## Error while dialing failed to WebSocket dial: failed to send handshake request

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

## Decompressor is not installed for grpc-encoding

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

This error is shown if the manifest project is not public. To fix it, make sure your manifest project is public or your manifest files
are stored in the agent's configuration repository.
