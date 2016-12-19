#!/bin/bash

set -xe

# rsync --delete -av config/{routes.rb,routes,initializers,application.rb} zj-gitlab:/opt/gitlab/embedded/service/gitlab-rails/config/
rsync --delete -av lib/mattermost zj-gitlab:/opt/gitlab/embedded/service/gitlab-rails/lib
# rsync --delete -av vendor/{assets,gitignore,gitlab-ci-yml} zj-gitlab:/opt/gitlab/embedded/service/gitlab-rails/vendor/
# rsync --delete -av ../gitlab-shell/{bin,lib,spec,hooks} zj-gitlab:/opt/gitlab/embedded/service/gitlab-shell
#ssh gitlab-test 'cd /opt/gitlab/embedded/service/gitlab-rails && /opt/gitlab/embedded/bin/bundle install --deployment'
#ssh gitlab-test 'export NO_PRIVILEGE_DROP=true; export USE_DB=false; gitlab-rake assets:precompile'
ssh zj-gitlab gitlab-ctl restart
