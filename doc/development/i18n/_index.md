---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Translate GitLab to your language
---

The text in the GitLab user interface is in American English by default. Each string can be
translated to other languages. As each string is translated, it's added to the languages translation
file and made available in future GitLab releases.

Contributions to translations are always needed. Many strings are not yet available for translation
because they have not been externalized. Helping externalize strings benefits all languages. Some
translations are incomplete or inconsistent. Translating strings helps complete and improve each
language.

There are many ways you can contribute in translating GitLab.

## Externalize strings

Before a string can be translated, it must be externalized. This is the process where English
strings in the GitLab source code are wrapped in a function that retrieves the translated string for
the user's language.

As new features are added and existing features are updated, the surrounding strings are
externalized. However, there are many parts of GitLab that still need more work to externalize all
strings.

See [Externalization for GitLab](externalization.md).

### Editing externalized strings

If you edit externalized strings in GitLab, you must [update the `pot` file](externalization.md#updating-the-po-files-with-the-new-content) before pushing your changes.

## Translate strings

The translation process is managed at [https://crowdin.com/project/gitlab-ee](https://crowdin.com/project/gitlab-ee)
using [Crowdin](https://crowdin.com/).
You must create a Crowdin account before you can submit translations. Once you are signed in, select
the language you wish to contribute translations to.

Voting for translations is also valuable, helping to confirm good translations and flag inaccurate
ones.

See [Translation guidelines](translation.md).

## Proofreading

Proofreading helps ensure the accuracy and consistency of translations. All translations are
proofread before being accepted. If a translation requires changes, a comment explaining why
notifies you.

See [Proofreading Translations](proofreader.md) for more information on who can proofread and
instructions on becoming a proofreader yourself.

## Release

Translations are typically included in the next major or minor release.

See [Merging translations from Crowdin](merging_translations.md).
