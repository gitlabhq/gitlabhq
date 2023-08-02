# CsvBuilder

## Usage

Generate a CSV given a collection and a mapping.

```ruby
columns = {
  'Title' => 'title',
  'Comment' => 'comment',
  'Author' => -> (post) { post.author.full_name }
  'Created At (UTC)' => -> (post) { post.created_at&.strftime('%Y-%m-%d %H:%M:%S') }
}

CsvBuilder.new(@posts, columns).render
```

When the value of the mapping is a string, a method is called with the given name
on the record (for example: `post.title`).
When the value of the mapping is a lambda, it is lazily executed.

It's possible to also pass ActiveRecord associations to preload when batching
through the collection:

```ruby
CsvBuilder.new(@posts, columns, [:author, :comments]).render
```

### SingleBatch builder

When the collection is an array or enumerable you can use:

```ruby
CsvBuilder::SingleBatch.new(@posts, columns).render
```

### Stream builder

A stream builder uses a lazy and more efficient iterator and by default returns
up to 100,000 records from the collection.

```ruby
CsvBuilder::Stream.new(@posts, columns).render(1_000)
```

## Development

Follow the GitLab [gems development guidelines](../../doc/development/gems.md).
