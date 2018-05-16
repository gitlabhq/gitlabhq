# Webhooks

## Add a webhook for **ALL** projects:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"
    # source installations
    bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production

## Add a webhook for projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme
    # source installations
    bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme RAILS_ENV=production

## Remove a webhook from **ALL** projects using:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"
    # source installations
    bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production

## Remove a webhook from projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme
    # source installations
    bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme RAILS_ENV=production

## List **ALL** webhooks:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:list
    # source installations
    bundle exec rake gitlab:web_hook:list RAILS_ENV=production

## List the webhooks from projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:list NAMESPACE=/
    # source installations
    bundle exec rake gitlab:web_hook:list NAMESPACE=/ RAILS_ENV=production

> Note: `/` is the global namespace.
