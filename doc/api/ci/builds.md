# Builds API

API used by runners to receive and update builds.

>**Note:**
This API is intended to be used only by Runners as their own
communication channel. For the consumer API see the
[Builds API](../builds.md).

## Authentication

This API uses two types of authentication:

1. Unique Runner's token which is the token assigned to the Runner after it
   has been registered.

2. Using the build authorization token.
   This is project's CI token that can be found under the **Builds** section of
   a project's settings. The build authorization token can be passed as a
   parameter or a value of `BUILD-TOKEN` header.

These two methods of authentication are interchangeable.

## Builds

### Runs oldest pending build by runner

```
POST /ci/api/v1/builds/register
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `token`   | string  | yes      | Unique runner token |


```
curl --request POST "https://gitlab.example.com/ci/api/v1/builds/register" --form "token=t0k3n"
```

**Responses:**

| Status | Data |Description                                                                |
|--------|------|---------------------------------------------------------------------------|
| `201`  | yes  | When a build is scheduled for a runner                                    |
| `204`  | no   | When no builds are scheduled for a runner (for GitLab Runner >= `v1.3.0`) |
| `403`  | no   | When invalid token is used or no token is sent                            |
| `404`  | no   | When no builds are scheduled for a runner (for GitLab Runner < `v1.3.0`) **or** when the runner is set to `paused` in GitLab runner's configuration page |

### Update details of an existing build

```
PUT /ci/api/v1/builds/:id
```

| Attribute | Type    | Required | Description          |
|-----------|---------|----------|----------------------|
| `id`      | integer | yes      | The ID of a project  |
| `token`   | string  | yes      | Unique runner token  |
| `state`   | string  | no       | The state of a build |
| `trace`   | string  | no       | The trace of a build |

```
curl --request PUT "https://gitlab.example.com/ci/api/v1/builds/1234" --form "token=t0k3n" --form "state=running" --form "trace=Running git clone...\n"
```

### Incremental build trace update

Using this method you need to send trace content as a request body. You also need to provide the `Content-Range` header
with a range of sent trace part. Note that you need to send parts in the proper order, so the begining of the part
must start just after the end of the previous part. If you provide the wrong part, then GitLab CI API will return `416
Range Not Satisfiable` response with a header `Range: 0-X`, where `X` is the current trace length.

For example, if you receive `Range: 0-11` in the response, then your next part must contain a `Content-Range: 11-...`
header and a trace part covered by this range.

For a valid update API will return `202` response with:
* `Build-Status: {status}` header containing current status of the build,
* `Range: 0-{length}` header with the current trace length.

```
PATCH /ci/api/v1/builds/:id/trace.txt
```

Parameters:

| Attribute | Type    | Required | Description          |
|-----------|---------|----------|----------------------|
| `id`      | integer | yes      | The ID of a build    |

Headers:

| Attribute       | Type    | Required | Description                       |
|-----------------|---------|----------|-----------------------------------|
| `BUILD-TOKEN`   | string  | yes      | The build authorization token     |
| `Content-Range` | string  | yes      | Bytes range of trace that is sent |

```
curl --request PATCH "https://gitlab.example.com/ci/api/v1/builds/1234/trace.txt" --header "BUILD-TOKEN=build_t0k3n" --header "Content-Range=0-21" --data "Running git clone...\n"
```


### Upload artifacts to build

```
POST /ci/api/v1/builds/:id/artifacts
```

| Attribute | Type    | Required | Description                   |
|-----------|---------|----------|-------------------------------|
| `id`      | integer | yes      | The ID of a build             |
| `token`   | string  | yes      | The build authorization token |
| `file`    | mixed   | yes      | Artifacts file                |

```
curl --request POST "https://gitlab.example.com/ci/api/v1/builds/1234/artifacts" --form "token=build_t0k3n" --form "file=@/path/to/file"
```

### Download the artifacts file from build

```
GET /ci/api/v1/builds/:id/artifacts
```

| Attribute | Type    | Required | Description                   |
|-----------|---------|----------|-------------------------------|
| `id`      | integer | yes      | The ID of a build             |
| `token`   | string  | yes      | The build authorization token |

```
curl "https://gitlab.example.com/ci/api/v1/builds/1234/artifacts" --form "token=build_t0k3n"
```

### Remove the artifacts file from build

```
DELETE /ci/api/v1/builds/:id/artifacts
```

| Attribute | Type    | Required | Description                   |
|-----------|---------|----------|-------------------------------|
| ` id`     | integer | yes      | The ID of a build             |
| `token`   | string  | yes      | The build authorization token |

```
curl --request DELETE "https://gitlab.example.com/ci/api/v1/builds/1234/artifacts" --form "token=build_t0k3n"
```
