<script>
import eventHub from '../event_hub';
import icon from '../../vue_shared/components/icon.vue';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  components: {
    icon,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    onClickAction(endpoint) {
      this.isLoading = true;

      eventHub.$emit('postAction', endpoint);
    },

    isActionDisabled(action) {
      if (action.playable === undefined) {
        return false;
      }

      return !action.playable;
    },
  },
};
</script>
<template>
  <div class="btn-group">
    <button
      v-tooltip
      :disabled="isLoading"
      type="button"
      class="dropdown-new btn btn-default js-pipeline-dropdown-manual-actions"
      title="Manual job"
      data-toggle="dropdown"
      data-placement="top"
      aria-label="Manual job"
    >
      <icon
        name="play"
        class="icon-play"
      />
      <i
        class="fa fa-caret-down"
        aria-hidden="true">
      </i>
      <gl-loading-icon v-if="isLoading" />
    </button>

    <ul class="dropdown-menu dropdown-menu-right">
      <li
        v-for="(action, i) in actions"
        :key="i"
      >
        <button
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)"
          type="button"
          class="js-pipeline-action-link no-btn btn"
          @click="onClickAction(action.path)"
        >
          {{ action.name }}
        </button>
      </li>
    </ul>
  </div>
</template>
