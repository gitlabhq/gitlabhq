# Web hooks

## Add a web hook for **ALL** projects:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"
    # source installations or cookbook
    bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production

## Add a web hook for projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme
    # source installations or cookbook
    bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme RAILS_ENV=production

## Remove a web hook from **ALL** projects using:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"
    # source installations or cookbook
    bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production

## Remove a web hook from projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme
    # source installations or cookbook
    bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme RAILS_ENV=production

## List **ALL** web hooks:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:list
    # source installations or cookbook
    bundle exec rake gitlab:web_hook:list RAILS_ENV=production

## List the web hooks from projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:list NAMESPACE=/
    # source installations or cookbook
    bundle exec rake gitlab:web_hook:list NAMESPACE=/ RAILS_ENV=production

> Note: `/` is the global namespace.
