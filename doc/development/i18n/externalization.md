---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Internationalization for GitLab

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10669) in GitLab 9.2.

For working with internationalization (i18n),
[GNU gettext](https://www.gnu.org/software/gettext/) is used given it's the most
used tool for this task and there are many applications that help us work with it.

NOTE:
All `rake` commands described on this page must be run on a GitLab instance. This instance is
usually the GitLab Development Kit (GDK).

## Setting up the GitLab Development Kit (GDK)

To work on the [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss)
project, you must download and configure it through the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/set-up-gdk.md).

After you have the GitLab project ready, you can start working on the translation.

## Tools

The following tools are used:

- [`gettext_i18n_rails`](https://github.com/grosser/gettext_i18n_rails):
  this gem allows us to translate content from models, views, and controllers. It also gives us
  access to the following Rake tasks:

  - `rake gettext:find`: parses almost all the files from the Rails application looking for content
    marked for translation. It then updates the PO files with this content.
  - `rake gettext:pack`: processes the PO files and generates the binary MO files that the
    application uses.

- [`gettext_i18n_rails_js`](https://github.com/webhippie/gettext_i18n_rails_js):
  this gem makes the translations available in JavaScript. It provides the following Rake task:

  - `rake gettext:po_to_json`: reads the contents of the PO files and generates JSON files that
    contain all the available translations.

- PO editor: there are multiple applications that can help us work with PO files. A good option is
  [Poedit](https://poedit.net/download),
  which is available for macOS, GNU/Linux, and Windows.

## Preparing a page for translation

There are four file types:

- Ruby files: models and controllers.
- HAML files: view files.
- ERB files: used for email templates.
- JavaScript files: we mostly work with Vue templates.

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

You can mark that content for translation with:

```ruby
def hello
  _("Hello world!")
end
```

Or:

```ruby
hello = _("Hello world!")
```

Be careful when translating strings at the class or module level since these are only evaluated once
at class load time. For example:

```ruby
validates :group_id, uniqueness: { scope: [:project_id], message: _("already shared with this group") }
```

This is translated when the class loads and results in the error message always being in the default
locale. Active Record's `:message` option accepts a `Proc`, so do this instead:

```ruby
validates :group_id, uniqueness: { scope: [:project_id], message: -> (object, data) { _("already shared with this group") } }
```

Messages in the API (`lib/api/` or `app/graphql`) do not need to be externalized.

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

```javascript
import { __ } from '~/locale';
const label = __('Subscribe');
```

To test JavaScript translations you must:

- Change the GitLab localization to a language other than English.
- Generate JSON files by using `bin/rake gettext:po_to_json` or `bin/rake gettext:compile`.

### Vue files

In Vue files, we make the following functions available:

- `__()` (double underscore parenthesis)
- `s__()` (namespaced double underscore parenthesis)

You can therefore import from the `~/locale` file.
For example:

```javascript
import { __, s__ } from '~/locale';
const label = __('Subscribe');
const nameSpacedlabel = __('Plan|Subscribe');
```

For the static text strings we suggest two patterns for using these translations in Vue files:

- External constants file:

  ```javascript
  javascripts
  │
  └───alert_settings
  │   │   constants.js
  │   └───components
  │       │   alert_settings_form.vue


  // constants.js

  import { s__ } from '~/locale';

  /* Integration constants */

  export const I18N_ALERT_SETTINGS_FORM = {
    saveBtnLabel: __('Save changes'),
  };


  // alert_settings_form.vue

  import {
    I18N_ALERT_SETTINGS_FORM,
  } from '../constants';

  <script>
    export default {
      i18n: {
        I18N_ALERT_SETTINGS_FORM,
      }
    }
  </script>

  <template>
    <gl-button
      ref="submitBtn"
      variant="success"
      type="submit"
    >
      {{ $options.i18n.I18N_ALERT_SETTINGS_FORM }}
    </gl-button>
  </template>
  ```

  When possible, you should opt for this pattern, as this allows you to import these strings directly into your component specs for re-use during testing.

- Internal component `$options` object:

  ```javascript
  <script>
    export default {
      i18n: {
        buttonLabel: s__('Plan|Button Label')
      }
    },
  </script>

  <template>
    <gl-button :aria-label="$options.i18n.buttonLabel">
      {{ $options.i18n.buttonLabel }}
    </gl-button>
  </template>
  ```

To visually test the Vue translations:

1. Change the GitLab localization to another language than English.
1. Generate JSON files using `bin/rake gettext:po_to_json` or `bin/rake gettext:compile`.

### Dynamic translations

Sometimes there are dynamic translations that the parser can't find when running
`bin/rake gettext:find`. For these scenarios you can use the [`N_` method](https://github.com/grosser/gettext_i18n_rails/blob/c09e38d481e0899ca7d3fc01786834fa8e7aab97/Readme.md#unfound-translations-with-rake-gettextfind).
There's also an alternative method to [translate messages from validation errors](https://github.com/grosser/gettext_i18n_rails/blob/c09e38d481e0899ca7d3fc01786834fa8e7aab97/Readme.md#option-a).

## Working with special content

### Interpolation

Placeholders in translated text should match the respective source file's code style. For example
use `%{created_at}` in Ruby but `%{createdAt}` in JavaScript. Make sure to
[avoid splitting sentences when adding links](#avoid-splitting-sentences-when-adding-links).

- In Ruby/HAML:

  ```ruby
  _("Hello %{name}") % { name: 'Joe' } => 'Hello Joe'
  ```

- In Vue:

  Use the [`GlSprintf`](https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/utilities-sprintf--sentence-with-link) component if:

  - You need to include child components in the translation string.
  - You need to include HTML in your translation string.
  - You're using `sprintf` and need to pass `false` as the third argument to
    prevent it from escaping placeholder values.

  For example:

  ```html
  <gl-sprintf :message="s__('ClusterIntegration|Learn more about %{linkStart}zones%{linkEnd}')">
    <template #link="{ content }">
      <gl-link :href="somePath">{{ content }}</gl-link>
    </template>
  </gl-sprintf>
  ```

  In other cases, it might be simpler to use `sprintf`, perhaps in a computed
  property. For example:

  ```html
  <script>
  import { __, sprintf } from '~/locale';

  export default {
    ...
    computed: {
      userWelcome() {
        sprintf(__('Hello %{username}'), { username: this.user.name });
      }
    }
    ...
  }
  </script>

  <template>
    <span>{{ userWelcome }}</span>
  </template>
  ```

- In JavaScript (when Vue cannot be used):

  ```javascript
  import { __, sprintf } from '~/locale';

  sprintf(__('Hello %{username}'), { username: 'Joe' }); // => 'Hello Joe'
  ```

  If you need to use markup within the translation, use `sprintf` and stop it
  from escaping placeholder values by passing `false` as its third argument.
  You **must** escape any interpolated dynamic values yourself, for instance
  using `escape` from `lodash`.

  ```javascript
  import { escape } from 'lodash';
  import { __, sprintf } from '~/locale';

  let someDynamicValue = '<script>alert("evil")</script>';

  // Dangerous:
  sprintf(__('This is %{value}'), { value: `<strong>${someDynamicValue}</strong>`, false);
  // => 'This is <strong><script>alert('evil')</script></strong>'

  // Incorrect:
  sprintf(__('This is %{value}'), { value: `<strong>${someDynamicValue}</strong>` });
  // => 'This is &lt;strong&gt;&lt;script&gt;alert(&#x27;evil&#x27;)&lt;/script&gt;&lt;/strong&gt;'

  // OK:
  sprintf(__('This is %{value}'), { value: `<strong>${escape(someDynamicValue)}</strong>` }, false);
  // => 'This is <strong>&lt;script&gt;alert(&#x27;evil&#x27;)&lt;/script&gt;</strong>'
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

  Avoid using `%d` or count variables in singular strings. This allows more natural translation in
  some languages.

- In JavaScript:

  ```javascript
  n__('Apple', 'Apples', 3)
  // => 'Apples'
  ```

  Using interpolation:

  ```javascript
  n__('Last day', 'Last %d days', x)
  // => When x == 1: 'Last day'
  // => When x == 2: 'Last 2 days'
  ```

The `n_` and `n__` methods should only be used to fetch pluralized translations of the same
string, not to control the logic of showing different strings for different
quantities. Some languages have different quantities of target plural forms.
For example, Chinese (simplified) has only one target plural form in our
translation tool. This means the translator has to choose to translate only one
of the strings, and the translation doesn't behave as intended in the other case.

For example, use this:

```ruby
if selected_projects.one?
  selected_projects.first.name
else
  n_("Project selected", "%d projects selected", selected_projects.count)
end
```

Instead of this:

```ruby
# incorrect usage example
n_("%{project_name}", "%d projects selected", count) % { project_name: 'GitLab' }
```

### Namespaces

A namespace is a way to group translations that belong together. They provide context to our
translators by adding a prefix followed by the bar symbol (`|`). For example:

```ruby
'Namespace|Translated string'
```

A namespace:

- Addresses ambiguity in words. For example: `Promotions|Promote` vs `Epic|Promote`.
- Allows translators to focus on translating externalized strings that belong to the same product
  area, rather than arbitrary ones.
- Gives a linguistic context to help the translator.

In some cases, namespaces don't make sense. For example, for ubiquitous UI words and phrases such as
"Cancel" or phrases like "Save changes," a namespace could be counterproductive.

Namespaces should be PascalCase.

- In Ruby/HAML:

  ```ruby
  s_('OpenedNDaysAgo|Opened')
  ```

  If the translation isn't found, `Opened` is returned.

- In JavaScript:

  ```javascript
  s__('OpenedNDaysAgo|Opened')
  ```

The namespace should be removed from the translation. For more details, see the
[translation guidelines](translation.md#namespaced-strings).

### HTML

We no longer include HTML directly in the strings that are submitted for translation. This is
because:

1. The translated string can accidentally include invalid HTML.
1. Translated strings can become an attack vector for XSS, as noted by the
   [Open Web Application Security Project (OWASP)](https://owasp.org/www-community/attacks/xss/).

To include formatting in the translated string, you can do the following:

- In Ruby/HAML:

  ```ruby
    html_escape(_('Some %{strongOpen}bold%{strongClose} text.')) % { strongOpen: '<strong>'.html_safe, strongClose: '</strong>'.html_safe }

    # => 'Some <strong>bold</strong> text.'
  ```

- In JavaScript:

  ```javascript
    sprintf(__('Some %{strongOpen}bold%{strongClose} text.'), { strongOpen: '<strong>', strongClose: '</strong>'}, false);

    // => 'Some <strong>bold</strong> text.'
  ```

- In Vue:

  See the section on [interpolation](#interpolation).

When [this translation helper issue](https://gitlab.com/gitlab-org/gitlab/-/issues/217935)
is complete, we plan to update the process of including formatting in translated strings.

#### Including Angle Brackets

If a string contains angle brackets (`<`/`>`) that are not used for HTML, the `rake gettext:lint`
linter still flags it. To avoid this error, use the applicable HTML entity code (`&lt;` or `&gt;`)
instead:

- In Ruby/HAML:

   ```ruby
   html_escape_once(_('In &lt; 1 hour')).html_safe

   # => 'In < 1 hour'
   ```

- In JavaScript:

  ```javascript
  import { sanitize } from '~/lib/dompurify';

  const i18n = { LESS_THAN_ONE_HOUR: sanitize(__('In &lt; 1 hour'), { ALLOWED_TAGS: [] }) };

  // ... using the string
  element.innerHTML = i18n.LESS_THAN_ONE_HOUR;

  // => 'In < 1 hour'
  ```

- In Vue:

  ```vue
  <gl-sprintf :message="s__('In &lt; 1 hours')"/>

  // => 'In < 1 hour'
  ```

### Numbers

Different locales may use different number formats. To support localization of numbers, we use
`formatNumber`, which leverages [`toLocaleString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toLocaleString).

By default, `formatNumber` formats numbers as strings using the current user locale.

- In JavaScript:

```javascript
import { formatNumber } from '~/locale';

// Assuming "User Preferences > Language" is set to "English":

const tenThousand = formatNumber(10000); // "10,000" (uses comma as decimal symbol in English locale)
const fiftyPercent = formatNumber(0.5, { style: 'percent' }) // "50%" (other options are passed to toLocaleString)
```

- In Vue templates:

```html
<script>
import { formatNumber } from '~/locale';

export default {
  //...
  methods: {
    // ...
    formatNumber,
  },
}
</script>
<template>
<div class="my-number">
  {{ formatNumber(10000) }} <!-- 10,000 -->
</div>
<div class="my-percent">
  {{ formatNumber(0.5,  { style: 'percent' }) }} <!-- 50% -->
</div>
</template>
```

### Dates / times

- In JavaScript:

```javascript
import { createDateTimeFormat } from '~/locale';

const dateFormat = createDateTimeFormat({ year: 'numeric', month: 'long', day: 'numeric' });
console.log(dateFormat.format(new Date('2063-04-05'))) // April 5, 2063
```

This makes use of [`Intl.DateTimeFormat`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat).

- In Ruby/HAML, there are two ways of adding format to dates and times:

  - **Using the `l` helper**: for example, `l(active_session.created_at, format: :short)`. We have
    some predefined formats for [dates](https://gitlab.com/gitlab-org/gitlab/-/blob/4ab54c2233e91f60a80e5b6fa2181e6899fdcc3e/config/locales/en.yml#L54)
    and [times](https://gitlab.com/gitlab-org/gitlab/-/blob/4ab54c2233e91f60a80e5b6fa2181e6899fdcc3e/config/locales/en.yml#L262).
    If you need to add a new format, because other parts of the code could benefit from it, add it
    to the file [`en.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/locales/en.yml).
  - **Using `strftime`**: for example, `milestone.start_date.strftime('%b %-d')`. We use `strftime`
    in case none of the formats defined in [`en.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/locales/en.yml)
    match the date/time specifications we need, and if there's no need to add it as a new format
    because it's very particular (for example, it's only used in a single view).

## Best practices

### Minimize translation updates

Updates can result in the loss of the translations for this string. To minimize risks, avoid changes
to strings unless they:

- Add value for the user.
- Include extra context for translators.

For example, avoid changes like this:

```diff
- _('Number of things: %{count}') % { count: 10 }
+ n_('Number of things: %d', 10)
```

### Keep translations dynamic

There are cases when it makes sense to keep translations together within an array or a hash.

Examples:

- Mappings for a dropdown list
- Error messages

To store these kinds of data, using a constant seems like the best choice. However, this doesn't
work for translations.

For example, avoid this:

```ruby
class MyPresenter
  MY_LIST = {
    key_1: _('item 1'),
    key_2: _('item 2'),
    key_3: _('item 3')
  }
end
```

The translation method (`_`) is called when the class loads for the first time and translates the
text to the default locale. Regardless of the user's locale, these values are not translated a
second time.

A similar thing happens when using class methods with memoization.

For example, avoid this:

```ruby
class MyModel
  def self.list
    @list ||= {
      key_1: _('item 1'),
      key_2: _('item 2'),
      key_3: _('item 3')
    }
  end
end
```

This method memoizes the translations using the locale of the user who first called this method.

To avoid these problems, keep the translations dynamic.

Good:

```ruby
class MyPresenter
  def self.my_list
    {
      key_1: _('item 1'),
      key_2: _('item 2'),
      key_3: _('item 3')
    }.freeze
  end
end
```

### Splitting sentences

Never split a sentence, as it assumes the sentence's grammar and structure is the same in all
languages.

For example, this:

```javascript
{{ s__("mrWidget|Set by") }}
{{ author.name }}
{{ s__("mrWidget|to be merged automatically when the pipeline succeeds") }}
```

Should be externalized as follows:

```javascript
{{ sprintf(s__("mrWidget|Set by %{author} to be merged automatically when the pipeline succeeds"), { author: author.name }) }}
```

#### Avoid splitting sentences when adding links

This also applies when using links in between translated sentences. Otherwise, these texts are not
translatable in certain languages.

- In Ruby/HAML, instead of:

  ```haml
  - zones_link = link_to(s_('ClusterIntegration|zones'), 'https://cloud.google.com/compute/docs/regions-zones/regions-zones', target: '_blank', rel: 'noopener noreferrer')
  = s_('ClusterIntegration|Learn more about %{zones_link}').html_safe % { zones_link: zones_link }
  ```

  Set the link starting and ending HTML fragments as variables:

  ```haml
  - zones_link_url = 'https://cloud.google.com/compute/docs/regions-zones/regions-zones'
  - zones_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: zones_link_url }
  = html_escape(s_('ClusterIntegration|Learn more about %{zones_link_start}zones%{zones_link_end}')) % { zones_link_start: zones_link_start, zones_link_end: '</a>'.html_safe }
  ```

- In Vue, instead of:

  ```html
  <template>
    <div>
      <gl-sprintf :message="s__('ClusterIntegration|Learn more about %{link}')">
        <template #link>
          <gl-link
            href="https://cloud.google.com/compute/docs/regions-zones/regions-zones"
            target="_blank"
          >zones</gl-link>
        </template>
      </gl-sprintf>
    </div>
  </template>
  ```

  Set the link starting and ending HTML fragments as placeholders:

  ```html
  <template>
    <div>
      <gl-sprintf :message="s__('ClusterIntegration|Learn more about %{linkStart}zones%{linkEnd}')">
        <template #link="{ content }">
          <gl-link
            href="https://cloud.google.com/compute/docs/regions-zones/regions-zones"
            target="_blank"
          >{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
  </template>
  ```

- In JavaScript (when Vue cannot be used), instead of:

  ```javascript
  {{
      sprintf(s__("ClusterIntegration|Learn more about %{link}"), {
          link: '<a href="https://cloud.google.com/compute/docs/regions-zones/regions-zones" target="_blank" rel="noopener noreferrer">zones</a>'
      }, false)
  }}
  ```

  Set the link starting and ending HTML fragments as placeholders:

  ```javascript
  {{
      sprintf(s__("ClusterIntegration|Learn more about %{linkStart}zones%{linkEnd}"), {
          linkStart: '<a href="https://cloud.google.com/compute/docs/regions-zones/regions-zones" target="_blank" rel="noopener noreferrer">',
          linkEnd: '</a>',
      }, false)
  }}
  ```

The reasoning behind this is that in some languages words change depending on context. For example,
in Japanese は is added to the subject of a sentence and を to the object. This is impossible to
translate correctly if you extract individual words from the sentence.

When in doubt, try to follow the best practices described in this [Mozilla Developer documentation](https://developer.mozilla.org/en-US/docs/Mozilla/Localization/Localization_content_best_practices#Splitting).

## Updating the PO files with the new content

Now that the new content is marked for translation, run this command to update the
`locale/gitlab.pot` files:

```shell
bin/rake gettext:regenerate
```

This command updates the `locale/gitlab.pot` file with the newly externalized strings and removes
any unused strings. Once the changes are on the default branch, [CrowdIn](https://translate.gitlab.com)
picks them up and presents them for translation.

You don't need to check in any changes to the `locale/[language]/gitlab.po` files. They are updated
automatically when [translations from CrowdIn are merged](merging_translations.md).

If there are merge conflicts in the `gitlab.pot` file, you can delete the file and regenerate it
using the same command.

### Validating PO files

To make sure we keep our translation files up to date, there's a linter that runs on CI as part of
the `static-analysis` job. To lint the adjustments in PO files locally, you can run
`rake gettext:lint`.

The linter takes the following into account:

- Valid PO-file syntax.
- Variable usage.
  - Only one unnamed (`%d`) variable, since the order of variables might change in different
    languages.
  - All variables used in the message ID are used in the translation.
  - There should be no variables used in a translation that aren't in the message ID.
- Errors during translation.
- Presence of angle brackets (`<` or `>`).

The errors are grouped per file, and per message ID:

```plaintext
Errors in `locale/zh_HK/gitlab.po`:
  PO-syntax errors
    SimplePoParser::ParserErrorSyntax error in lines
    Syntax error in msgctxt
    Syntax error in msgid
    Syntax error in msgstr
    Syntax error in message_line
    There should be only whitespace until the end of line after the double quote character of a message text.
    Parsing result before error: '{:msgid=>["", "You are going to delete %{project_name_with_namespace}.\\n", "Deleted projects CANNOT be restored!\\n", "Are you ABSOLUTELY sure?"]}'
    SimplePoParser filtered backtrace: SimplePoParser::ParserError
Errors in `locale/zh_TW/gitlab.po`:
  1 pipeline
    <%d 條流水線> is using unknown variables: [%d]
    Failure translating to zh_TW with []: too few arguments
```

In this output, `locale/zh_HK/gitlab.po` has syntax errors. The file `locale/zh_TW/gitlab.po` has
variables in the translation that aren't in the message with ID `1 pipeline`.

## Adding a new language

A new language should only be added as an option in User Preferences once at least 10% of the
strings have been translated and approved. Even though a larger number of strings may have been
translated, only the approved translations display in the GitLab UI.

NOTE:
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221012) in GitLab 13.3:
Languages with less than 2% of translations are not available in the UI.

Suppose you want to add translations for a new language, for example, French:

1. Register the new language in `lib/gitlab/i18n.rb`:

   ```ruby
   ...
   AVAILABLE_LANGUAGES = {
     ...,
     'fr' => 'Français'
   }.freeze
   ...
   ```

1. Add the language:

   ```shell
   bin/rake gettext:add_language[fr]
   ```

   If you want to add a new language for a specific region, the command is similar. You must
   separate the region with an underscore (`_`), specify the region in capital letters. For example:

   ```shell
   bin/rake gettext:add_language[en_GB]
   ```

1. Adding the language also creates a new directory at the path `locale/fr/`. You can now start
   using your PO editor to edit the PO file located at `locale/fr/gitlab.edit.po`.

1. After updating the translations, you must process the PO files to generate the binary MO files,
   and update the JSON files containing the translations:

   ```shell
   bin/rake gettext:compile
   ```

1. To see the translated content, you must change your preferred language. You can find this under
   the user's **Settings** (`/profile`).

1. After checking that the changes are ok, commit the new files. For example:

   ```shell
   git add locale/fr/ app/assets/javascripts/locale/fr/
   git commit -m "Add French translations for Value Stream Analytics page"
   ```
