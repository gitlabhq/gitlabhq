---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Flows in GitLab QA
---

Flows are frequently used sequences of actions. They are a higher level
of abstraction than page objects. Flows can include multiple page objects,
or any other relevant code.

For example, the sign in flow encapsulates two steps that are included
in every browser UI test.

```ruby
# QA::Flow::Login

def sign_in(as: nil)
  Runtime::Browser.visit(:gitlab, Page::Main::Login)
  Page::Main::Login.perform { |login| login.sign_in_using_credentials(user: as) }
end

# When used in a test

it 'performs a test after signing in as the default user' do
  Flow::Login.sign_in

  # Perform the test
end
```

`QA::Flow::Login` provides an even more useful flow, allowing a test to easily switch users.

```ruby
# QA::Flow::Login

def while_signed_in(as: nil)
  Page::Main::Menu.perform(&:sign_out_if_signed_in)

  sign_in(as: as)

  yield

  Page::Main::Menu.perform(&:sign_out)
end

# When used in a test

it 'performs a test as one user and verifies as another' do
  user1 = create(:user)
  user2 = create(:user)

  Flow::Login.while_signed_in(as: user1) do
    # Perform some setup as user1
  end

  Flow::Login.sign_in(as: user2)

  # Perform the rest of the test as user2
end
```
