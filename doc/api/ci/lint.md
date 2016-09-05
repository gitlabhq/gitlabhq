# Validate the .gitlab-ci.yml

> [Introduced][ce-5953] in GitLab 8.12.

Check whether your .gitlab-ci.yml file is valid.

```
POST ci/lint
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `content`  | hash    | yes      | the .gitlab-ci.yaml content|

```bash
curl --request POST "https://gitlab.example.com/api/v3/ci/lint?content={
  image: "ruby:2.1",
  services: ["postgres"],
  before_script: ["gem install bundler", "bundle install", "bundle exec rake db:create"],
  variables: {"DB_NAME": "postgres"},
  types: ["test", "deploy", "notify"],
  rspec: {
    script: "rake spec",
    tags: ["ruby", "postgres"],
    only: ["branches"]
  },
  spinach: {
    script: "rake spinach",
    allow_failure: true,
    tags: ["ruby", "mysql"],
    except: ["tags"]
  },
  staging: {
    variables: {KEY1: "value1", KEY2: "value2"},
    script: "cap deploy stating",
    type: "deploy",
    tags: ["ruby", "mysql"],
    except: ["stable"]
  },
  production: {
    variables: {DB_NAME: "mysql"},
    type: "deploy",
    script: ["cap deploy production", "cap notify"],
    tags: ["ruby", "mysql"],
    only: ["master", "/^deploy-.*$/"]
  },
  dockerhub: {
    type: "notify",
    script: "curl http://dockerhub/URL",
    tags: ["ruby", "postgres"],
    only: ["branches"]
  }
}"
```

Be sure to copy paste the exact contents of `.gitlab-ci.yml` as YAML is very picky with indentation and spaces.

Example responses:

* Valid content:

    ```json
    {
      "status": "valid",
      "errors": []
    }
    ```

* Invalid content:

    ```json
    {
      "status": "invalid",
      "errors": [
        "variables config should be a hash of key value pairs"
      ]
    }
    ```

* Without the content attribute:

    ```json
    {
      "error": "content is missing"
    }
    ```
