# Namespaces

## List namespaces

Get a list of namespaces. (As user: my namespaces, as admin: all namespaces)

```
GET /namespaces
```

```json
[
  {
    "id": 1,
    "path": "user1",
    "kind": "user"
  },
  {
    "id": 2,
    "path": "group1",
    "kind": "group"
  }
]
```

You can search for namespaces by name or path, see below.

## Search for namespace

Get all namespaces that match your string in their name or path.

```
GET /namespaces?search=foobar
```

```json
[
  {
    "id": 1,
    "path": "user1",
    "kind": "user"
  }
]
```
