---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to contribute to GitLab Documentation.
title: Vale documentation tests
---

[Vale](https://vale.sh/) is a grammar, style, and word usage linter for the
English language. Vale's configuration is stored in the [`.vale.ini`](https://vale.sh/docs/topics/config/) file located
in the root directory of projects. For example, the [`.vale.ini`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.vale.ini)
of the `gitlab` project.

Vale supports creating [custom rules](https://vale.sh/docs/topics/styles/) that extend any of
several types of checks, which we store in the documentation directory of projects. For example,
the [`doc/.vale` directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.vale) of the `gitlab` project.

This configuration is also used in build pipelines, where [error-level rules](#result-types) are enforced.

You can use Vale:

- [On the command line](https://vale.sh/docs/vale-cli/structure/).
- [In a code editor](#configure-vale-in-your-editor).
- [In a Git hook](_index.md#configure-pre-push-hooks). Vale only reports errors in the Git hook (the same
  configuration as the CI/CD pipelines), and does not report suggestions or warnings.

## Install Vale

Install [`vale`](https://github.com/errata-ai/vale/releases) using either:

- If using [`asdf`](https://asdf-vm.com), the [`asdf-vale` plugin](https://github.com/pdemagny/asdf-vale). In a checkout
  of a GitLab project with a `.tool-versions` file ([example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.tool-versions)),
  run:

  ```shell
  asdf plugin add vale && asdf install vale
  ```

- A package manager:
  - macOS using `brew`, run: `brew install vale`.
  - Linux, use your distribution's package manager or a [released binary](https://github.com/errata-ai/vale/releases).

## Configure Vale in your editor

Using linters in your editor is more convenient than having to run the commands from the
command line.

To configure Vale in your editor, install one of the following as appropriate:

- Visual Studio Code [`ChrisChinchilla.vale-vscode` extension](https://marketplace.visualstudio.com/items?itemName=ChrisChinchilla.vale-vscode).
  You can configure the plugin to [display only a subset of alerts](#limit-which-tests-are-run).
- Sublime Text [`SublimeLinter-vale` package](https://packagecontrol.io/packages/SublimeLinter-vale). To have Vale
  suggestions appears as blue instead of red (which is how errors appear), add `vale` configuration to your
  [SublimeLinter](https://www.sublimelinter.com/en/master/) configuration:

  ```json
  "vale": {
    "styles": [{
      "mark_style": "outline",
      "scope": "region.bluish",
      "types": ["suggestion"]
    }]
  }
  ```

- [LSP for Sublime Text](https://lsp.sublimetext.io) package [`LSP-vale-ls`](https://packagecontrol.io/packages/LSP-vale-ls).
- Vim [ALE plugin](https://github.com/dense-analysis/ale).
- JetBrains IDEs - No plugin exists, but
  [this issue comment](https://github.com/errata-ai/vale-server/issues/39#issuecomment-751714451)
  contains tips for configuring an external tool.
- Emacs [Flycheck extension](https://github.com/flycheck/flycheck). A minimal configuration
  for Flycheck to work with Vale could look like:

  ```lisp
  (flycheck-define-checker vale
    "A checker for prose"
    :command ("vale" "--output" "line" "--no-wrap"
              source)
    :standard-input nil
    :error-patterns
      ((error line-start (file-name) ":" line ":" column ":" (id (one-or-more (not (any ":")))) ":" (message)   line-end))
    :modes (markdown-mode org-mode text-mode)
    :next-checkers ((t . markdown-markdownlint-cli))
  )

  (add-to-list 'flycheck-checkers 'vale)
  ```

  In this setup the `markdownlint` checker is set as a "next" checker from the defined `vale` checker.
  Enabling this custom Vale checker provides error linting from both Vale and markdownlint.

## Result types

Vale returns three types of results:

- **Error** - For branding guidelines, trademark guidelines, and anything that causes content on
  the documentation site to render incorrectly.
- **Warning** - For general style guide rules, tenets, and best practices.
- **Suggestion** - For technical writing style preferences that may require refactoring of documentation or updates to an exceptions list.

The result types have these attributes:

| Result type  | Displays in CI/CD job output | Displays in MR diff | Causes CI/CD jobs to fail | Vale rule link |
|--------------|------------------------------|---------------------|---------------------------|----------------|
| `error`      | **{check-circle}** Yes       | **{check-circle}** Yes | **{check-circle}** Yes | [Error-level Vale rules](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=master&scope=blobs&search=level%3A+error+file%3A%5Edoc&snippets=false&utf8=✓) |
| `warning`    | **{dotted-circle}** No       | **{check-circle}** Yes | **{dotted-circle}** No | [Warning-level Vale rules](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=master&scope=blobs&search=level%3A+warning+file%3A%5Edoc&snippets=false&utf8=✓) |
| `suggestion` | **{dotted-circle}** No       | **{dotted-circle}** No | **{dotted-circle}** No | [Suggestion-level Vale rules](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=master&scope=blobs&search=level%3A+suggestion+file%3A%5Edoc&snippets=false&utf8=✓) |

## When to add a new Vale rule

It's tempting to add a Vale rule for every style guide rule. However, we should be
mindful of the effort to create and enforce a Vale rule, and the noise it creates.

In general, follow these guidelines:

- If you add an [error-level Vale rule](#result-types), you must fix
  the existing occurrences of the issue in the documentation before you can add the rule.

  If there are too many issues to fix in a single merge request, add the rule at a
  `warning` level. Then, fix the existing issues in follow-up merge requests.
  When the issues are fixed, promote the rule to an `error`.

- If you add a warning-level or suggestion-level rule, consider:

  - How many more warnings or suggestions it creates in the Vale output. If the
    number of additional warnings is significant, the rule might be too broad.

  - How often an author might ignore it because it's acceptable in the context.
    If the rule is too subjective, it cannot be adequately enforced and creates
    unnecessary additional warnings.

  - Whether it's appropriate to display in the merge request diff in the GitLab UI.
    If the rule is difficult to implement directly in the merge request (for example,
    it requires page refactoring), set it to suggestion-level so it displays in local editors only.

## Where to add a new Vale rule

New Vale rules belong in one of two categories (known in Vale as [styles](https://vale.sh/docs/topics/styles/)). These
rules are stored separately in specific styles directories specified in a project's `.vale.ini` file. For example,
[`.vale.ini` for the `gitlab` project](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.vale.ini).

Where to add your new rules depends on the type of rule you're proposing:

- `gitlab_base`: base rules that are applicable to any GitLab documentation.
- `gitlab_docs`: rules that are only applicable to documentation that is published to <https://docs.gitlab.com>.

Most new rules belong in [`gitlab_base`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.vale/gitlab_base).

## Limit which tests are run

You can set Visual Studio Code to display only a subset of Vale alerts when viewing files:

1. Go to **Preferences > Settings > Extensions > Vale**.
1. In **Vale CLI: Min Alert Level**, select the minimum alert level you want displayed in files.

To display only a subset of Vale alerts when running Vale from the command line, use
the `--minAlertLevel` flag, which accepts `error`, `warning`, or `suggestion`. Combine it with `--config`
to point to the configuration file in the project, if needed:

```shell
vale --config .vale.ini --minAlertLevel error doc/**/*.md
```

Omit the flag to display all alerts, including `suggestion` level alerts.

### Test one rule at a time

To test only a single rule when running Vale from the command line, modify this
command, replacing `OutdatedVersions` with the name of the rule:

```shell
vale --no-wrap --filter='.Name=="gitlab_base.OutdatedVersions"' doc/**/*.md
```

## Disable Vale tests

You can disable a specific Vale linting rule or all Vale linting rules for any portion of a
document:

- To disable a specific rule, add a `<!-- vale gitlab_<type>.rulename = NO -->` tag before the text, and a
  `<!-- vale gitlab_<type>.rulename = YES -->` tag after the text, replacing `rulename` with the filename of a test in the
  directory of one of the [GitLab styles](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc/.vale).
- To disable all Vale linting rules, add a `<!-- vale off -->` tag before the text, and a
  `<!-- vale on -->` tag after the text.

Whenever possible, exclude only the problematic rule and lines.

Ignore statements do not work for Vale rules with the `raw` scope. For more information, see this [issue](https://github.com/errata-ai/vale/issues/194).

For more information on Vale scoping rules, see
[Vale's documentation](https://vale.sh/docs/topics/scoping/).

## Show Vale warnings on commit or push

By default, the Vale check in Lefthook only shows error-level issues. The default branches
have no Vale errors, so any errors listed here are introduced by the commit to the branch.

To also see the Vale warnings, set a local environment variable: `VALE_WARNINGS=true`.

Enable Vale warnings on commit or push to improve the documentation suite by:

- Detecting warnings you might be introducing with your commits.
- Identifying warnings that already exist in the page, which you can resolve to reduce technical debt.

These warnings:

- Don't stop the commit from working.
- Don't result in a broken pipeline.
- Include all warnings for a file, not just warnings that are introduced by the commits.

To enable Vale warnings with Lefthook:

- Automatically, add `VALE_WARNINGS=true` to your shell configuration.
- Manually, prepend `VALE_WARNINGS=true` to invocations of `lefthook`. For example:

  ```shell
  VALE_WARNINGS=true bundle exec lefthook run pre-commit
  ```

You can also [configure your editor](#configure-vale-in-your-editor) to show Vale warnings.

## Resolve problems Vale identifies

### Spelling test

When Vale flags a valid word as a spelling mistake, you can fix it following these
guidelines:

| Flagged word                                         | Guideline |
|------------------------------------------------------|-----------|
| jargon                                               | Rewrite the sentence to avoid it. |
| *correctly-capitalized* name of a product or service | Add the word to the [Vale spelling exceptions list](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/spelling-exceptions.txt). |
| name of a person                                     | Remove the name if it's not needed, or [add the Vale exception code inline](#disable-vale-tests). |
| a command, variable, code, or similar                | Put it in backticks or a code block. For example: ``The git clone command can be used with the CI_COMMIT_BRANCH variable.`` -> ``The `git clone` command can be used with the `CI_COMMIT_BRANCH` variable.`` |
| UI text from GitLab                                  | Verify it correctly matches the UI, then: If it does not match the UI, update it. If it matches the UI, but the UI seems incorrect, create an issue to see if the UI needs to be fixed. If it matches the UI and seems correct, add it to the [Vale spelling exceptions list](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/spelling-exceptions.txt). |
| UI text from a third-party product                   | Rewrite the sentence to avoid it, or [add the Vale exception code in-line](#disable-vale-tests). |

#### Uppercase (acronym) test

The [`Uppercase.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Uppercase.yml)
test checks for incorrect usage of words in all capitals. For example, avoid usage
like `This is NOT important`.

If the word must be in all capitals, follow these guidelines:

| Flagged word                                                   | Guideline |
|----------------------------------------------------------------|-----------|
| Acronym (likely known by the average visitor to that page)     | Add the acronym to the list of words and acronyms in `Uppercase.yml`. |
| Acronym (likely not known by the average visitor to that page) | The first time the acronym is used, write it out fully followed by the acronym in parentheses. In later uses, use just the acronym by itself. For example: `This feature uses the File Transfer Protocol (FTP). FTP is...`. |
| Correctly capitalized name of a product or service           | Add the name to the list of words and acronyms in `Uppercase.yml`. |
| Command, variable, code, or similar                            | Put it in backticks or a code block. For example: ``Use `FALSE` as the variable value.`` |
| UI text from a third-party product                             | Rewrite the sentence to avoid it, or [add the vale exception code in-line](#disable-vale-tests). |

### Readability score

In [`ReadingLevel.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/ReadingLevel.yml),
we have implemented
[the Flesch-Kincaid grade level test](https://readable.com/readability/flesch-reading-ease-flesch-kincaid-grade-level/)
to determine the readability of our documentation.

As a general guideline, the lower the score, the more readable the documentation.
For example, a page that scores `12` before a set of changes, and `9` after, indicates an iterative improvement to readability. The score is not an exact science, but is meant to help indicate the
general complexity level of the page.

The readability score is calculated based on the number of words per sentence, and the number
of syllables per word. For more information, see [the Vale documentation](https://vale.sh/docs/topics/styles/#metric).

## Export Vale results to a file

To export all (or filtered) Vale results to a file, modify this command:

```shell
# Returns results of types suggestion, warning, and error
find . -name '*.md' | sort | xargs vale --minAlertLevel suggestion --output line > ../../results.txt

# Returns only warnings and errors
find . -name '*.md' | sort | xargs vale --minAlertLevel warning --output line > ../../results.txt

# Returns only errors
find . -name '*.md' | sort | xargs vale --minAlertLevel error --output line > ../../results.txt
```

These results can be used with the
[`create_issues.js` script](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/scripts/create_issues.js)
to generate [documentation-related issues for Hackathons](https://handbook.gitlab.com/handbook/product/ux/technical-writing/workflow/#create-issues-for-a-hackathon).

## Enable custom rules locally

Vale 3.0 and later supports using two locations for rules. This change enables you
to create and use your own custom rules alongside the rules included in a project.

To create and use custom rules locally on macOS:

1. Create a local file in the Application Support folder for Vale:

   ```shell
   touch ~/Library/Application\ Support/vale/.vale.ini
   ```

1. Add these lines to the `.vale.ini` file you just created:

   ```yaml
   [*.md]
   BasedOnStyles = local
   ```

1. If the folder `~/Library/Application Support/vale/styles/local` does not exist,
   create it:

   ```shell
   mkdir ~/Library/Application\ Support/vale/styles/local
   ```

1. Add your desired rules to `~/Library/Application Support/vale/styles/local`.

Rules in your `local` style directory are prefixed with `local` instead of `gitlab`
in Vale results, like this:

```shell
$ vale --minAlertLevel warning doc/ci/yaml/index.md

 doc/ci/yaml/index.md
    ...[snip]...
 3876:17   warning  Instead of future tense 'will   gitlab.FutureTense
                    be', use present tense.
 3897:26   error    Remove 'documentation'          local.new-rule

✖ 1 error, 5 warnings and 0 suggestions in 1 file.
```

## Related topics

- [Styles in Vale](https://vale.sh/docs/topics/styles/)
- [Example styles](https://github.com/errata-ai/vale/tree/master/testdata/styles) containing rules you can adapt
