---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Syntax Highlighting **(FREE)**

GitLab provides syntax highlighting on all files through the [Rouge](https://rubygems.org/gems/rouge) Ruby gem. It attempts to guess what language to use based on the file extension, which most of the time is sufficient.

NOTE:
The [Web IDE](web_ide/index.md) and [Snippets](../snippets.md) use [Monaco Editor](https://microsoft.github.io/monaco-editor/)
for text editing, which internally uses the [Monarch](https://microsoft.github.io/monaco-editor/monarch.html)
library for syntax highlighting.

If GitLab is guessing wrong, you can override its choice of language using the
`gitlab-language` attribute in `.gitattributes`. For example, if you are working in a
<!-- vale gitlab.Spelling = NO --> Prolog <!-- vale gitlab.Spelling = YES -->
project and using the `.pl` file extension (which would normally be highlighted as Perl),
you can add the following to your `.gitattributes` file:

``` conf
*.pl gitlab-language=prolog
```

<!-- vale gitlab.Spelling = NO -->
When you check in and push that change, all `*.pl` files in your project are highlighted as Prolog.
<!-- vale gitlab.Spelling = YES -->

The paths here are Git's built-in [`.gitattributes` interface](https://git-scm.com/docs/gitattributes). So, if you were to invent a file format called a `Nicefile` at the root of your project that used Ruby syntax, all you need is:

``` conf
/Nicefile gitlab-language=ruby
```

To disable highlighting entirely, use `gitlab-language=text`. Lots more fun shenanigans are available through common gateway interface (CGI) options, such as:

``` conf
# json with erb in it
/my-cool-file gitlab-language=erb?parent=json

# an entire file of highlighting errors!
/other-file gitlab-language=text?token=Error
```

Please note that these configurations only take effect when the `.gitattributes`
file is in your [default branch](repository/branches/default.md).

NOTE:
The Web IDE does not support `.gitattribute` files, but it's [planned for a future release](https://gitlab.com/gitlab-org/gitlab/-/issues/22014).

## Configure maximum file size for highlighting

You can configure the maximum size of the file to be highlighted.

The file size is measured in kilobytes, and is set to a default of `512 KB`. Any file _over_ the file size is rendered in plain text.

1. Open the [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example) configuration file.

1. Add this section, replacing `maximum_text_highlight_size_kilobytes` with the value you want.

   ```yaml
   gitlab:
     extra:
       ## Maximum file size for syntax highlighting
       ## https://docs.gitlab.com/ee/user/project/highlighting.html
       maximum_text_highlight_size_kilobytes: 512
   ```
