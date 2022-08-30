<script>
import StatusIcon from './mr_widget_status_icon.vue';
import Actions from './action_buttons.vue';

export default {
  components: {
    StatusIcon,
    Actions,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <div v-if="isLoading" class="gl-w-full mr-conflict-loader">
      <slot name="loading"></slot>
    </div>
    <template v-else>
      <slot name="icon">
        <status-icon :status="status" />
      </slot>
      <div
        :class="{ 'gl-display-flex': actions.length, 'gl-md-display-flex': !actions.length }"
        class="media-body"
      >
        <slot></slot>
        <div
          :class="{ 'gl-flex-direction-column-reverse': !actions.length }"
          class="gl-display-flex gl-md-display-block gl-font-size-0 gl-ml-auto"
        >
          <slot name="actions">
            <actions v-if="actions.length" :tertiary-buttons="actions" />
          </slot>
        </div>
      </div>
    </template>
  </div>
</template>
