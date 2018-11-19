# Switching to Rails 5

GitLab switched recently to Rails 5. This is a big change (especially for backend development) and it introduces couple of temporary inconveniences.

## After the switch, I found a broken feature. What do I do?

Many fixes and tweaks were done to make our codebase compatible with Rails 5, but it's possible that not all issues were found. If you find an bug, please create an issue and assign it the ~rails5 label.

## It takes much longer to run CI pipelines that build GitLab. Why?

We are temporarily running CI pipelines with Rails 4 and 5 so that we ensure we remain compatible with Rails 4 in case we must revert back to Rails 4 from Rails 5 (this can double the duration of CI pipelines).

We might revert back to Rails 4 if we found a major issue we were unable to quickly fix.

Once we are sure we can stay with Rails 5, we will stop running CI pipelines with Rails 4.

## Can I skip running Rails 4 tests?

If you are sure that your merge request doesn't introduce any incompatibility, you can just include `norails4` anywhere in your branch name and Rails 4 tests will be skipped.

## CI is failing on my test with Rails 4. How can I debug it?

You can run specs locally with Rails 4 using the following command:

```sh
BUNDLE_GEMFILE=Gemfile.rails4 RAILS5=0 bundle exec rspec ...
```
