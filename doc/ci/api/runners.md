# Runners API

## Runners

### Retrieve all runners

__Authentication is done by GitLab user token & GitLab url__

Used to get information about all runners registered on the Gitlab CI
instance.

    GET /ci/runners

Returns:

```json
[
  {
    "id" : 85,
    "token" : "12b68e90394084703135"
  },
  {
    "id" : 86,
    "token" : "76bf894e969364709864"
  },
]
```

### Register a new runner


__Authentication is done with a Shared runner registration token or a project Specific runner registration token__

Used to make Gitlab CI aware of available runners.

    POST /ci/runners/register

Parameters:

  * `token` (required) - The registration token. It is 2 types of token you can pass here. 

1. Shared runner registration token
2. Project specific registration token

Returns:

```json
{
  "id" : 85,
  "token" : "12b68e90394084703135"
}
```

### Delete a runner


__Authentication is done by runner token__

Used to removing runners.

    DELETE /ci/runners/delete

Parameters:

  * `token` (required) - The runner token.

Returns:

```json
{
  "id" : 1,
  "token" : "d14963981a428f70121777e50643d1",
  "created_at" : "2015-02-26T11:39:39.232Z",
  "updated_at" : "2015-02-26T11:39:39.232Z",
  "description" : "awesome runner"
}
```