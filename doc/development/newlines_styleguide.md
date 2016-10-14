# Newlines styleguide

This style guide recommends best practices for newlines in Ruby code.

## Rule: separate code with newlines only to group together related logic

```ruby
# bad
def method
  issue = Issue.new

  issue.save
  
  render json: issue 
end
```

```ruby
# good
def method
  issue = Issue.new
  issue.save
  
  render json: issue 
end
```

## Rule: separate code and block with newlines

### Newline before block

```ruby
# bad
def method
  issue = Issue.new
  if issue.save
    render json: issue
  end
end
```

```ruby
# good
def method
  issue = Issue.new

  if issue.save
    render json: issue
  end
end
```

## Newline after block

```ruby
# bad
def method
  if issue.save
    issue.send_email
  end
  render json: issue
end
```

```ruby
# good
def method
  if issue.save
    issue.send_email
  end

  render json: issue
end
```

### Exception: no need for newline when code block starts or ends right inside another code block

```ruby
# bad
def method

  if issue

    if issue.valid?
      issue.save
    end

  end

end
```

```ruby
# good
def method
  if issue
    if issue.valid?
      issue.save
    end
  end
end
```
