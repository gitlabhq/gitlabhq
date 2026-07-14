# safe_zip

Provides a safe interface to extract specific directories or files within a `zip` archive,
preventing path traversal attacks (symlink escapes, `../` tricks, absolute paths).

## Usage

```ruby
require "safe_zip"

# Extract a directory
SafeZip::Extract.new("/path/to/archive.zip").extract(directories: ["public/"], to: "/dest")

# Extract specific files
SafeZip::Extract.new("/path/to/archive.zip").extract(files: ["index.html"], to: "/dest")
```

Raises subclasses of `SafeZip::Extract::Error` on path traversal attempts or missing entries.
