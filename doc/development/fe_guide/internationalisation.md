# Frontend internationalisation guide

The library used for handling translations is [gettext][gettext_i18n_rails]. This includes the
Javascript version [gettext JS][gettext_i18n_rails_js]. For JavaScript we use the
[Jed][jed] library to handle translations.

## Methods

### HAML & Ruby

When working with the translations in HAML files you can use the methods provided with fast_gettext.
Check their [documentation][fast_gettext] for more information.

```ruby
# Translates 'Car'
_('Car')

# Translates 'car' within 'Namepspace'
s_('Namespace|car')

# Translates 'Days' if count is more 1
# else it will use 'Day'
n_('Day', 'Days', 3)
```

### JavaScript

For JavaScript, you need to include the locale library. This automatically includes all the
translations and sets up [Jed][jed] to be used with the current locale.

```javascript
import locale from './locale';
```

For convenience, the locale library exports the same method names as above. However, instead of 1
underscore, they use 2 underscores so not to conflict with the Underscore library. These can be
imported directly from the `locale` file. These methods can then be used in the same way as above.

```javascript
import {
  __,
  n__,
  s__,
} from './locale';
```

If required, you can also get access to the currently used language by importing that as well.

```javascript
import { lang } from './locale';
```

### Vue

To use these translation methods inside Vue you need to import and install the Vue plugin that sets
up the Vue instance correctly.

```javascript
import Vue from 'vue';
import Translate from './vue_shared/translate';

Vue.use(Translate);
```

Like our JavaScript you can then use the exact same method names.

```vue
{{ __('Car') }}
{{ n__('Day', 'Days', 3) }}
{{ s__('Namespace|car') }}
```

Both of our JavaScript and Vue can automatically include the number when using the `n__()` method.
This is as simple as including the `%d` pointer in both strings. The JavaScript will then
automatically replace this the number passed in.

```vue
{{ n__('%d day', '%d days', 3) }} // 3 days
```

## Commands

To find and collect translations into `.po` files run the below command. This will make
[gettext][gettext_i18n_rails] go through all `rb`, `haml`, `js` and `vue`. It will search for
translations that use the methods mentioned above.

```shell
bundle exec rake gettext:find
```

After running this command, you also need to run the below command to compile this `.po` file into
the correct format for our JavaScript to use.

```shell
bundle exec rake gettext:po_to_json
```

[gettext_i18n_rails]: https://github.com/grosser/gettext_i18n_rails
[gettext_i18n_rails_js]: https://github.com/webhippie/gettext_i18n_rails_js
[jed]: http://messageformat.github.io/Jed/
[fast_gettext]: https://github.com/grosser/fast_gettext
