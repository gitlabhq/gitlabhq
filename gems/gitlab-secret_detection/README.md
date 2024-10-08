# Gitlab::SecretDetection

The gitlab-secret_detection gem performs keyword and regex matching on input payloads that may include secrets. The gem accepts one or more payloads, matches them against a defined ruleset of regular expressions, and returns scan results.

##### Scan parameters

The method for triggering the scan (
i.e.,[`Gitlab::SecretDetection.secrets_scan`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L75))
accepts the following parameters:

| Parameter      | Type    | Required | Default                                                                                                                                                             | Description                                                                                                                                                                                                                                                                                                                                                                |
|----------------|---------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `payloads`        | Array   | Yes      | NA                                                                                                                                                                  | Array of input payloads. Each payload has attributes: `id`, and data`.                                                                                                                                                                                              |
| `timeout`      | Number  | No       | [`60s`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L22)  | The maximum duration allowed for the scan to run on a commit request comprising multiple blobs. If the specified timeout elapses, the scan is automatically terminated. The timeout duration is specified in seconds but can also accept floating-point values to denote smaller units. For instance, use `0.5` to represent `500ms`.                                      |
| `payload_timeout` | Number  | No       | [`5s`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L24)   | The maximum duration allowed for the scan to run on an individual payload. Upon expiration of the specified timeout, the scan is interrupted for the current payload and advances to the next payload in the request. The timeout duration is specified in seconds but can also accept floating-point values to denote smaller units. For instance, use `0.5` to represent `500ms`. |
| `subprocess`   | Boolean | No       | [`true`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L34) | Runs the scan operation within a subprocess rather than the main process. This design aims to mitigate memory overconsumption issues that may arise from scanning multiple large paylaods within a single subprocess. Check [here](https://docs.gitlab.com/ee/architecture/blueprints/secret_detection/decisions/002_run_scan_within_subprocess.html) for more details.       |

##### Scan Constraints

| Name                            | Value                                                                                                                                                               | Description                                                                                                                                                 |
|---------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `MAX_PROCS_PER_REQUEST`         | [`5`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L29)    | The maximum number of processes spawned per commit request.                                                                                                 |
| `MIN_CHUNK_SIZE_PER_PROC_BYTES` | [`2MiB`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L32) | The minimum cumulative size of blobs necessary to initiate the creation of a new subprocess, where the scan will be executed within that dedicated process. |

##### Ruleset Source

The Ruleset file referenced for running the Pre-receive Secret Detection is
located [here](https://gitlab.com/gitlab-org/gitlab/-/blob/2da1c72dbc9df4d9130262c6b79ea785b6bb14ac/gems/gitlab-secret_detection/lib/gitleaks.toml).

