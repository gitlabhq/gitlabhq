<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `<p>${s__(
  'AdminUsers|You can ban their account in the future if necessary.',
)}</p>`;

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalAttributes() {
      return {
        'data-path': this.path,
        'data-method': 'put',
        'data-modal-attributes': JSON.stringify({
          title: sprintf(s__('AdminUsers|Unban user %{username}?'), {
            username: this.username,
          }),
          okVariant: 'info',
          okTitle: s__('AdminUsers|Unban user'),
          messageHtml,
        }),
      };
    },
  },
};
</script>

<template>
  <div class="js-confirm-modal-button" v-bind="{ ...modalAttributes }">
    <gl-dropdown-item>
      <slot></slot>
    </gl-dropdown-item>
  </div>
</template>
