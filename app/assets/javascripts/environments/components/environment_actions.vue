<script>
import playIconSvg from 'icons/_icon_play.svg';
import eventHub from '../event_hub';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  props: {
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  components: {
    loadingIcon,
  },

  data() {
    return {
      playIconSvg,
      isLoading: false,
    };
  },

  computed: {
    title() {
      return 'Deploy to...';
    },
  },

  methods: {
    onClickAction(endpoint) {
      this.isLoading = true;

      $(this.$refs.tooltip).tooltip('destroy');
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
  <div
    class="btn-group"
    role="group">
    <button
      type="button"
      class="dropdown btn btn-default dropdown-new js-dropdown-play-icon-container has-tooltip"
      data-container="body"
      data-toggle="dropdown"
      ref="tooltip"
      :title="title"
      :aria-label="title"
      :disabled="isLoading">
      <span>
        <span v-html="playIconSvg"></span>
        <i
          class="fa fa-caret-down"
          aria-hidden="true"/>
        <loading-icon v-if="isLoading" />
      </span>
    </button>

    <ul class="dropdown-menu dropdown-menu-align-right">
      <li v-for="action in actions">
        <button
          type="button"
          class="js-manual-action-link no-btn btn"
          @click="onClickAction(action.play_path)"
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)">
          <span v-html="playIconSvg"></span>
          <span>
            {{action.name}}
          </span>
        </button>
      </li>
    </ul>
  </div>
</template>
