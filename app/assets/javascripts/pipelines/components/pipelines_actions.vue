<script>
  import playIconSvg from 'icons/_icon_play.svg';
  import eventHub from '../event_hub';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    components: {
      loadingIcon,
    },
    props: {
      actions: {
        type: Array,
        required: true,
      },
    },
    data() {
      return {
        playIconSvg,
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
      type="button"
      class="dropdown-new btn btn-default js-pipeline-dropdown-manual-actions"
      title="Manual job"
      data-toggle="dropdown"
      data-placement="top"
      aria-label="Manual job"
      :disabled="isLoading"
    >
      <span v-html="playIconSvg"></span>
      <i
        class="fa fa-caret-down"
        aria-hidden="true">
      </i>
      <loading-icon v-if="isLoading" />
    </button>

    <ul class="dropdown-menu dropdown-menu-align-right">
      <li
        v-for="(action, i) in actions"
        :key="i"
      >
        <button
          type="button"
          class="js-pipeline-action-link no-btn btn"
          @click="onClickAction(action.path)"
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)"
        >
          {{ action.name }}
        </button>
      </li>
    </ul>
  </div>
</template>
