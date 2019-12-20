# Internationalization for GitLab

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10669) in GitLab 9.2.

For working with internationalization (i18n),
[GNU gettext](https://www.gnu.org/software/gettext/) is used given it's the most
used tool for this task and there are a lot of applications that will help us to
work with it.

## Setting up GitLab Development Kit (GDK)

In order to be able to work on the [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss)
project you must download and configure it through [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/set-up-gdk.md).

Once you have the GitLab project ready, you can start working on the translation.

## Tools

The following tools are used:

1. [`gettext_i18n_rails`](https://github.com/grosser/gettext_i18n_rails): this
   gem allow us to translate content from models, views and controllers. Also
   it gives us access to the following raketasks:
   - `rake gettext:find`: Parses almost all the files from the
     Rails application looking for content that has been marked for
     translation. Finally, it updates the PO files with the new content that
     it has found.
   - `rake gettext:pack`: Processes the PO files and generates the
     MO files that are binary and are finally used by the application.

1. [`gettext_i18n_rails_js`](https://github.com/webhippie/gettext_i18n_rails_js):
   this gem is useful to make the translations available in JavaScript. It
   provides the following raketask:
   - `rake gettext:po_to_json`: Reads the contents from the PO files and
     generates JSON files containing all the available translations.

1. PO editor: there are multiple applications that can help us to work with PO
   files, a good option is [Poedit](https://poedit.net/download) which is
   available for macOS, GNU/Linux and Windows.

## Preparing a page for translation

We basically have 4 types of files:

1. Ruby files: basically Models and Controllers.
1. HAML files: these are the view files.
1. ERB files: used for email templates.
1. JavaScript files: we mostly need to work with Vue templates.

### Ruby files

If there is a method or variable that works with a raw string, for instance:

```ruby
def hello
  "Hello world!"
end
```

Or:

```ruby
hello = "Hello world!"
```

You can easily mark that content for translation with:

```ruby
def hello
  _("Hello world!")
end
```

Or:

```ruby
hello = _("Hello world!")
```

NOTE: **Note:** Messages in the API (`lib/api/` or `app/graphql`) do
not need to be externalised.

### HAML files

Given the following content in HAML:

```haml
%h1 Hello world!
```

You can mark that content for translation with:

```haml
%h1= _("Hello world!")
```

### ERB files

Given the following content in ERB:

```erb
<h1>Hello world!</h1>
```

You can mark that content for translation with:

```erb
<h1><%= _("Hello world!") %></h1>
```

### JavaScript files

In JavaScript we added the `__()` (double underscore parenthesis) function that
you can import from the `~/locale` file. For instance:

```js
import { __ } from '~/locale';
const label = __('Subscribe');
```

In order to test JavaScript translations you have to change the GitLab
localization to other language than English and you have to generate JSON files
using `bin/rake gettext:po_to_json` or `bin/rake gettext:compile`.

### Dynamic translations

Sometimes there are some dynamic translations that can't be found by the
parser when running `bin/rake gettext:find`. For these scenarios you can
use the [`N_` method](https://github.com/grosser/gettext_i18n_rails/blob/c09e38d481e0899ca7d3fc01786834fa8e7aab97/Readme.md#unfound-translations-with-rake-gettextfind).

There is also and alternative method to [translate messages from validation errors](https://github.com/grosser/gettext_i18n_rails/blob/c09e38d481e0899ca7d3fc01786834fa8e7aab97/Readme.md#option-a).

## Working with special content

### Interpolation

Placeholders in translated text should match the code style of the respective source file.
For example use `%{created_at}` in Ruby but `%{createdAt}` in JavaScript. Make sure to [avoid splitting sentences when adding links](#avoid-splitting-sentences-when-adding-links).

- In Ruby/HAML:

  ```ruby
  _("Hello %{name}") % { name: 'Joe' } => 'Hello Joe'
  ```

- In JavaScript:

  ```js
  import { __, sprintf } from '~/locale';

  sprintf(__('Hello %{username}'), { username: 'Joe' }); // => 'Hello Joe'
  ```

  By default, `sprintf` escapes the placeholder values.
  If you want to take care of that yourself, you can pass `false` as third argument.

  ```js
  import { __, sprintf } from '~/locale';

  sprintf(__('This is %{value}'), { value: '<strong>bold</strong>' }); // => 'This is &lt;strong&gt;bold&lt;/strong&gt;'
  sprintf(__('This is %{value}'), { value: '<strong>bold</strong>' }, false); // => 'This is <strong>bold</strong>'
  ```

### Plurals

- In Ruby/HAML:

  ```ruby
  n_('Apple', 'Apples', 3)
  # => 'Apples'
  ```

  Using interpolation:

  ```ruby
  n_("There is a mouse.", "There are %d mice.", size) % size
  # => When size == 1: 'There is a mouse.'
  # => When size == 2: 'There are 2 mice.'
  ```

  Avoid using `%d` or count variables in singular strings. This allows more natural translation in some languages.

- In JavaScript:

  ```js
  n__('Apple', 'Apples', 3)
  // => 'Apples'
  ```

  Using interpolation:

  ```js
  n__('Last day', 'Last %d days', x)
  // => When x == 1: 'Last day'
  // => When x == 2: 'Last 2 days'
  ```

### Namespaces

Sometimes you need to add some context to the text that you want to translate
(if the word occurs in a sentence and/or the word is ambiguous).
Namespaces should be PascalCase.

- In Ruby/HAML:

  ```ruby
  s_('OpenedNDaysAgo|Opened')
  ```

  In case the translation is not found it will return `Opened`.

- In JavaScript:

  ```js
  s__('OpenedNDaysAgo|Opened')
  ```

Note: The namespace should be removed from the translation. See the [translation
guidelines for more details](translation.md#namespaced-strings).

### Dates / times

- In JavaScript:

```js
import { createDateTimeFormat } from '~/locale';

const dateFormat = createDateTimeFormat({ year: 'numeric', month: 'long', day: 'numeric' });
console.log(dateFormat.format(new Date('2063-04-05'))) // April 5, 2063
```

This makes use of [`Intl.DateTimeFormat`].

[`Intl.DateTimeFormat`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat

- In Ruby/HAML, we have two ways of adding format to dates and times:

  1. **Through the `l` helper**, i.e. `l(active_session.created_at, format: :short)`. We have some predefined formats for
     [dates](https://gitlab.com/gitlab-org/gitlab/blob/4ab54c2233e91f60a80e5b6fa2181e6899fdcc3e/config/locales/en.yml#L54) and [times](https://gitlab.com/gitlab-org/gitlab/blob/4ab54c2233e91f60a80e5b6fa2181e6899fdcc3e/config/locales/en.yml#L262).
     If you need to add a new format, because other parts of the code could benefit from it,
     you'll need to add it to [en.yml](https://gitlab.com/gitlab-org/gitlab/blob/master/config/locales/en.yml) file.
  1. **Through `strftime`**, i.e. `milestone.start_date.strftime('%b %-d')`. We use `strftime` in case none of the formats
     defined on [en.yml](https://gitlab.com/gitlab-org/gitlab/blob/master/config/locales/en.yml) matches the date/time
     specifications we need, and if there is no need to add it as a new format because is very particular (i.e. it's only used in a single view).

## Best practices

### Splitting sentences

Please never split a sentence as that would assume the sentence grammar and
structure is the same in all languages.

For instance, the following:

```js
{{ s__("mrWidget|Set by") }}
{{ author.name }}
{{ s__("mrWidget|to be merged automatically when the pipeline succeeds") }}
```

should be externalized as follows:

```js
{{ sprintf(s__("mrWidget|Set by %{author} to be merged automatically when the pipeline succeeds"), { author: author.name }) }}
```

#### Avoid splitting sentences when adding links

This also applies when using links in between translated sentences, otherwise these texts are not translatable in certain languages.

- In Ruby/HAML, instead of:

  ```haml
  - zones_link = link_to(s_('ClusterIntegration|zones'), 'https://cloud.google.com/compute/docs/regions-zones/regions-zones', target: '_blank', rel: 'noopener noreferrer')
  = s_('ClusterIntegration|Learn more about %{zones_link}').html_safe % { zones_link: zones_link }
  ```

  Set the link starting and ending HTML fragments as variables like so:

  ```haml
  - zones_link_url = 'https://cloud.google.com/compute/docs/regions-zones/regions-zones'
  - zones_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: zones_link_url }
  = s_('ClusterIntegration|Learn more about %{zones_link_start}zones%{zones_link_end}').html_safe % { zones_link_start: zones_link_start, zones_link_end: '</a>'.html_safe }
  ```

- In JavaScript, instead of:

  ```js
  {{
      sprintf(s__("ClusterIntegration|Learn more about %{link}"), {
          link: '<a href="https://cloud.google.com/compute/docs/regions-zones/regions-zones" target="_blank" rel="noopener noreferrer">zones</a>'
      })
  }}
  ```

  Set the link starting and ending HTML fragments as variables like so:

  ```js
  {{
      sprintf(s__("ClusterIntegration|Learn more about %{linkStart}zones%{linkEnd}"), {
          linkStart: '<a href="https://cloud.google.com/compute/docs/regions-zones/regions-zones" target="_blank" rel="noopener noreferrer">'
          linkEnd: '</a>',
      })
  }}
  ```

The reasoning behind this is that in some languages words change depending on context. For example in Japanese は is added to the subject of a sentence and を to the object. This is impossible to translate correctly if we extract individual words from the sentence.

When in doubt, try to follow the best practices described in this [Mozilla
Developer documentation][mdn].

[mdn]: https://developer.mozilla.org/en-US/docs/Mozilla/Localization/Localization_content_best_practices#Splitting

##### Vue components interpolation

When translating UI text in Vue components, you might want to include child components inside
the translation string.
You could not use a JavaScript-only solution to render the translation,
because Vue would not be aware of the child components and would render them as plain text.

For this use case, you should use the `gl-sprintf` component which is maintained
in **GitLab UI**.

The `gl-sprintf` component accepts a `message` property, which is the translatable string,
and it exposes a named slot for every placeholder in the string, which lets you include Vue
components easily.

Assume you want to print the translatable string
`Pipeline %{pipelineId} triggered %{timeago} by %{author}`. To replace the `%{timeago}` and
`%{author}` placeholders with Vue components, here's how you would do that with `gl-sprintf`:

```html
<template>
  <div>
    <gl-sprintf :message="__('Pipeline %{pipelineId} triggered %{timeago} by %{author}')">
      <template #pipelineId>{{ pipeline.id }}</template>
      <template #timeago>
        <timeago :time="pipeline.triggerTime" />
      </template>
      <template #author>
        <gl-avatar-labeled
          :src="pipeline.triggeredBy.avatarPath"
          :label="pipeline.triggeredBy.name"
        />
      </template>
    </gl-sprintf>
  </div>
</template>
```

For more information, see the [`gl-sprintf`](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-sprintf--default) documentation.

## Updating the PO files with the new content

Now that the new content is marked for translation, we need to update
`locale/gitlab.pot` files with the following command:

```sh
bin/rake gettext:regenerate
```

This command will update `locale/gitlab.pot` file with the newly externalized
strings and remove any strings that aren't used anymore. You should check this
file in. Once the changes are on master, they will be picked up by
[Crowdin](https://translate.gitlab.com) and be presented for
translation.

We don't need to check in any changes to the `locale/[language]/gitlab.po` files.
They are updated automatically when [translations from Crowdin are merged](merging_translations.md).

If there are merge conflicts in the `gitlab.pot` file, you can delete the file
and regenerate it using the same command.

### Validating PO files

To make sure we keep our translation files up to date, there's a linter that is
running on CI as part of the `static-analysis` job.

To lint the adjustments in PO files locally you can run `rake gettext:lint`.

The linter will take the following into account:

- Valid PO-file syntax
- Variable usage
  - Only one unnamed (`%d`) variable, since the order of variables might change
    in different languages
  - All variables used in the message-id are used in the translation
  - There should be no variables used in a translation that aren't in the
    message-id
- Errors during translation.

The errors are grouped per file, and per message ID:

```
Errors in `locale/zh_HK/gitlab.po`:
  PO-syntax errors
    SimplePoParser::ParserErrorSyntax error in lines
    Syntax error in msgctxt
    Syntax error in msgid
    Syntax error in msgstr
    Syntax error in message_line
    There should be only whitespace until the end of line after the double quote character of a message text.
    Parsing result before error: '{:msgid=>["", "You are going to remove %{project_name_with_namespace}.\\n", "Removed project CANNOT be restored!\\n", "Are you ABSOLUTELY sure?"]}'
    SimplePoParser filtered backtrace: SimplePoParser::ParserError
Errors in `locale/zh_TW/gitlab.po`:
  1 pipeline
    <%d 條流水線> is using unknown variables: [%d]
    Failure translating to zh_TW with []: too few arguments
```

In this output the `locale/zh_HK/gitlab.po` has syntax errors.
The `locale/zh_TW/gitlab.po` has variables that are used in the translation that
aren't in the message with id `1 pipeline`.

## Adding a new language

Let's suppose you want to add translations for a new language, let's say French.

1. The first step is to register the new language in `lib/gitlab/i18n.rb`:

   ```ruby
   ...
   AVAILABLE_LANGUAGES = {
     ...,
     'fr' => 'Français'
   }.freeze
   ...
   ```

1. Next, you need to add the language:

   ```sh
   bin/rake gettext:add_language[fr]
   ```

   If you want to add a new language for a specific region, the command is similar,
   you just need to separate the region with an underscore (`_`). For example:

   ```sh
   bin/rake gettext:add_language[en_GB]
   ```

   Please note that you need to specify the region part in capitals.

1. Now that the language is added, a new directory has been created under the
   path: `locale/fr/`. You can now start using your PO editor to edit the PO file
   located in: `locale/fr/gitlab.edit.po`.

1. After you're done updating the translations, you need to process the PO files
   in order to generate the binary MO files and finally update the JSON files
   containing the translations:

   ```sh
   bin/rake gettext:compile
   ```

1. In order to see the translated content we need to change our preferred language
   which can be found under the user's **Settings** (`/profile`).

1. After checking that the changes are ok, you can proceed to commit the new files.
   For example:

   ```sh
   git add locale/fr/ app/assets/javascripts/locale/fr/
   git commit -m "Add French translations for Cycle Analytics page"
   ```
