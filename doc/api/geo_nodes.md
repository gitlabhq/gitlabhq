# Geo Nodes API

In order to interact with Geo node endpoints, you need to authenticate yourself
as an admin.

## Retrieve configuration about all Geo nodes

```
GET /geo_nodes
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/geo_nodes
```

Example response:

```json
[
  {
    "id": 1,
    "url": "https://primary.example.com/",
    "primary": true,
    "enabled": true,
    "files_max_capacity": 10,
    "repos_max_capacity": 25,
    "clone_protocol": "ssh"
  },
  {
    "id": 2,
    "url": "https://secondary.example.com/",
    "primary": false,
    "enabled": true,
    "files_max_capacity": 10,
    "repos_max_capacity": 25,
    "clone_protocol": "http"
  }
]
```

## Retrieve configuration about a specific Geo node

```
GET /geo_nodes/:id
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/geo_nodes/1
```

Example response:

```json
{
  "id": 1,
  "url": "https://primary.example.com/",
  "primary": true,
  "enabled": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "clone_protocol": "ssh"
}
```

## Retrieve status about all secondary Geo nodes

```
GET /geo_nodes/status
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/geo_nodes/status
```

Example response:

```json
[
  {
    "geo_node_id": 2,
    "healthy": true,
    "health": "Healthy",
    "attachments_count": 1,
    "attachments_synced_count": 1,
    "attachments_failed_count": 0,
    "attachments_synced_in_percentage": "100.00%",
    "db_replication_lag_seconds": 0,
    "lfs_objects_count": 0,
    "lfs_objects_synced_count": 0,
    "lfs_objects_failed_count": 0,
    "lfs_objects_synced_in_percentage": "0.00%",
    "repositories_count": 41,
    "repositories_failed_count": 1,
    "repositories_synced_count": 40,
    "repositories_synced_in_percentage": "97.56%",
    "last_event_id": 23,
    "last_event_timestamp": 1509681166,
    "cursor_last_event_id": 23,
    "cursor_last_event_timestamp": 1509681166,
    "last_successful_status_check_timestamp": 1510125024
  }
]
```

## Retrieve status about a specific secondary Geo node

```
GET /geo_nodes/:id/status
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/geo_nodes/2/status
```

Example response:

```json
{
  "geo_node_id": 2,
  "healthy": true,
  "health": "Healthy",
  "attachments_count": 1,
  "attachments_synced_count": 1,
  "attachments_failed_count": 0,
  "attachments_synced_in_percentage": "100.00%",
  "db_replication_lag_seconds": 0,
  "lfs_objects_count": 0,
  "lfs_objects_synced_count": 0,
  "lfs_objects_failed_count": 0,
  "lfs_objects_synced_in_percentage": "0.00%",
  "repositories_count": 41,
  "repositories_failed_count": 1,
  "repositories_synced_count": 40,
  "repositories_synced_in_percentage": "97.56%",
  "last_event_id": 23,
  "last_event_timestamp": 1509681166,
  "cursor_last_event_id": 23,
  "cursor_last_event_timestamp": 1509681166,
  "last_successful_status_check_timestamp": 1510125268
}
```
