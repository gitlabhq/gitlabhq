## GitLab: self hosted Git management software

![logo](https://raw.github.com/gitlabhq/gitlabhq/master/public/gitlab_logo.png)

![animated-screenshots](https://gist.github.com/fnkr/2f9badd56bfe0ed04ee7/raw/4f48806fbae97f556c2f78d8c2d299c04500cb0d/compiled.gif)

### GitLab allows you to
 * keep your code secure on your own server
 * manage repositories, users and access permissions
 * communicate through issues, line-comments and wiki pages
 * perform code review with merge requests

### GitLab is

* powered by Ruby on Rails
* completely free and open source (MIT license)
* used by more than 10.000 organizations to keep their code secure

### Code status

* [![build status](http://ci.gitlab.org/projects/1/status.png?ref=master)](http://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

* [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://travis-ci.org/gitlabhq/gitlabhq) on travis-ci.org (master branch)

* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

* [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq) this button can be yellow (small updates are available) but must not be red (a security fix or an important update is available), gems are updated in major releases of GitLab.

* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### Resources

* GitLab.org community site: [Homepage](http://gitlab.org) | [Screenshots](http://gitlab.org/screenshots/) | [Blog](http://blog.gitlab.org/) | [Demo](http://demo.gitlabhq.com/users/sign_in)

* GitLab.com commercial services: [Homepage](http://www.gitlab.com/) | [Subscription](http://www.gitlab.com/subscription/) | [Consultancy](http://www.gitlab.com/consultancy/) | [GitLab Cloud](http://www.gitlab.com/cloud/) | [Blog](http://blog.gitlab.com/)

* GitLab CI: [Readme](https://github.com/gitlabhq/gitlab-ci/blob/master/README.md) of the GitLab open-source continuous integration server

### Requirements

* Ubuntu/Debian**
* ruby 1.9.3
* MySQL or PostgreSQL
* git
* gitlab-shell
* redis

** More details are in the [requirements doc](doc/install/requirements.md)

### Installation

#### Official production installation

* [Installation guide for a production server](doc/install/installation.md)


#### Official development installation

If you want to contribute, please first read our [Contributing Guidelines](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md) and then we suggest you to use the Vagrant virtual machine project to get an environment working with all dependencies.

* [Vagrant virtual machine for development](https://github.com/gitlabhq/gitlab-vagrant-vm)


#### Unofficial production installations

* [GitLab recipes](https://github.com/gitlabhq/gitlab-recipes) repository with unofficial guides for using GitLab with different software (operating systems, webservers, etc.) than the official version.

* [Installation guides](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Unofficial-Installation-Guides) public wiki with unofficial guides to install GitLab on different operating systems.

* [BitNami one-click installers](http://bitnami.com/stack/gitlab)

* [TurnKey Linux virtual appliance](http://www.turnkeylinux.org/gitlab)


### New versions and upgrading

Since 2011 GitLab is released on the 22nd of every month. Every new release includes an upgrade guide.

* [Upgrade guides](doc/update)

* [Changelog](CHANGELOG)

* Features that will be in the next releases are listed on [the feedback and suggestions forum](http://feedback.gitlab.com/forums/176466-general) with the status ["started"](http://feedback.gitlab.com/forums/176466-general/status/796456) and [completed](http://feedback.gitlab.com/forums/176466-general/status/796457).


### Run in production mode

The Installation guide contains instructions on how to download an init script and run it automatically on boot. You can also start the init script manually:

    sudo service gitlab start

or by directly calling the script

     sudo /etc/init.d/gitlab start

### Run in development mode

Start it with [Foreman](https://github.com/ddollar/foreman)

    bundle exec foreman start -p 3000

or start each component separately

    bundle exec rails s
    bundle exec rake sidekiq:start

### Run the tests

* Seed the database

        bundle exec rake db:setup RAILS_ENV=test
        bundle exec rake db:seed_fu RAILS_ENV=test

* Run all tests

        bundle exec rake gitlab:test

* [RSpec](http://rspec.info/) unit and functional tests

        All RSpec tests: bundle exec rake spec

        Single RSpec file: bundle exec rspec spec/controllers/commit_controller_spec.rb

* [Spinach](https://github.com/codegram/spinach) integration tests

        All Spinach tests: bundle exec rake spinach

        Single Spinach test: bundle exec spinach features/project/issues/milestones.feature


### GitLab interfaces

* [GitLab API](doc/api/README.md)

* [Rake tasks](doc/raketasks)

* [Directory structure](doc/install/structure.md)

* [Databases](doc/install/databases.md)


### Getting help

* [Maintenance policy](MAINTENANCE.md) specifies what versions are supported.

* [Troubleshooting guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide) contains solutions to common problems.

* [Mailing list](https://groups.google.com/forum/#!forum/gitlabhq) and [Stack Overflow](http://stackoverflow.com/questions/tagged/gitlab) are the best places to ask questions. For example you can use it if you have questions about: permission denied errors, invisible repos, can't clone/pull/push or with web hooks that don't fire. Please search for similar issues before posting your own, there's a good chance somebody else had the same issue you have now and has resolved it. There are a lot of helpful GitLab users there who may be able to help you quickly. If your particular issue turns out to be a bug, it will find its way from there to a fix.

* [Unofficial #gitlab IRC on Freenode](http://www.freenode.net/) is another way to get in touch with other GitLab users who may be able to help you.

* [Feedback and suggestions forum](http://feedback.gitlab.com) is the place to propose and discuss new features for GitLab.

* [Contributing guide](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md) describes how to submit pull requests and issues. Pull requests and issues not in line with the guidelines in this document will be closed.

* [Support subscription](http://www.gitlab.com/subscription/) connects you to the knowledge of GitLab experts that will resolve your issues and answer your questions.

* [Consultancy](http://www.gitlab.com/consultancy/) allows you hire GitLab experts for installations, upgrades and customizations.


### Getting in touch

* [Core team](https://github.com/gitlabhq?tab=members)

* [Contributors](https://github.com/gitlabhq/gitlabhq/graphs/contributors)

* [Leader](https://github.com/randx)

* [Contact page](http://gitlab.org/contact/)
