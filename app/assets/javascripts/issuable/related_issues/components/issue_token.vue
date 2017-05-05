<script>
import eventHub from '../event_hub';

export default {
  name: 'IssueToken',

  props: {
    idKey: {
      type: Number,
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
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    removeButtonLabel() {
      return `Remove related issue ${this.displayReference}`;
    },
    hasState() {
      return this.state && this.state.length > 0;
    },
    hasTitle() {
      return this.title.length > 0;
    },
  },

  methods: {
    onRemoveRequest() {
      let namespacePrefix = '';
      if (this.eventNamespace && this.eventNamespace.length > 0) {
        namespacePrefix = `${this.eventNamespace}-`;
      }

      eventHub.$emit(`${namespacePrefix}removeRequest`, this.idKey);
    },
  },
  updated() {
    const link = this.$refs.link;
    const removeButton = this.$refs.removeButton;

    if (link) {
      $(link).tooltip('fixTitle');
    }

    if (removeButton) {
      $(removeButton).tooltip('fixTitle');
    }
  },
};
</script>

<template>
  <div class="issue-token">
    <a
      ref="link"
      class="issue-token-link"
      :href="path"
      :title="title"
      data-toggle="tooltip"
      data-placement="top">
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
        class="js-issue-token-title issue-token-title"
        :class="{ 'issue-token-title-standalone': !canRemove }">
        <span class="issue-token-title-text">
          {{ title }}
        </span>
      </span>
    </a>
    <button
      ref="removeButton"
      v-if="canRemove"
      type="button"
      class="js-issue-token-remove-button issue-token-remove-button"
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
