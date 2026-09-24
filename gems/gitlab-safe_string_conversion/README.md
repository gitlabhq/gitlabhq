# Gitlab::SafeStringConversion

Monkey-patches `String#to_i`, `String#to_r`, `String#to_c` and `Kernel#Integer`, `Kernel#Rational`, `Kernel#Complex` to raise `Gitlab::SafeStringConversion::ConversionError` when converting a string larger than the configured threshold to a number. This prevents algorithmic-complexity denial-of-service attacks from oversized numeric strings.

The gem auto-patches on load: since it is declared in the Gemfile without an explicit `require:` option, Bundler's default require behavior activates it at application boot.

## Usage

Configure the maximum string size before conversion:

```ruby
Gitlab::SafeStringConversion.max_string_size = 5000
```

The default is 4300. Attempting to convert a larger string raises `ConversionError`:

```ruby
("1" * 4301).to_i
# raises Gitlab::SafeStringConversion::ConversionError
```

To temporarily bypass the check within a block:

```ruby
Gitlab::SafeStringConversion.disable_safety do
  # Conversions here skip the size check
  ("1" * 10000).to_i # succeeds
end

# Back outside the block, the check is active again
("1" * 4301).to_i # raises ConversionError
```

`disable_safety` is thread-local: it only affects the thread that called it, so other concurrently running threads keep enforcing the size limit.

## Development

Follow the GitLab [gems development guidelines](../../doc/development/gems.md).
