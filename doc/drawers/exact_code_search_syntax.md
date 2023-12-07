---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
source: /doc/user/search/exact_code_search.md
---

# Search tips

| Query                | Description                                                                           |
| -------------------- |-------------------------------------------------------------------------------------- |
| `foo`                | Returns files that contain `foo`                                                      |
| `"class foo"`        | Returns files that contain the exact string `class foo`                               |
| `class foo`          | Returns files that contain both `class` and `foo`                                     |
| `foo or bar`         | Returns files that contain either `foo` or `bar`                                      |
| `class Foo`          | Returns files that contain `class` (case insensitive) and `Foo` (case sensitive)      |
| `class Foo case:yes` | Returns files that contain `class` and `Foo` (both case sensitive)                    |
| `foo -bar`           | Returns files that contain `foo` but not `bar`                                        |
| `foo file:js`        | Searches for `foo` in files with names that contain `js`                              |
| `foo -file:test`     | Searches for `foo` in files with names that do not contain `test`                     |
| `foo lang:ruby`      | Searches for `foo` in Ruby source code                                                |
| `foo f:\.js$`        | Searches for `foo` in files with names that end with `.js`                            |
| `foo.*bar`           | Searches for strings that match the regular expression `foo.*bar`                     |
