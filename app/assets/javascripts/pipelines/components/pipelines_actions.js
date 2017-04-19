/* eslint-disable no-new */
/* global Flash */
import '~/flash';
import playIconSvg from 'icons/_icon_play.svg';
import eventHub from '../event_hub';

export default {
  props: {
    actions: {
      type: Array,
      required: true,
    },

    service: {
      type: Object,
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

      this.service.postAction(endpoint)
      .then(() => {
        this.isLoading = false;
        eventHub.$emit('refreshPipelines');
      })
      .catch(() => {
        this.isLoading = false;
        new Flash('An error occured while making the request.');
      });
    },

    isActionDisabled(action) {
      if (action.playable === undefined) {
        return false;
      }

      return !action.playable;
    },
  },

  template: `
    <div class="btn-group" v-if="actions">
      <button
        type="button"
        class="dropdown-toggle btn btn-default has-tooltip js-pipeline-dropdown-manual-actions"
        title="Manual job"
        data-toggle="dropdown"
        data-placement="top"
        aria-label="Manual job"
        :disabled="isLoading">
        ${playIconSvg}
        <i
          class="fa fa-caret-down"
          aria-hidden="true" />
        <i
          v-if="isLoading"
          class="fa fa-spinner fa-spin"
          aria-hidden="true" />
      </button>

      <ul class="dropdown-menu dropdown-menu-align-right">
        <li v-for="action in actions">
          <button
            type="button"
            class="js-pipeline-action-link no-btn btn"
            @click="onClickAction(action.path)"
            :class="{ 'disabled': isActionDisabled(action) }"
            :disabled="isActionDisabled(action)">
            ${playIconSvg}
            <span>{{action.name}}</span>
          </button>
        </li>
      </ul>
    </div>
  `,
};
