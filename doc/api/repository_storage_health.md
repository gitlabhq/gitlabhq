# Circuitbreaker API

> [Introduced][ce-11449] in GitLab 9.5.

The Circuitbreaker API is only accessible to administrators. All requests by
guests will respond with `401 Unauthorized`, and all requests by normal users
will respond with `403 Forbidden`.

## Repository Storages

### Get all storage information

Returns of all currently configured storages and their health information.

```
GET /circuit_breakers/repository_storage
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/circuit_breakers/repository_storage
```

```json
[
  {
    "storage_name": "default",
    "failing_on_hosts": [],
    "total_failures": 0
  },
  {
    "storage_name": "broken",
    "failing_on_hosts": [
      "web01", "worker01"
    ],
    "total_failures": 1
  }
]
```

### Get failing storages

This returns a list of all currently failing storages.

```
GET /circuit_breakers/repository_storage/failing
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/circuit_breakers/repository_storage/failing
```

```json
[
    {
        "storage_name":"broken",
        "failing_on_hosts":["web01", "worker01"],
        "total_failures":2
    }
]
```

## Reset failing storage information

Use this remove all failing storage information and allow access to the storage again.

```
DELETE /circuit_breakers/repository_storage
```

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/circuit_breakers/repository_storage
```

[ce-11449]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11449
