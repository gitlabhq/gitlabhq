---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
source: /doc/user/search/exact_code_search.md
---

# Syntax options

| Query                | Regular expression mode                                 | Exact match mode               |
| -------------------- | ------------------------------------------------------- | ------------------------------ |
| `"foo"`              | `foo`                                                   | `"foo"`                        |
| `foo file:^doc/`     | `foo` in directories that start with `/doc`             | `foo` in directories that start with `/doc` |
| `"class foo"`        | `class foo`                                             | `"class foo"`                  |
| `class foo`          | `class` and `foo`                                       | `class foo`                    |
| `foo or bar`         | `foo` or `bar`                                          | `foo or bar`                   |
| `class Foo`          | `class` (case insensitive) and `Foo` (case sensitive)   | `class Foo` (case insensitive) |
| `class Foo case:yes` | `class` and `Foo` (both case sensitive)                 | `class Foo` (case sensitive)   |
| `foo -bar`           | `foo` but not `bar`                                     | `foo -bar`                     |
| `foo file:js`        | `foo` in files with names that contain `js`             | `foo` in files with names that contain `js` |
| `foo -file:test`     | `foo` in files with names that do not contain `test`    | `foo` in files with names that do not contain `test` |
| `foo lang:ruby`      | `foo` in Ruby source code                               | `foo` in Ruby source code      |
| `foo file:\.js$`     | `foo` in files with names that end with `.js`           | `foo` in files with names that end with `.js` |
| `foo.*bar`           | `foo.*bar` (regular expression)                         | None                           |
| `sym:foo`            | `foo` in symbols like class, method, and variable names | `foo` in symbols like class, method, and variable names |
