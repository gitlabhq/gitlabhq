<script>
import eventHub from '../event_hub';
import tooltip from '../../../vue_shared/directives/tooltip';

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

  directives: {
    tooltip,
  },

  computed: {
    removeButtonLabel() {
      return `Remove related issue ${this.displayReference}`;
    },
    hasState() {
      return this.state && this.state.length > 0;
    },
    isOpen() {
      return this.state === 'opened' || this.state === 'reopened';
    },
    isClosed() {
      return this.state === 'closed';
    },
    hasTitle() {
      return this.title.length > 0;
    },
    computedLinkElementType() {
      return this.path.length > 0 ? 'a' : 'span';
    },
    computedPath() {
      return this.path.length ? this.path : null;
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
};
</script>

<template>
  <div class="issue-token">
    <component
      v-tooltip
      :is="this.computedLinkElementType"
      ref="link"
      class="issue-token-link"
      :href="computedPath"
      :title="title"
      data-placement="top">
      <span
        ref="reference"
        class="issue-token-reference">
        <i
          ref="stateIcon"
          v-if="hasState"
          class="fa"
          :class="{
            'issue-token-state-icon-open fa-circle-o': isOpen,
            'issue-token-state-icon-closed fa-minus': isClosed,
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
    </component>
    <button
      v-if="canRemove"
      ref="removeButton"
      type="button"
      class="js-issue-token-remove-button issue-token-remove-button"
      :aria-label="removeButtonLabel"
      @click="onRemoveRequest">
      <i
        class="fa fa-times"
        aria-hidden="true">
      </i>
    </button>
  </div>
</template>
