[Rouge]: https://rubygems.org/gems/rouge

# Syntax Highlighting

GitLab provides syntax highlighting on all files and snippets through the [Rouge][] rubygem. It will try to guess what language to use based on the file extension, which most of the time is sufficient.

If GitLab is guessing wrong, you can override its choice of language using the `gitlab-language` attribute in `.gitattributes`. For example, if you are working in a Prolog project and using the `.pl` file extension (which would normally be highlighted as Perl), you can add the following to your `.gitattributes` file:

``` conf
*.pl gitlab-language=prolog
```

When you check in and push that change, all `*.pl` files in your project will be highlighted as Prolog.

The paths here are simply git's builtin [`.gitattributes` interface](https://git-scm.com/docs/gitattributes).  So, if you were to invent a file format called a `Nicefile` at the root of your project that used ruby syntax, all you need is:

``` conf
/Nicefile gitlab-language=ruby
```

To disable highlighting entirely, use `gitlab-language=text`. Lots more fun shenanigans are available through CGI options, such as:

``` conf
# json with erb in it
/my-cool-file gitlab-language=erb?parent=json

# an entire file of highlighting errors!
/other-file gitlab-language=text?token=Error
```

Please note that these configurations will only take effect when the `.gitattributes` file is in your default branch (usually `master`).
