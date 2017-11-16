<script>
import eventHub from '../event_hub';
import tooltip from '../../../vue_shared/directives/tooltip';

export default {
  name: 'IssueToken',
  data() {
    return {
      removeDisabled: false,
    };
  },
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
    isCondensed: {
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
      return `Remove ${this.displayReference}`;
    },
    hasState() {
      return this.state && this.state.length > 0;
    },
    stateTitle() {
      if (this.isCondensed) return '';

      return this.isOpen ? 'Open' : 'Closed';
    },
    isOpen() {
      return this.state === 'opened';
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
    innerComponentType() {
      return this.isCondensed ? 'span' : 'div';
    },
    issueTitle() {
      return this.isCondensed ? this.title : '';
    },
  },

  methods: {
    onRemoveRequest() {
      let namespacePrefix = '';
      if (this.eventNamespace && this.eventNamespace.length > 0) {
        namespacePrefix = `${this.eventNamespace}-`;
      }

      eventHub.$emit(`${namespacePrefix}removeRequest`, this.idKey);

      this.removeDisabled = true;
    },
  },
};
</script>

<template>
  <div :class="{
    'issue-token': isCondensed,
    'flex-row issue-info-container': !isCondensed,
  }">
    <component
      v-tooltip
      :is="this.computedLinkElementType"
      ref="link"
      :class="{
        'issue-token-link': isCondensed,
        'issue-main-info': !isCondensed,
      }"
      :href="computedPath"
      :title="issueTitle"
      data-placement="top"
    >
      <component
        :is="innerComponentType"
        v-if="hasTitle"
        ref="title"
        class="js-issue-token-title"
        :class="{
          'issue-token-title issue-token-end': isCondensed,
          'issue-title block-truncated': !isCondensed,
          'issue-token-title-standalone': !canRemove
        }">
        <span class="issue-token-title-text">
          {{ title }}
        </span>
      </component>
      <component
        :is="innerComponentType"
        ref="reference"
        :class="{
          'issue-token-reference': isCondensed,
          'issuable-info': !isCondensed,
        }">
        <i
          ref="stateIcon"
          v-if="hasState"
          v-tooltip
          class="fa"
          :class="{
            'issue-token-state-icon-open fa-circle-o': isOpen,
            'issue-token-state-icon-closed fa-minus': isClosed,
          }"
          :title="stateTitle"
          :aria-label="state"
        >
        </i>{{ displayReference }}
      </component>
    </component>
    <button
      v-if="canRemove"
      v-tooltip
      ref="removeButton"
      type="button"
      class="js-issue-token-remove-button"
      :class="{
        'issue-token-remove-button': isCondensed,
        'btn btn-default': !isCondensed
      }"
      :title="removeButtonLabel"
      :aria-label="removeButtonLabel"
      :disabled="removeDisabled"
      @click="onRemoveRequest"
    >
      <i
        class="fa fa-times"
        aria-hidden="true">
      </i>
    </button>
  </div>
</template>
