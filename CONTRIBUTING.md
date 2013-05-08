# Contribute to GitLab

This guide details how to use issues and pull requests to improve GitLab.

## Closing policy for issues and pull requests

Issues and pull requests not in line with the guidelines listed in this document will be closed with just a link to this paragraph. GitLab is a popular open source project and the capacity to deal with issues and pull requests is limited. To get support for your problems please use other channels as detailed in [the getting help section of the readme](https://github.com/gitlabhq/gitlabhq#getting-help). Professional [support subscriptions](http://www.gitlab.com/subscription/) and [consulting services](http://www.gitlab.com/consultancy/) are available from [GitLab.com](http://www.gitlab.com/).

## Issue tracker

The [issue tracker](https://github.com/gitlabhq/gitlabhq/issues) is only for obvious bugs or misbehavior in the master branch of GitLab. When submitting an issue please conform to the issue submission guidelines listed below.

Do not use the issue tracker for feature requests. We have a specific
[Feedback and suggestions forum](http://feedback.gitlab.com) for this purpose.

Please send a pull request with a tested solution or a pull request with a failing test instead of opening an issue if you can. If you're unsure where to post, post to the [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq) first. There are a lot of helpful GitLab users there who may be able to help you quickly. If your particular issue turns out to be a bug, it will find its way from there.

### Issue tracker guidelines

**[Search](https://github.com/gitlabhq/gitlabhq/search?q=&ref=cmdform&type=Issues)** for similar entries before submitting your own, there's a good chance somebody else had the same issue or idea. Show your support with `:+1:` and/or join the discussion.

* Only report issues for supported versions according to the [maintenance policy](MAINTENANCE.md)
* Summarize your issue in one sentence (what goes wrong, what did you expect to happen)
* Describe your issue in detail
* How can we reproduce the issue on the [GitLab Vagrant virtual machine](https://github.com/gitlabhq/gitlab-vagrant-vm) (start with: `vagrant destroy && vagrant up && vagrant ssh`)
* Add the last commit sha1 of the GitLab version you used to replicate the issue
* Add logs or screen shots when possible
* Link to the line of code that might be responsible for the problem
* Describe your setup (use relevant parts from `sudo -u gitlab -H bundle exec rake gitlab:env:info`)

## Pull requests

We welcome pull request with improvements to GitLab code and/or documentation. The issues we would really like a pull request for are listed with the [status 'accepting merge/pull requests' on our feedback forum](http://feedback.gitlab.com/forums/176466-general/status/796455) but other improvements are also welcome.

### Pull request guidelines

 If you can please submit a pull request with the fix including tests. The workflow to make a pull request is as follows:

1. Fork the project on GitHub
1. Create a feature branch
1. Write [tests](README.md#run-the-tests) and code
1. If you have multiple commits please combine them into one commit by [squashing them](http://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
1. Push the commit to your fork
1. Submit a pull request
2. [Search for issues](https://github.com/gitlabhq/gitlabhq/search?q=&ref=cmdform&type=Issues) related to your pull request and mention them in the pull request comments

We will accept pull requests if:

* The code has proper tests and all tests pass
* It can be merged without problems (if not please use: `git rebase master`)
* It doesn't break any existing functionality
* It's quality code that conforms to the [Rails style guide](https://github.com/bbatsov/rails-style-guide) and best practices
* The description includes a motive for your change and the method you used to achieve it
* It keeps the GitLab code base clean and well structured
* We think other users will need the same functionality
* If it makes changes to the UI the pull request should include screenshots

For examples of feedback on pull requests please look at already [closed pull requests](https://github.com/gitlabhq/gitlabhq/pulls?direction=desc&page=1&sort=created&state=closed).
