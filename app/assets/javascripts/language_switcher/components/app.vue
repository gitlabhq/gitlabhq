<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { setCookie } from '~/lib/utils/common_utils';
import { PREFERRED_LANGUAGE_COOKIE_KEY } from '../constants';

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: {
    locales: {
      default: [],
    },
    preferredLocale: {
      default: {},
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
};
</script>
<template>
  <gl-collapsible-listbox
    v-model="selected"
    :toggle-text="preferredLocale.text"
    :items="locales"
    category="tertiary"
    right
    icon="earth"
    size="small"
    toggle-class="py-0 gl-h-6"
    @select="onLanguageSelected"
  >
    <template #list-item="{ item: locale }">
      <span
        :data-testid="itemTestSelector(locale.value)"
        :data-qa-selector="itemTestSelector(locale.value)"
      >
        {{ locale.text }}
      </span>
    </template>
  </gl-collapsible-listbox>
</template>
