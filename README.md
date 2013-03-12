## GitLab: self hosted Git management software

![logo](https://raw.github.com/gitlabhq/gitlabhq/master/public/gitlab_logo.png)

### GitLab allows you to
 * keep your code secure on your own server
 * manage repositories, users and access permissions
 * communicate through issues, line-comments and wiki pages
 * perform code review with merge requests

### GitLab is

* powered by Ruby on Rails
* completely free and open source (MIT license)
* used by 10.000 organizations to keep their code secure

### Code status

* [![build status](http://ci.gitlab.org/projects/1/status?ref=master)](http://ci.gitlab.org/projects/1?ref=master) ci.gitlab.org (master branch)

* [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://travis-ci.org/gitlabhq/gitlabhq) travis-ci.org (master branch)

* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

* [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq)

* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### Resources

* GitLab.org community site: [Homepage](http://gitlab.org) [Screenshots](http://gitlab.org/screenshots/) [Blog](http://blog.gitlab.org/) [Demo](http://demo.gitlabhq.com/users/sign_in)

* GitLab.com: [Homepage](http://blog.gitlab.com/) [Hosted pricing](http://blog.gitlab.com/pricing/) [Services](http://blog.gitlab.com/services/) [Blog](http://blog.gitlab.com/blog/)

* GitLab CI: [Readme](https://github.com/gitlabhq/gitlab-ci/blob/master/README.md) of the GitLab open-source continuous integration server

### Requirements

* Ubuntu/Debian**
* ruby 1.9.3
* MySQL
* git
* gitlab-shell
* redis

** More details are in the [requirements doc](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/requirements.md)

### Installation

#### For production

Follow the installation guide for production server.

* [Installation guide for latest stable release (4.2)](https://github.com/gitlabhq/gitlabhq/blob/4-2-stable/doc/install/installation.md) - **Recommended**

* [Installation guide for the current master branch (5.0)](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md)


#### For development

If you want to contribute, please first read our [Contributing Guidelines](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md) and then we suggest you to use the Vagrant virtual machine project to get an environment working sandboxed and with all dependencies.

* [Vagrant virtual machine](https://github.com/gitlabhq/gitlab-vagrant-vm)

### Starting

1. The Installation guide contains instructions to download an init script and run that on boot. With the init script you can also start GitLab

        sudo service gitlab start

  or

        sudo /etc/init.d/gitlab restart

2. Start it with [Foreman](https://github.com/ddollar/foreman) in development mode

        bundle exec foreman start -p 3000

 or start it manually

        bundle exec rails s
        bundle exec rake sidekiq:start

### Running the tests

* Seed the database

        bundle exec rake db:setup RAILS_ENV=test
        bundle exec rake db:seed_fu RAILS_ENV=test

* Run all tests

        bundle exec rake gitlab:test

* Rspec unit and functional tests

        bundle exec rake spec

* Spinach integration tests

        bundle exec rake spinach

### Getting help

* [Troubleshooting guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)

* [Support forum](https://groups.google.com/forum/#!forum/gitlabhq)

* [Feedback and suggestions forum](http://gitlab.uservoice.com/forums/176466-general)

* [Paid support](http://blog.gitlab.com/support/)

* [Paid services](http://blog.gitlab.com/services/)

### New versions and the API

Each month on the 22th a new version is released together with an upgrade guide.

* [Upgrade guides](https://github.com/gitlabhq/gitlabhq/wiki)

* [Roadmap](https://github.com/gitlabhq/gitlabhq/blob/master/ROADMAP.md)

### Other documentation

* [GitLab API](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/README.md)

* [Rake tasks](https://github.com/gitlabhq/gitlabhq/tree/master/doc/raketasks)

* [GitLab recipes](https://github.com/gitlabhq/gitlab-recipes)

### Getting in touch

* [Contributing guide](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md)

* [Core team](https://github.com/gitlabhq?tab=members)

* [Contributors](https://github.com/gitlabhq/gitlabhq/graphs/contributors)

* [Leader](https://github.com/randx)

* [Contact page](http://gitlab.org/contact/)
