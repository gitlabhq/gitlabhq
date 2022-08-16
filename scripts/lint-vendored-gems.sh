#!/bin/sh

# Rubocop doesn't have a good way to run excluded files without a separate invocation:
# https://github.com/rubocop/rubocop/issues/6323
find vendor/gems -name \*.gemspec | xargs bundle exec rubocop --only Gemspec/AvoidExecutingGit
