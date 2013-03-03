# Contribute to GitLab

If you have a question or want to contribute to GitLab this guide show you the appropriate channel to use.

## Ruling out common errors

Some errors are common and it may so happen, that you are not the only one who stumbled over a particular issue. We have [collected several of those and documented quick solutions](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide) for them.

## Support forum

Please visit our [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq) for any kind of question regarding the usage or adiministration/configuration of GitLab.

### Use the support forum if ...

* You get permission denied errors
* You can't see your repos
* You have issues cloning, pulling or pushing
* You have issues with web_hooks not firing

**Search** for similar issues before posting your own, there's a good chance somebody else had the same issue you have now and had it resolved.

## Paid support

Community support in the [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq) is done by volunteers. Paid support is available from [GitLab.com](http://blog.gitlab.com/services/)

## Feature suggestions

Feature suggestions don't belong in issues but can go to [Feedback forum](http://gitlab.uservoice.com/forums/176466-general) where they can be voted on.

## Pull requests

Code speaks louder than words. If you can please submit a pull request with the fix including tests. The workflow to make a pull request is as follows:

1. Fork the project on GitHub
1. Create a feature branch
1. Write tests and code
1. If you have multiple commits please combine them into one commit by [squashing them](http://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
1. Push the commit to your fork
1. Submit a pull request

We will accept pull requests if:

* The code has proper tests and all tests pass
* It can be merged without problems (if not please use: git rebase master)
* It doesn't break any existing functionality
* It's quality code that conforms to the [Rails style guide](https://github.com/bbatsov/rails-style-guide) and best practices
* The description includes a motive for your change and the method you used to achieve it
* It keeps the GitLab code base clean and well structured
* We think other users will need the same functionality
* If it makes changes to the UI the pull request should include screenshots

For examples of feedback on pull requests please look at already [closed pull requests](https://github.com/gitlabhq/gitlabhq/pulls?direction=desc&page=1&sort=created&state=closed).

## Submitting via GitHub's issue tracker

* For obvious bugs or misbehavior in GitLab in the master branch. Please include the revision id and a reproducible test case.
* For problematic or insufficient documentation. Please give a suggestion on how to improve it.

If you're unsure where to post, post it to the [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq) first.
There are a lot of helpful GitLab users there who may be able to help you quickly.
If your particular issue turns out to be a bug, it will find its way from there to the [issue tracker on GitHub](https://github.com/gitlabhq/gitlabhq/issues).

### When submitting an issue

**Search** for similar entries before submitting your own, there's a good chance somebody else had the same issue or idea. Show your support with `:+1:` and/or join the discussion.

Please consider the following points when submitting an **issue**:

* Summarize your issue in one sentence (what happened wrong, when you did/expected something else)
* Describe your issue in detail (including steps to reproduce)
* Add logs or screen shots when possible
* Describe your setup (use relevant parts from `sudo -u gitlab -H bundle exec rake gitlab:env:info`)

## Thank you!

By taking the time to use the right channel, you help the development team to organize and prioritize issues and suggestions in order to make GitLab a better product for us all.
