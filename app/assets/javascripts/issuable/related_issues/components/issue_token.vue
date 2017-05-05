<script>
import eventHub from '../event_hub';
import {
  FETCHING_STATUS,
  FETCH_SUCCESS_STATUS,
  FETCH_ERROR_STATUS,
} from '../constants';

export default {
  name: 'IssueToken',

  props: {
    reference: {
      type: String,
      required: true,
    },
    displayReference: {
      type: String,
      required: true,
    },
    eventNamespace: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    path: {
      type: String,
      required: false,
      default: '',
    },
    state: {
      type: String,
      required: false,
      default: '',
    },
    fetchStatus: {
      type: String,
      required: false,
      default: FETCH_SUCCESS_STATUS,
    },
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    isFetching() {
      return this.fetchStatus === FETCHING_STATUS;
    },
    hasFetchingError() {
      return this.fetchStatus === FETCH_ERROR_STATUS;
    },
    removeButtonLabel() {
      return `Remove related issue ${this.reference}`;
    },
    hasState() {
      return this.state && this.state.length > 0;
    },
    hasTitle() {
      return this.title.length > 0 || this.isFetching;
    }
  },

  methods: {
    onRemoveRequest() {
      let namespacePrefix = '';
      if (this.eventNamespace && this.eventNamespace.length > 0) {
        namespacePrefix = `${this.eventNamespace}-`;
      }

      eventHub.$emit(`${namespacePrefix}removeRequest`, this.reference);
    },
  },
  updated() {
    const removeButton = this.$refs.removeButton;
    if (removeButton) {
      $(this.$refs.removeButton).tooltip('fixTitle');
    }
  },
};
</script>

<template>
  <div
    class="issue-token"
    :class="{ 'issue-token-error': hasFetchingError }">
    <a
      ref="link"
      class="issue-token-link"
      :href="path">
      <span
        ref="reference"
        class="issue-token-reference">
        <i
          ref="stateIcon"
          v-if="hasState"
          class="fa"
          :class="{
            'issue-token-state-icon-open fa-circle-o': state === 'opened',
            'issue-token-state-icon-closed fa-minus': state === 'closed',
          }"
          :aria-label="state">
        </i>
        {{ displayReference }}
      </span>
      <span
        v-if="hasTitle"
        ref="title"
        class="issue-token-title">
        <i
          ref="fetchStatusIcon"
          v-if="isFetching"
          class="fa fa-spinner fa-spin"
          aria-label="Fetching info">
        </i>
        {{ title }}
      </span>
    </a>
    <button
      ref="removeButton"
      v-if="canRemove"
      type="button"
      class="issue-token-remove-button"
      :class="{ 'issue-token-remove-button-standalone': !hasTitle }"
      :title="removeButtonLabel"
      data-toggle="tooltip"
      @click="onRemoveRequest">
      <i
        class="fa fa-times"
        aria-hidden="true">
      </i>
    </button>
  </div>
</template>
