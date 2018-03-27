# Test a Clojure application with GitLab CI/CD

This example will guide you how to run tests in your Clojure application.

You can checkout the example [source](https://gitlab.com/dzaporozhets/clojure-web-application) and check [CI status](https://gitlab.com/dzaporozhets/clojure-web-application/builds?scope=all).

## Configure the project

This is what the `.gitlab-ci.yml` file looks like for this project:

```yaml
variables:
  POSTGRES_DB: sample-test
  DATABASE_URL: "postgresql://postgres@postgres:5432/sample-test"

before_script:
  - apt-get update -y
  - apt-get install default-jre postgresql-client -y
  - wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
  - chmod a+x lein
  - export LEIN_ROOT=1
  - PATH=$PATH:.
  - lein deps
  - lein migratus migrate

test:
  script:
    - lein test
```

In before script we install JRE and [Leiningen](http://leiningen.org/).
Sample project uses [migratus](https://github.com/yogthos/migratus) library to manage database migrations.
So we added database migration as last step of `before_script` section

You can use public runners available on `gitlab.com` for testing your application with such configuration.
