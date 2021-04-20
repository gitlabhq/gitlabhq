# Web IDE Languages

The Web IDE uses the [Monaco editor](https://microsoft.github.io/monaco-editor/) which uses the [Monarch library](https://microsoft.github.io/monaco-editor/monarch.html) for syntax highlighting.
The Web IDE currently supports all languages defined in the [monaco-languages](https://github.com/microsoft/monaco-languages/tree/master/src) repository.

## Adding New Languages

While Monaco supports a wide variety of languages, there's always the chance that it's missing something.
You'll find a list of [unsupported languages in this epic](https://gitlab.com/groups/gitlab-org/-/epics/1474), which is the right place to add more if needed.

Should you be willing to help us and add support to GitLab for any missing languages, here are the steps to do so:

1. Create a new issue and add it to [this epic](https://gitlab.com/groups/gitlab-org/-/epics/1474), if it doesn't already exist.
2. Create a new file in this folder called `{languageName}.js`, where `{languageName}` is the name of the language you want to add support for.
3. Follow the [Monarch documentation](https://microsoft.github.io/monaco-editor/monarch.html) to add a configuration for the new language.
    - Example: The [`vue.js`](./vue.js) file in the current directory adds support for Vue.js Syntax Highlighting.
4. Add tests for the new language implementation in `spec/frontend/ide/lib/languages/{langaugeName}.js`.
    - Example: See [`vue_spec.js`](spec/frontend/ide/lib/languages/vue_spec.js).
5. Create a [merge request](https://docs.gitlab.com/ee/user/project/merge_requests/creating_merge_requests.html) with your newly added language.

Thank you!
