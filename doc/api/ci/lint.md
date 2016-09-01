# Validate the .gitlab-ci.yml

Check whether your .gitlab-ci.yml file is valid.

```
POST ci/lint
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `content`  | hash    | yes      | the .gitlab-ci.yaml content|

```bash
curl --request POST "https://gitlab.example.com/api/v3/ci/lint?content=YAML+Content"
```

Example response:

* valid content

```json
{
  "status": "valid",
  "errors": []
}
```

* invalid content

```json
{
  "status": "invalid",
  "errors": [
    "variables config should be a hash of key value pairs"
  ]
}
```

* without the content attribute

```json
{
  "error": "content is missing"
}
```
