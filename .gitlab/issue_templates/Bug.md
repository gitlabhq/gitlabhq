<!---
Please read this!

Before opening a new issue, make sure to search for keywords in the issues
filtered by the "regression" or "type::bug" label:

- https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=regression
- https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=type::bug

and verify the issue you're about to submit isn't a duplicate.
--->

### Summary

<!-- Summarize the bug encountered concisely. -->

### Steps to reproduce

<!-- Describe how one can reproduce the issue - this is very important. Please use an ordered list. -->

### Example Project

<!-- If possible, please create an example project here on GitLab.com that exhibits the problematic 
behavior, and link to it here in the bug report. If you are using an older version of GitLab, this 
will also determine whether the bug is fixed in a more recent version. -->

### What is the current *bug* behavior?

<!-- Describe what actually happens. -->

### What is the expected *correct* behavior?

<!-- Describe what you should see instead. -->

### Relevant logs and/or screenshots

<!-- Paste any relevant logs - please use code blocks (```) to format console output, logs, and code
 as it's tough to read otherwise. -->

### Output of checks

<!-- If you are reporting a bug on GitLab.com, uncomment below -->

<!-- This bug happens on GitLab.com -->

<!-- and uncomment below if you have /label privileges -->
<!-- /label ~"reproduced on GitLab.com" -->
<!-- or follow up with an issue comment of `@gitlab-bot label ~"reproduced on GitLab.com"` if you do not -->

#### Results of GitLab environment info

<!--  Input any relevant GitLab environment information if needed. -->

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

<!--  Input any relevant GitLab application check information if needed. -->

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

<!-- If you can, link to the line of code that might be responsible for the problem. -->

/label ~"type::bug"
<!-- If you don't have /label privileges, follow up with an issue comment of `@gitlab-bot label ~"type::bug"` -->

