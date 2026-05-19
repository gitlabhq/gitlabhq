# AutoFreeze

Sets the `frozen_string_literal` compile option for your gems.

## Installation

1. In your Gemfile, add this:

```
gem 'auto_freeze'
```

2. Run `bundle install` as normal.

## Usage

Before the `Bundler.require` in your application, configure the gems to be
required with the `frozen_string_literal` compile option set to true.
By default, all gems are required with frozen strings.

```ruby
AutoFreeze.setup!
Bundler.require(*Rails.groups)
```

You can exclude certain gems:

```ruby
exclude_gems = %w[
  arr-pm
  email_reply_trimmer
  method_source
  seed-fu
  unicode_utils
].freeze
AutoFreeze.setup!(excluded_gems: exclude_gems)
Bundler.require(*Rails.groups)
```

To only freeze gems you specify, pass an array into `included_gems` option:

```ruby
AutoFreeze.setup!(included_gems: %w[httpclient])
Bundler.require(*Rails.groups)
```

AutoFreeze will automatically set `frozen_string_literal` compile option to be
`true` when that gem is required by Bundler.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Thanks

Thanks to
<https://evilmartians.com/chronicles/freezolite-the-magic-gem-for-keeping-ruby-literals-safely-frozen>
for the research showing that it was possible to dynamically enable the `frozen_string_literal` option.
