<script>
import Icon from '~/vue_shared/components/icon.vue';
import popover from '~/vue_shared/directives/popover';

export default {
  name: 'SecurityReportsHelpPopover',
  components: {
    Icon,
  },
  directives: {
    popover,
  },
  props: {
    options: {
      type: Object,
      required: true,
    },
  },
  computed: {
    popoverOptions() {
      return {
        html: true,
        trigger: 'focus',
        placement: 'top',
        template:
          '<div class="popover" role="tooltip"><div class="arrow"></div><p class="popover-title"></p><div class="popover-content"></div></div>',
        ...this.options,
      };
    },
  },
};
</script>
<template>
  <button
    type="button"
    class="btn-transparent btn-blank"
    v-popover="popoverOptions"
    tabindex="0"
  >
    <icon name="question" />
  </button>
</template>
