<script>
import { GlListbox } from '@gitlab/ui';
import { setCookie } from '~/lib/utils/common_utils';
import { PREFERRED_LANGUAGE_COOKIE_KEY } from '../constants';

export default {
  components: {
    GlListbox,
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
  },
};
</script>
<template>
  <gl-listbox
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
      <span :data-testid="`language_switcher_lang_${locale.value}`">
        {{ locale.text }}
      </span>
    </template>
  </gl-listbox>
</template>
