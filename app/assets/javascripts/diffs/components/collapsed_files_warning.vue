<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { mapState } from 'vuex';

import { CENTERED_LIMITED_CONTAINER_CLASSES, EVT_EXPAND_ALL_FILES } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  props: {
    limited: {
      type: Boolean,
      required: false,
      default: false,
    },
    dismissed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDismissed: this.dismissed,
    };
  },
  computed: {
    ...mapState('diffs', ['diffFiles']),
    containerClasses() {
      return {
        [CENTERED_LIMITED_CONTAINER_CLASSES]: this.limited,
      };
    },
    shouldDisplay() {
      return !this.isDismissed && this.diffFiles.length > 1;
    },
  },

  methods: {
    dismiss() {
      this.isDismissed = true;
      this.$emit('dismiss');
    },
    expand() {
      eventHub.$emit(EVT_EXPAND_ALL_FILES);
      this.dismiss();
    },
  },
};
</script>

<template>
  <div v-if="shouldDisplay" data-testid="root" :class="containerClasses" class="col-12">
    <gl-alert
      :dismissible="true"
      :title="__('Some changes are not shown')"
      variant="warning"
      class="gl-mb-5"
      @dismiss="dismiss"
    >
      <p class="gl-mb-0">
        {{ __('For a faster browsing experience, some files are collapsed by default.') }}
      </p>
      <template #actions>
        <gl-button category="secondary" variant="warning" class="gl-alert-action" @click="expand">
          {{ __('Expand all files') }}
        </gl-button>
      </template>
    </gl-alert>
  </div>
</template>
