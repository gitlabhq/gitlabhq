# Style guides

1. [Ruby](https://github.com/rubocop-hq/ruby-style-guide).
   Important sections include [Source Code Layout][rss-source] and
   [Naming][rss-naming]. Use:
   - multi-line method chaining style **Option A**: dot `.` on the second line
   - string literal quoting style **Option A**: single quoted by default
1. [Rails](https://github.com/rubocop-hq/rails-style-guide)
1. [Newlines styleguide][newlines-styleguide]
1. [Testing][testing]
1. [JavaScript styleguide][js-styleguide]
1. [SCSS styleguide][scss-styleguide]
1. [Shell commands (Ruby)](../shell_commands.md) created by GitLab
   contributors to enhance security
1. [Database Migrations](../migration_style_guide.md)
1. [Markdown](https://cirosantilli.com/markdown-style-guide/)
1. [Documentation styleguide](../documentation/styleguide.md)
1. Interface text should be written subjectively instead of objectively. It
   should be the GitLab core team addressing a person. It should be written in
   present time and never use past tense (has been/was). For example instead
   of _prohibited this user from being saved due to the following errors:_ the
   text should be _sorry, we could not create your account because:_
1. Code should be written in [US English][us-english]
1. [Go](../go_guide/index.md)
1. [Python](../python_guide/index.md)
1. [Shell scripting](../shell_scripting_guide/index.md)

## Checking the style and other issues

This is also the style used by linting tools such as
[RuboCop](https://github.com/rubocop-hq/rubocop) and [Hound CI](https://houndci.com).
You can run RuboCop by hand or install a tool like [Overcommit](https://github.com/sds/overcommit) to run it for you.
Overcommit will automatically run the configured checks (like Rubocop) on every modified file before commit. You can use the example overcommit configuration found in `.overcommit.yml.example` as a quickstart.
This saves you time as you don't have to wait for the same errors to be detected by the CI.

---

[Return to Contributing documentation](index.md)

[rss-source]: https://github.com/rubocop-hq/ruby-style-guide/blob/master/README.adoc#source-code-layout
[rss-naming]: https://github.com/rubocop-hq/ruby-style-guide/blob/master/README.adoc#naming-conventions
[doc-guidelines]: ../documentation/index.md "Documentation guidelines"
[js-styleguide]: ../fe_guide/style/javascript.md "JavaScript styleguide"
[scss-styleguide]: ../fe_guide/style/scss.md "SCSS styleguide"
[newlines-styleguide]: ../newlines_styleguide.md "Newlines styleguide"
[testing]: ../testing_guide/index.md
[us-english]: https://en.wikipedia.org/wiki/American_English
