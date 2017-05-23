Please read this!

Before opening a new issue, make sure to search for keywords in the issues
filtered by the "regression" or "bug" label:

- https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name%5B%5D=regression
- https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name%5B%5D=bug

and verify the issue you're about to submit isn't a duplicate.

Please remove this notice if you're confident your issue isn't a duplicate.

------

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

<details>
<summary>Expand for output related to GitLab environment info</summary>
<pre>

(For installations with omnibus-gitlab package run and paste the output of:
`sudo gitlab-rake gitlab:env:info`)

(For installations from source run and paste the output of:
`sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production`)

</pre>
</details>

#### Results of GitLab application Check

<details>
<summary>Expand for output related to the GitLab application check</summary>
<pre>

(For installations with omnibus-gitlab package run and paste the output of:
`sudo gitlab-rake gitlab:check SANITIZE=true`)

(For installations from source run and paste the output of:
`sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production SANITIZE=true`)

(we will only investigate if the tests are passing)

</pre>
</details>

### Possible fixes

(If you can, link to the line of code that might be responsible for the problem)

/label ~bug
