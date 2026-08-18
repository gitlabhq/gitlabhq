<script>
import { GlLink, GlAlert } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'MRWidgetAlertMessage',
  components: {
    GlAlert,
    GlLink,
  },
  mixins: [glSlotsMixin],
  props: {
    type: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: undefined,
    },
    dismissible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDismissed: false,
    };
  },
  methods: {
    onDismiss() {
      this.isDismissed = true;
    },
  },
};
</script>

<template>
  <gl-alert v-if="!isDismissed" :variant="type" :dismissible="dismissible" @dismiss="onDismiss">
    <slot></slot>
    <gl-link v-if="helpPath" :href="helpPath" target="_blank" class="gl-label-link">
      <template v-if="glSlots()['link-content']" #default
        ><slot name="link-content"></slot
      ></template>
    </gl-link>
  </gl-alert>
</template>
