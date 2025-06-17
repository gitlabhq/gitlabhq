<script>
import { s__ } from '~/locale';
import ActionButtons from '../action_buttons.vue';
import MergeChecksMessage from './message.vue';

export default {
  name: 'MergeChecksTitleRegex',
  components: {
    MergeChecksMessage,
    ActionButtons,
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
  },
  computed: {
    mrEditPath() {
      let { pathname } = document.location;

      pathname = pathname.replace(/\/$/, '');

      return `${pathname}/edit`;
    },
    tertiaryActionsButtons() {
      return [
        {
          text: s__('mrWidget|Edit merge request'),
          category: 'default',
          href: this.mrEditPath,
        },
      ];
    },
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template #failed>
      <action-buttons :tertiary-buttons="tertiaryActionsButtons" />
    </template>
  </merge-checks-message>
</template>
