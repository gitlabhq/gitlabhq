# Rake tasks for developers

## Setup db with developer seeds:

Note that if your db user does not have advanced privileges you must create the db manually before running this command.

```
bundle exec rake setup
```

## Run tests

This runs all test suites present in GitLab.

```
bundle exec rake test
```

## Generate searchable docs for source code

You can find results under the `doc/code` directory.

```
bundle exec rake gitlab:generate_docs
```
