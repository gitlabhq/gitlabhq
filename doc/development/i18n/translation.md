---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Translating GitLab
---

For managing the translation process, we use [Crowdin](https://crowdin.com).
To contribute translations at [`translate.gitlab.com`](https://translate.gitlab.com),
you must create a Crowdin account. You may create a new account or use any of their supported
sign-in services.

## Language selections

GitLab is being translated into many languages. To select a language to contribute to:

1. Find the language that you want to contribute to, in the
   [GitLab Crowdin project](https://crowdin.com/project/gitlab-ee).

   - If the language you want is available, proceed to the next step.
   - If the language you want is not available,
     [open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&utf8=✓&state=all&label_name[]=Category%3AInternationalization).
     Notify our Crowdin administrators by including `@gitlab-org/foundations/import-and-integrate` in your issue.
   - After the issue and any merge requests are complete, restart this procedure.

1. View the list of files and folders. Select `gitlab.pot` to open the translation editor.

## Translation editor

The online translation editor is the easiest way to contribute translations.

![Crowdin Editor](img/crowdin-editor_v10_1.png)

- Strings for translation are listed in the left panel.
- Translations are entered into the central panel. Multiple translations are required for strings
  that contain plurals. The string to translate is shown in the above image with glossary terms
  highlighted. If the string to translate isn't clear, you can request context.

A glossary of common terms is available in the **Terms** tab in the right panel. In the **Comments**
tab, you can add comments to discuss a translation with the community.

Remember to **Save** each translation.

### Context

DETAILS:
**Status:** Beta

WARNING:
This feature is in [beta](../../policy/development_stages_support.md#beta).
You might get a string similar to the one you want to translate,
so be sure to select the correct string and line of code.
If you cannot find a string with code search, post a comment in Crowdin with that string.

In Crowdin, each string contains a link that shows all instances of the string in the entire GitLab codebase.
When you translate a string, you can go to the relevant commit or merge request to get more context.

![Crowdin Editor showing a string with a link for more translation context](img/crowdin-editor-string-context.png)

When you select the link, code search results appear for that string.
You can [view Git blame from code search](../../user/search/_index.md#view-git-blame-from-code-search)
to see the commits that added the string.
For a list of relevant merge requests, select a commit.

![GitLab code search displaying results for a string](img/gitlab-search-occurrence.png)

## General Translation Guidelines

Be sure to check the following guidelines before you translate any strings.

### Namespaced strings

A namespace precedes the string and is separated from it by a `|` (`namespace|string`). When you see
a namespace before an externalized string, you should remove the namespace from the final
translation. For example, in `OpenedNDaysAgo|Opened`, remove `OpenedNDaysAgo|`. If translating to
French, translate `OpenedNDaysAgo|Opened` to `Ouvert•e`, not `OpenedNDaysAgo|Ouvert•e`.

### Technical terms

You should treat some technical terms like proper nouns and not translate them. Technical terms that
should always be in English are noted in the glossary when using
[`translate.gitlab.com`](https://translate.gitlab.com).
This helps maintain a logical connection and consistency between tools (for example, a Git client)
and GitLab.

To find the list of technical terms:

1. Go to [`translate.gitlab.com`](https://translate.gitlab.com).
1. Select the language to translate.
1. Select **Glossary**.

### Formality

The level of formality used in software varies by language:

| Language | Formality | Example |
| -------- | --------- | ------- |
| French   | formal    | `vous` for `you` |
| German   | informal  | `du` for `you` |
| Spanish   | informal  | `tú` for `you` |

Refer to other translated strings and notes in the glossary to assist you in determining a suitable
level of formality.

### Inclusive language

[Diversity, inclusion, and belonging](https://handbook.gitlab.com/handbook/values/#diversity-inclusion)
are GitLab values. We ask you to avoid translations that exclude people based on their gender or
ethnicity. In languages that distinguish between a male and female form, use both or choose a
neutral formulation.

<!-- vale gitlab_base.Spelling = NO -->

For example, in German, the word _user_ can be translated into _Benutzer_ (male) or _Benutzerin_
(female). Therefore, _create a new user_ translates to _Benutzer(in) anlegen_.

<!-- vale gitlab_base.Spelling = YES -->

### Updating the glossary

To propose additions to the glossary,
[open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&utf8=✓&state=all&label_name[]=Category%3AInternationalization).

## French translation guidelines

<!-- vale gitlab_base.Spelling = NO -->

In French, the _écriture inclusive_ is now over (see on [Legifrance](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000036068906/)).
To include both genders, write _Utilisateurs et utilisatrices_ instead of _Utilisateur·rice·s_. If
there is not enough space, use the male gender alone.

<!-- vale gitlab_base.Spelling = YES -->
