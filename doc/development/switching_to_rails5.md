# Switching to Rails 5

GitLab has switched recently to Rails 5. This is a big change (especially for backend development) and it introduces couple of temporary inconveniences.

### Q: Hey, after the switch this feature is broken. How is it possible?
A: Many fixes and tweaks were done to make our codebase compatible with Rails 5, but it's possible that not all issues were found. If you find an bug, please create an issue and assign it ~rails5 label.

### Q: It takes much longer time to run CI on my merge requests, why?
A: If we would find a major issue after switching to Rails 5 and we wouldn't be able to fix it, we would have to switch back to Rails 4. To make sure that no Rails 4 incompatible changes are introduced until we are sure that we can stick with Rails 5, we will run CI both with Rails 4 and 5 (this means that CI may take twice more time to finish). This is only a temporary policy and running jobs on Rails 4 will be removed in a couple of weeks.

### Q: Can I skip running Rails 4 tests?
A: If you are sure that your merge request doesn't introduce any incompatibility, you can just include 'norails4' in your branch name and Rails 4 tests will be skipped.

### Q: CI is failing on my test with Rails 4, how can I debug it?
A: You can run specs locally with Rails 4 with: `BUNDLE_GEMFILE=Gemfile.rails4 RAILS5=0 bundle exec rspec ...`
