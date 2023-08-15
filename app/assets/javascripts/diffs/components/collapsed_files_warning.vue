<script>
import { GlAlert, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';

import { EVT_EXPAND_ALL_FILES } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  props: {
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
  <div v-if="shouldDisplay" data-testid="root" class="col-12">
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
        <gl-button class="gl-alert-action" @click="expand">
          {{ __('Expand all files') }}
        </gl-button>
      </template>
    </gl-alert>
  </div>
</template>
