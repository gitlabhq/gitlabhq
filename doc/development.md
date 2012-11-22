## Development tips:


### Installation

Install the Gitlab development in a virtual machine with the [Gitlab Vagrant virtual machine](https://github.com/gitlabhq/gitlab-vagrant-vm). Installing it in a virtual machine makes it much easier to set up all the dependencies for integration testing.


### Start application in development mode

#### 1. Via foreman

    bundle exec foreman start -p 3000

#### 2. Manually

    bundle exec rails s
    bundle exec rake environment resque:work QUEUE=* VVERBOSE=1


### Test DB setup & seed

    bundle exec rake db:setup RAILS_ENV=test
    bundle exec rake db:seed_fu RAILS_ENV=test


###  Run the Tests

    # All in one
    bundle exec rake gitlab:test

    # Rspec
    bundle exec rake spec

    # Spinach
    bundle exec rake spinach
