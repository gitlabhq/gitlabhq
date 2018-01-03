# Gotchas

The purpose of this guide is to document potential "gotchas" that contributors
might encounter or should avoid during development of GitLab CE and EE.

## Do not assert against the absolute value of a sequence-generated attribute

Consider the following factory:

```ruby
FactoryBot.define do
  factory :label do
    sequence(:title) { |n| "label#{n}" }
  end
end
```

Consider the following API spec:

```ruby
require 'rails_helper'

describe API::Labels do
  it 'creates a first label' do
    create(:label)

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_http_status(200)
    expect(json_response.first['name']).to eq('label1')
  end

  it 'creates a second label' do
    create(:label)

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_http_status(200)
    expect(json_response.first['name']).to eq('label1')
  end
end
```

When run, this spec doesn't do what we might expect:

```sh
1) API::API reproduce sequence issue creates a second label
   Failure/Error: expect(json_response.first['name']).to eq('label1')

     expected: "label1"
          got: "label2"

     (compared using ==)
```

That's because FactoryBot sequences are not reseted for each example.

Please remember that sequence-generated values exist only to avoid having to
explicitly set attributes that have a uniqueness constraint when using a factory.

### Solution

If you assert against a sequence-generated attribute's value, you should set it
explicitly. Also, the value you set shouldn't match the sequence pattern.

For instance, using our `:label` factory, writing `create(:label, title: 'foo')`
is ok, but `create(:label, title: 'label1')` is not.

Following is the fixed API spec:

```ruby
require 'rails_helper'

describe API::Labels do
  it 'creates a first label' do
    create(:label, title: 'foo')

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_http_status(200)
    expect(json_response.first['name']).to eq('foo')
  end

  it 'creates a second label' do
    create(:label, title: 'bar')

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_http_status(200)
    expect(json_response.first['name']).to eq('bar')
  end
end
```

## Do not `rescue Exception`

See ["Why is it bad style to `rescue Exception => e` in Ruby?"][Exception].

_**Note:** This rule is [enforced automatically by
Rubocop](https://gitlab.com/gitlab-org/gitlab-ce/blob/8-4-stable/.rubocop.yml#L911-914)._

[Exception]: http://stackoverflow.com/q/10048173/223897

## Do not use inline JavaScript in views

Using the inline `:javascript` Haml filters comes with a
performance overhead. Using inline JavaScript is not a good way to structure your code and should be avoided.

_**Note:** We've [removed these two filters](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/initializers/hamlit.rb)
in an initializer._

### Further reading

- Stack Overflow: [Why you should not write inline JavaScript](http://programmers.stackexchange.com/questions/86589/why-should-i-avoid-inline-scripting)
