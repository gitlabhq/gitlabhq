# Gotchas

The purpose of this guide is to document potential "gotchas" that contributors
might encounter or should avoid during development of GitLab CE and EE.

## Don't `describe` symbols

Consider the following model spec:

```ruby
require 'rails_helper'

describe User do
  describe :to_param do
    it 'converts the username to a param' do
      user = described_class.new(username: 'John Smith')

      expect(user.to_param).to eq 'john-smith'
    end
  end
end
```

When run, this spec doesn't do what we might expect:

```sh
spec/models/user_spec.rb|6 error|  Failure/Error: u = described_class.new NoMethodError: undefined method `new' for :to_param:Symbol
```

### Solution

Except for the top-level `describe` block, always provide a String argument to
`describe`.

## Don't assert against the absolute value of a sequence-generated attribute

Consider the following factory:

```ruby
FactoryGirl.define do
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

That's because FactoryGirl sequences are not reseted for each example.

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

## Don't `rescue Exception`

See ["Why is it bad style to `rescue Exception => e` in Ruby?"][Exception].

_**Note:** This rule is [enforced automatically by
Rubocop](https://gitlab.com/gitlab-org/gitlab-ce/blob/8-4-stable/.rubocop.yml#L911-914)._

[Exception]: http://stackoverflow.com/q/10048173/223897

## Don't use inline JavaScript in views

Using the inline `:javascript` Haml filters comes with a
performance overhead. Using inline JavaScript is not a good way to structure your code and should be avoided.

_**Note:** We've [removed these two filters](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/initializers/hamlit.rb)
in an initializer._

### Further reading

- Stack Overflow: [Why you should not write inline JavaScript](http://programmers.stackexchange.com/questions/86589/why-should-i-avoid-inline-scripting)

## ID-based CSS selectors need to be a bit more specific

Normally, because HTML `id` attributes need to be unique to the page, it's
perfectly fine to write some JavaScript like the following:

```javascript
$('#js-my-selector').hide();
```

However, there's a feature of GitLab's Markdown processing that [automatically
adds anchors to header elements][ToC Processing], with the `id` attribute being
automatically generated based on the content of the header.

Unfortunately, this feature makes it possible for user-generated content to
create a header element with the same `id` attribute we're using in our
selector, potentially breaking the JavaScript behavior. A user could break the
above example with the following Markdown:

```markdown
## JS My Selector
```

Which gets converted to the following HTML:

```html
<h2>
  <a id="js-my-selector" class="anchor" href="#js-my-selector" aria-hidden="true"></a>
  JS My Selector
</h2>
```

[ToC Processing]: https://gitlab.com/gitlab-org/gitlab-ce/blob/8-4-stable/lib/banzai/filter/table_of_contents_filter.rb#L31-37

### Solution

The current recommended fix for this is to make our selectors slightly more
specific:

```javascript
$('div#js-my-selector').hide();
```

### Further reading

- Issue: [Merge request ToC anchor conflicts with tabs](https://gitlab.com/gitlab-org/gitlab-ce/issues/3908)
- Merge Request: [Make tab target selectors less naive](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2023)
- Merge Request: [Make cross-project reference's clipboard target less naive](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2024)
