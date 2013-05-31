# Contribute to GitLab

This guide details how to use issues and pull requests to improve GitLab.

## Closing policy for issues and pull requests

Issues and pull requests not in line with the guidelines listed in this document will be closed. GitLab is a popular open source project and the capacity to deal with issues and pull requests is limited. To get support for your problems please use other channels as detailed in [the getting help section of the readme](https://github.com/gitlabhq/gitlabhq#getting-help). Professional [support subscriptions](http://www.gitlab.com/subscription/) and [consulting services](http://www.gitlab.com/consultancy/) are available from [GitLab.com](http://www.gitlab.com/).

## Issue tracker

The [issue tracker](https://github.com/gitlabhq/gitlabhq/issues) is only for obvious bugs or misbehavior in the latest [stable or development release of GitLab](MAINTENANCE.md). When submitting an issue please conform to the issue submission guidelines listed below.

Do not use the issue tracker for feature requests. We have a specific [feedback and suggestions forum](http://feedback.gitlab.com) for this purpose.

Please send a pull request with a tested solution or a pull request with a failing test instead of opening an issue if you can. If you're unsure where to post, post to the [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq) or [Stack Overflow](http://stackoverflow.com/questions/tagged/gitlab) first. There are a lot of helpful GitLab users there who may be able to help you quickly. If your particular issue turns out to be a bug, it will find its way from there.

### Issue tracker guidelines

**[Search](https://github.com/gitlabhq/gitlabhq/search?q=&ref=cmdform&type=Issues)** for similar entries before submitting your own, there's a good chance somebody else had the same issue. Show your support with `:+1:` and/or join the discussion. Please submit issues in the following format:

1. **Summary:** Summarize your issue in one sentence (what goes wrong, what did you expect to happen)
2. **Steps to reproduce:** How can we reproduce the issue, preferably on the [GitLab Vagrant virtual machine](https://github.com/gitlabhq/gitlab-vagrant-vm) (start with: `vagrant destroy && vagrant up && vagrant ssh`)
3. **Expected behavior:** Describe your issue in detail
4. **Observed behavior**
5. **Relevant logs and/or screen shots:** Please use code blocks (\`\`\`) to format console output, logs, and code as it's very hard to read otherwise.
6. **Output of checks**
    * Results of GitLab [Application Check](doc/install/installation.md#check-application-status) (`sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production`); we will only investigate if the tests are passing
    * Version of GitLab you are running; we will only investigate issues in the latest stable and development releases as per the [maintenance policy](MAINTENANCE.md)
    * Add the last commit sha1 of the GitLab version you used to replicate the issue (obtainable from the help page)
    * Describe your setup (use relevant parts from `sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production`)
7. **Possible fixes**: If you can, link to the line of code that might be responsible for the problem

## Pull requests

We welcome pull requests with fixes and improvements to GitLab code, tests, and/or documentation. The features we would really like a pull request for are listed with the [status 'accepting merge/pull requests' on our feedback forum](http://feedback.gitlab.com/forums/176466-general/status/796455) but other improvements are also welcome.

### Pull request guidelines

If you can, please submit a pull request with the fix or improvements including tests. If you don't know how to fix the issue but can write a test that exposes the issue we will accept that as well. The workflow to make a pull request is as follows:

1. Fork the project on GitHub
1. Create a feature branch
1. Write [tests](README.md#run-the-tests) and code
1. If you have multiple commits please combine them into one commit by [squashing them](http://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
1. Push the commit to your fork
1. Submit a pull request
2. [Search for issues](https://github.com/gitlabhq/gitlabhq/search?q=&ref=cmdform&type=Issues) related to your pull request and mention them in the pull request description

We will accept pull requests if:

* The code has proper tests and all tests pass (or it is a test exposing a failure in existing code)
* It can be merged without problems (if not please use: `git rebase master`)
* It doesn't break any existing functionality
* It's quality code that conforms to the [Rails style guide](https://github.com/bbatsov/rails-style-guide) and best practices
* The description includes a motive for your change and the method you used to achieve it
* It keeps the GitLab code base clean and well structured
* We think other users will benefit from the same functionality
* If it makes changes to the UI the pull request should include screenshots

For examples of feedback on pull requests please look at already [closed pull requests](https://github.com/gitlabhq/gitlabhq/pulls?direction=desc&page=1&sort=created&state=closed).
