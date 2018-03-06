# Translating GitLab

For managing the translation process we use [Crowdin](https://crowdin.com).

## Using Crowdin

The first step is to get familiar with Crowdin.

### Sign In

To contribute translations at [translate.gitlab.com](https://translate.gitlab.com)
you must create a Crowdin account.
You may create a new account or use any of their supported sign in services.

### Language Selections

GitLab is being translated into many languages.

1. Select the language you would like to contribute translations to by clicking the flag
1. You will see a list of files and folders.
  Click `gitlab.pot` to open the translation editor.

### Translation Editor

The online translation editor is the easiest way to contribute translations.

![Crowdin Editor](img/crowdin-editor.png)

1. Strings for translation are listed in the left panel
1. Translations are entered into the central panel.
  Multiple translations will be required for strings that contains plurals.
  The string to be translated is shown above with glossary terms highlighted.
  If the string to be translated is not clear, you can 'Request Context'

A glossary of common terms is available in the right panel by clicking Terms.
Comments can be added to discuss a translation with the community.

Remember to **Save** each translation.

## General Translation Guidelines

Be sure to check the following guidelines before you translate any strings.

### Namespaced strings

When an externalized string is prepended with a namespace, e.g.
`s_('OpenedNDaysAgo|Opened')`, the namespace should be removed from the final
translation.
For example in French `OpenedNDaysAgo|Opened` would be translated to
`Ouvert•e`, not `OpenedNDaysAgo|Ouvert•e`.

### Technical terms

Some technical terms should be treated like proper nouns and not be translated.

Technical terms that should always be in English are noted in the glossary when
using [translate.gitlab.com](https://translate.gitlab.com).

This helps maintain a logical connection and consistency between tools (e.g.
`git` client) and GitLab.

### Formality

The level of formality used in software varies by language.
For example, in French we translate `you` as the formal `vous`.

You can refer to other translated strings and notes in the glossary to assist
determining a suitable level of formality.

### Inclusive language

[Diversity] is one of GitLab's values.
We ask you to avoid translations which exclude people based on their gender or
ethnicity.
In languages which distinguish between a male and female form, use both or
choose a neutral formulation.

For example in German, the word "user" can be translated into "Benutzer" (male) or "Benutzerin" (female).
Therefore "create a new user" would translate into "Benutzer(in) anlegen".

[Diversity]: https://about.gitlab.com/handbook/values/#diversity

### Updating the glossary

To propose additions to the glossary please
[open an issue](https://gitlab.com/gitlab-org/gitlab-ce/issues).

## French Translation Guidelines

### Inclusive language in French

In French, we should follow the guidelines from [ecriture-inclusive.fr]. For
instance:

- Utilisateur•rice•s

[ecriture-inclusive.fr]: http://www.ecriture-inclusive.fr/
