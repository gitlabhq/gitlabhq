<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

// TODO: To be replaced with <template> content in https://gitlab.com/gitlab-org/gitlab/-/issues/320922
const messageHtml = `
  <p>${s__('AdminUsers|Blocking user has the following effects:')}</p>
  <ul>
    <li>${s__('AdminUsers|User will not be able to login')}</li>
    <li>${s__('AdminUsers|User will not be able to access git repositories')}</li>
    <li>${s__('AdminUsers|Personal projects will be left')}</li>
    <li>${s__('AdminUsers|Owned groups will be left')}</li>
  </ul>
`;

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
          title: sprintf(s__('AdminUsers|Block user %{username}?'), { username: this.username }),
          okVariant: 'confirm',
          okTitle: s__('AdminUsers|Block'),
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
