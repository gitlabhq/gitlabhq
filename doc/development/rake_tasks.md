# Rake tasks for developers

## Setup db with developer seeds:

Note that if your db user does not have advanced privilegies you must create db manually before run this command 

```
bundle exec rake setup
```

## Run tests

This runs all test suite present in GitLab 

```
bundle exec rake test
```

## Generate searchable docs for source code

You can find results under `doc/code` directory

```
bundle exec rake gitlab:generate_docs
```
