<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import safeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'DiffFileOptionsMenuItem',
  components: {
    GlDisclosureDropdownItem,
  },
  directives: {
    safeHtml,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item :item="item">
    <template #list-item>
      <!--
        https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212514#note_2887937008

        If performance becomes an issue as a result of DOM-sanitizing all menu items,
        we should be able to switch to `v-html` and depend on back end sanitization.
      -->
      <span v-safe-html="item.text"></span>
    </template>
  </gl-disclosure-dropdown-item>
</template>
