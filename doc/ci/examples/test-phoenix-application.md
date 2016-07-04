## Test a Phoenix application

This example demonstrates the integration of Gitlab CI with Phoenix, elixir and
postgres.

### Add `.gitlab-ci.yml` file to project

The following `.gitlab-ci.yml` should be added in the root of your
repository to trigger CI:

```yaml
image: elixir:1.3.1

services:
  - postgres:9.5.3

variables:
  MIX_ENV: "test"

before_script:
  # Setup phoenix dependencies
  - apt-get update
  - apt-get install -y postgresql-client
  - mix local.hex --force
  - mix deps.get --only test
  - mix ecto.reset

test:
  script:
    - mix test
```

The variables will set the Mix environment to test. The
before_script will install `psql`, and other phoenix dependencies and will also
run your migrations.

Finally, the test script will run your tests.

### Update the Config Settings

In `config/test.exs`, update the database hostname:
```
config :my_app, MyApp.Repo,
  hostname: if(System.get_env("CI"), do: "postgres", else: "localhost"),
```

### Add the Migrations Folder

If you do not have any migrations yet, you will need to create an empty
`.gitkeep` file in `priv/repo/migrations`.

**Source**: https://medium.com/@nahtnam/using-phoenix-on-gitlab-ci-5a51eec81142
