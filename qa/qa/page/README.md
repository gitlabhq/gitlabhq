# Page objects in GitLab QA

In GitLab QA we are using a known pattern, called _Page Objects_.

This means that we have built an abstraction for all GitLab pages that we use
to drive GitLab QA scenarios. Whenever we do something on a page, like filling
in a form, or clicking a button, we do that only through a page object
associated with this area of GitLab.

For example, when GitLab QA test harness signs in into GitLab, it needs to fill
in a user login and user password. In order to do that, we have a class, called
`Page::Main::Login` and `sign_in_using_credentials` methods, that is the only
piece of the code, that has knowledge about `user_login` and `user_password`
fields.

## Why do we need that?

We need page objects, because we need to reduce duplication and avoid problems
whenever someone changes some selectors in GitLab's source code.

Imagine that we have a hundred specs in GitLab QA, and we need to sign into
GitLab each time, before we make assertions. Without a page object one would
need to rely on volatile helpers or invoke Capybara methods directly. Imagine
invoking `fill_in :user_login` in every `*_spec.rb` file / test example.

When someone later changes `t.text_field :login` in the view associated with
this page to `t.text_field :username` it will generate a different field
identifier, what would effectively break all tests.

Because we are using `Page::Main::Login.act { sign_in_using_credentials }`
everywhere, when we want to sign into GitLab, the page object is the single
source of truth, and we will need to update `fill_in :user_login`
to `fill_in :user_username` only in a one place.

## What problems did we have in the past?

We do not run QA tests for every commit, because of performance reasons, and
the time it would take to build packages and test everything.

That is why when someone changes `t.text_field :login` to
`t.text_field :username` in the _new session_ view we won't know about this
change until our GitLab QA nightly pipeline fails, or until someone triggers
`package-and-qa` action in their merge request.

Obviously such a change would break all tests. We call this problem a _fragile
tests problem_.

In order to make GitLab QA more reliable and robust, we had to solve this
problem by introducing coupling between GitLab CE / EE views and GitLab QA.

## How did we solve fragile tests problem?

Currently, when you add a new `Page::Base` derived class, you will also need to
define all selectors that your page objects depends on.

Whenever you push your code to CE / EE repository, `qa:selectors` sanity test
job is going to be run as a part of a CI pipeline.

This test is going to validate all page objects that we have implemented in
`qa/page` directory. When it fails, you will be notified about missing
or invalid views / selectors definition.

## How to properly implement a page object?

We have built a DSL to define coupling between a page object and GitLab views
it is actually implemented by. See an example below.

```ruby
module Page
  module Main
    class Login < Page::Base
      view 'app/views/devise/passwords/edit.html.haml' do
        element :password_field, 'password_field :password'
        element :password_confirmation, 'password_field :password_confirmation'
        element :change_password_button, 'submit "Change your password"'
      end

      view 'app/views/devise/sessions/_new_base.html.haml' do
        element :login_field, 'text_field :login'
        element :password_field, 'password_field :password'
        element :sign_in_button, 'submit "Sign in"'
      end

      # ...
  end
end
```

It is possible to use `element` DSL method without value, with a String value
or with a Regexp.

```ruby
view 'app/views/my/view.html.haml' do
  # Require `f.submit "Sign in"` to be present in `my/view.html.haml
  element :my_button, 'f.submit "Sign in"'

  # Match every line in `my/view.html.haml` against
  # `/link_to .* "My Profile"/` regexp.
  element :profile_link, /link_to .* "My Profile"/

  # Implicitly require `.qa-logout-button` CSS class to be present in the view
  element :logout_button
end
```

## Running the test locally

During development, you can run the `qa:selectors` test by running

```shell
bin/qa Test::Sanity::Selectors
```

from within the `qa` directory.

## Where to ask for help?

If you need more information, ask for help on `#qa` channel on Slack (GitLab
Team only).

If you are not a Team Member, and you still need help to contribute, please
open an issue in GitLab QA issue tracker.
