### Summary

(Summarize the bug encountered concisely)

### Steps to reproduce

(How one can reproduce the issue - this is very important)

### What is the current *bug* behavior?

(What actually happens)

### What is the expected *correct* behavior?

(What you should see instead)

### Relevant logs and/or screenshots

(Paste any relevant logs - please use code blocks (```) to format console output,
logs, and code as it's very hard to read otherwise.)

### Output of checks

(If you are reporting a bug on GitLab.com, write: This bug happens on GitLab.com)

#### Results of GitLab environment info

(For installations with omnibus-gitlab package run and paste the output of:
`sudo gitlab-rake gitlab:env:info`)

(For installations from source run and paste the output of:
`sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production`)

#### Results of GitLab application Check

(For installations with omnibus-gitlab package run and paste the output of:
`sudo gitlab-rake gitlab:check SANITIZE=true`)

(For installations from source run and paste the output of:
`sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production SANITIZE=true`)

(we will only investigate if the tests are passing)

### Possible fixes

(If you can, link to the line of code that might be responsible for the problem)
