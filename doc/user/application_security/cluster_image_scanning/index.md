---
type: reference, howto
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster Image Scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/) in GitLab 14.1.

WARNING:
This analyzer is in [Alpha](../../../policy/alpha-beta-support.md#alpha-features)
and is unstable. The JSON report and CI/CD configuration may be subject to change or breakage
across GitLab releases.

Your Kubernetes cluster may run workloads based on images that the Container Security analyzer
didn't scan. These images may therefore contain known vulnerabilities. By including an extra job in
your pipeline that scans for those security risks and displays them in the vulnerability report, you
can use GitLab to audit your Kubernetes workloads and environments.

GitLab provides integration with open-source tools for vulnerability analysis in Kubernetes clusters:

- [Starboard](https://github.com/aquasecurity/starboard)

To integrate GitLab with security scanners other than those listed here, see
[Security scanner integration](../../../development/integrations/secure.md).

You can use cluster image scanning through the following methods:

- [The cluster image scanning analyzer](#use-the-cluster-image-scanning-analyzer)
- [The GitLab agent](#cluster-image-scanning-with-the-gitlab-agent)

## Use the cluster image scanning analyzer

You can use the cluster image scanning analyzer to run cluster image scanning with [GitLab CI/CD](../../../ci/index.md).
To enable the cluster image scanning analyzer, [include the CI job](#configuration)
in your existing `.gitlab-ci.yml` file.

### Prerequisites

To enable cluster image scanning in your pipeline, you need the following:

- Cluster Image Scanning runs in the `test` stage, which is available by default. If you redefine the stages
  in the `.gitlab-ci.yml` file, the `test` stage is required.
- [GitLab Runner](https://docs.gitlab.com/runner/)
  with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html)
  or [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html)
  executor on Linux/amd64.
- Docker `18.09.03` or later installed on the same computer as the runner. If you're using the
  shared runners on GitLab.com, then this is already the case.
- [Starboard Operator](https://aquasecurity.github.io/starboard/v0.10.3/operator/installation/kubectl/)
  installed and configured in your cluster.
- The configuration for accessing your Kubernetes cluster stored in the `CIS_KUBECONFIG`
  [configuration variable](#cicd-variables-for-cluster-image-scanning)
  with the type set to `File` (see [Configuring the cluster](#configuring-the-cluster)).

### Configuring the cluster

1. Create a new service account.

   To properly fetch vulnerabilities from the cluster and to limit analyzer access to the workload,
   you must create a new service account with the cluster role limited to `get`, `list`, and `watch`
   `vulnerabilityreports` in the Kubernetes cluster:

   ```shell
   kubectl apply -f https://gitlab.com/gitlab-org/security-products/analyzers/cluster-image-scanning/-/raw/main/gitlab-vulnerability-viewer-service-account.yaml
   ```

1. Obtain the Kubernetes API URL.

   Get the API URL by running this command:

   ```shell
   API_URL=$(kubectl cluster-info | grep -E 'Kubernetes master|Kubernetes control plane' | awk '/http/ {print $NF}')
   ```

1. Obtain the CA certificate:

   1. List the secrets with `kubectl get secrets`. One should have a name similar to
      `default-token-xxxxx`. Copy that token name for use below.

   1. Run this command to get the certificate:

      ```shell
      CA_CERTIFICATE=$(kubectl get secret <secret name> -o jsonpath="{['data']['ca\.crt']}")
      ```

1. Obtain the service account token:

   ```shell
   TOKEN=$(kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep gitlab-vulnerability-viewer | awk '{print $1}') -o jsonpath="{.data.token}" | base64 --decode)
   ```

1. Generate the value for the `CIS_KUBECONFIG` variable. Copy the printed value from the output:

   ```shell
   echo "
   ---
   apiVersion: v1
   kind: Config
   clusters:
   - name: gitlab-vulnerabilities-viewer
     cluster:
       server: $API_URL
       certificate-authority-data: $CA_CERTIFICATE
   contexts:
   - name: gitlab-vulnerabilities-viewer
     context:
       cluster: gitlab-vulnerabilities-viewer
       namespace: default
       user: gitlab-vulnerabilities-viewer
   current-context: gitlab-vulnerabilities-viewer
   users:
   - name: gitlab-vulnerabilities-viewer
     user:
       token: $TOKEN
   "
   ```

1. Set the CI/CD variable:

   1. Navigate to your project's **Settings > CI/CD**.

   1. Expand the **Variables** section.

   1. Select **Add variable** and fill in the details:

      - **Key**: `CIS_KUBECONFIG`.
      - **Value**: `generated value`
      - **Type**: `File`

WARNING:
The `CIS_KUBECONFIG` variable is accessible by all jobs executed for your project. Mark the
`Protect variable` flag to export this variable to pipelines running on protected branches and tags
only. You can apply additional protection to your cluster by
[restricting service account access to a single namespace](https://kubernetes.io/docs/reference/access-authn-authz/rbac/),
and [configuring Starboard Operator](https://aquasecurity.github.io/starboard/v0.10.3/operator/configuration/#install-modes)
to install in restricted mode.

### Configuration

To include the `Cluster-Image-Scanning.gitlab-ci.yml` template (GitLab 14.1 and later), add the
following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/Cluster-Image-Scanning.gitlab-ci.yml
```

The included template:

- Creates a `cluster_image_scanning` job in your CI/CD pipeline.
- Connects to your Kubernetes cluster with credentials provided in the `CIS_KUBECONFIG` variable and
  fetches vulnerabilities found by [Starboard Operator](https://aquasecurity.github.io/starboard/v0.10.3/operator/).

GitLab saves the results as a
[Cluster Image Scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportscluster_image_scanning)
that you can download and analyze later. When downloading, you always receive the most recent
artifact.

#### Customize the cluster image scanning settings

You can customize how GitLab scans your cluster. For example, to restrict the analyzer to get
results for only a certain workload, use the [`variables`](../../../ci/yaml/index.md#variables)
parameter in your `.gitlab-ci.yml` to set [CI/CD variables](#cicd-variables-for-cluster-image-scanning).
The variables you set in your `.gitlab-ci.yml` overwrite those in
`Cluster-Image-Scanning.gitlab-ci.yml`.

##### CI/CD variables for cluster image scanning

You can [configure](#customize-the-cluster-image-scanning-settings) analyzers by using the following CI/CD variables:

| CI/CD Variable                 | Default       | Description |
| ------------------------------ | ------------- | ----------- |
| `CIS_KUBECONFIG`               | `""` | File used to configure access to the Kubernetes cluster. See the [Kubernetes documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) for more details. |
| `CIS_CONTAINER_NAMES` | `""` | A comma-separated list of container names used in the Kubernetes resources you want to filter vulnerabilities for. For example, `alpine,postgres`.  |
| `CIS_RESOURCE_NAMES` | `""` | A comma-separated list of Kubernetes resources you want to filter vulnerabilities for. For example, `nginx,redis`.   |
| `CIS_RESOURCE_NAMESPACES` | `""` | A comma-separated list of namespaces of the Kubernetes resources you want to filter vulnerabilities for. For example, `production,staging`.   |
| `CIS_RESOURCE_KINDS` | `""` | A comma-separated list of the kinds of Kubernetes resources to filter vulnerabilities for. For example, `deployment,pod`. |
| `CIS_CLUSTER_IDENTIFIER` | `""` | ID of the Kubernetes cluster integrated with GitLab. This is used to map vulnerabilities to the cluster so they can be filtered in the Vulnerability Report page. |
| `CIS_CLUSTER_AGENT_IDENTIFIER` | `""` | ID of the Kubernetes cluster agent integrated with GitLab. This maps vulnerabilities to the agent so they can be filtered in the Vulnerability Report page. |

#### Override the cluster image scanning template

If you want to override the job definition (for example, to change properties like `variables`), you
must declare and override a job after the template inclusion, and then
specify any additional keys.

This example sets `CIS_RESOURCE_NAME` to `nginx`:

```yaml
include:
  - template: Security/Cluster-Image-Scanning.gitlab-ci.yml

cluster_image_scanning:
  variables:
    CIS_RESOURCE_NAME: nginx
```

#### Connect with Kubernetes cluster associated to the project

If you want to connect to the Kubernetes cluster associated with the project and run Cluster Image Scanning jobs without
configuring the `CIS_KUBECONFIG` variable, you must extend `cluster_image_scanning` and specify the environment you want to scan.

This example configures the `cluster_image_scanning` job to scan the Kubernetes cluster connected with the `staging` environment:

```yaml
cluster_image_scanning:
  environment:
    name: staging
    action: prepare
```

### Reports JSON format

The cluster image scanning tool emits a JSON report file. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json).

Here's an example cluster image scanning report:

```json-doc
{
  "version": "14.0.2",
  "scan": {
    "scanner": {
      "id": "starboard_trivy",
      "name": "Trivy (using Starboard Operator)",
      "url": "https://github.com/aquasecurity/starboard",
      "vendor": {
        "name": "GitLab"
      },
      "version": "0.16.0"
    },
    "start_time": "2021-04-28T12:47:00Z",
    "end_time": "2021-04-28T12:47:00Z",
    "type": "cluster_image_scanning",
    "status": "success"
  },
  "vulnerabilities": [
    {
      "id": "c15f22205ee842184c2d55f1a207b3708283353f85083d66c34379c709b0ac9d",
      "category": "cluster_image_scanning",
      "message": "CVE-2011-3374 in apt",
      "description": "",
      "cve": "library/nginx:1.18:apt:CVE-2011-3374",
      "severity": "Low",
      "confidence": "Unknown",
      "solution": "Upgrade apt from 1.8.2.2",
      "scanner": {
        "id": "starboard_trivy",
        "name": "Trivy (using Starboard Operator)"
      },
      "location": {
        "dependency": {
          "package": {
            "name": "apt"
          },
          "version": "1.8.2.2"
        },
        "operating_system": "library/nginx:1.18",
        "image": "index.docker.io/library/nginx:1.18"
      },
      "identifiers": [
        {
          "type": "cve",
          "name": "CVE-2011-3374",
          "value": "CVE-2011-3374",
          "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2011-3374"
        }
      ],
      "links": [
        "https://avd.aquasec.com/nvd/cve-2011-3374"
      ]
    }
  ]
}
```

## Cluster image scanning with the GitLab agent

You can use the [GitLab agent](../../clusters/agent/index.md) to
scan images from within your Kubernetes cluster and record the vulnerabilities in GitLab.

### Prerequisites

- [Starboard Operator](https://aquasecurity.github.io/starboard/v0.10.3/operator/installation/kubectl/)
  installed and configured in your cluster.
- [GitLab agent](../../clusters/agent/install/index.md)
  set up in GitLab, installed in your cluster, and configured using a configuration repository.

### Configuration

The agent runs the cluster image scanning once the `cluster_image_scanning`
directive is added to your [agent's configuration repository](../../clusters/agent/vulnerabilities.md).

## Security Dashboard

The [Security Dashboard](../security_dashboard/index.md) shows you an overview of all
the security vulnerabilities in your groups, projects, and pipelines.

## Interacting with the vulnerabilities

After you find a vulnerability, you can address it in the [vulnerability report](../vulnerabilities/index.md)
or the [GitLab agent's](../../clusters/agent/vulnerabilities.md)
details section.

## Troubleshooting

### Getting warning message `gl-cluster-image-scanning-report.json: no matching files`

For information on this error, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).
