<script>
import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { setCookie } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { PREFERRED_LANGUAGE_COOKIE_KEY, EN } from '../constants';

const HELP_TRANSLATE_MSG = __('Help translate to your language');
const HELP_TRANSLATE_HREF = helpPagePath('/development/i18n/translation.md');

export default {
  components: {
    GlCollapsibleListbox,
    GlLink,
  },
  inject: {
    locales: {
      default: [],
    },
    preferredLocale: {
      default: EN,
    },
  },
  data() {
    return {
      selected: this.preferredLocale.value,
    };
  },
  methods: {
    onLanguageSelected(code) {
      setCookie(PREFERRED_LANGUAGE_COOKIE_KEY, code);
      window.location.reload();
    },
    itemTestSelector(locale) {
      return `language_switcher_lang_${locale}`;
    },
  },
  HELP_TRANSLATE_MSG,
  HELP_TRANSLATE_HREF,
};
</script>
<template>
  <gl-collapsible-listbox
    v-model="selected"
    :toggle-text="preferredLocale.text"
    :items="locales"
    category="tertiary"
    placement="bottom-end"
    icon="earth"
    size="small"
    toggle-class="py-0 gl-h-6"
    @select="onLanguageSelected"
  >
    <template #list-item="{ item: locale }">
      <span :data-testid="itemTestSelector(locale.value)">
        {{ locale.text }}
      </span>
    </template>
    <template #footer>
      <div
        class="gl-flex gl-justify-center gl-border-t-1 gl-border-t-default gl-p-3 gl-border-t-solid"
        data-testid="footer"
      >
        <gl-link :href="$options.HELP_TRANSLATE_HREF">{{ $options.HELP_TRANSLATE_MSG }}</gl-link>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
