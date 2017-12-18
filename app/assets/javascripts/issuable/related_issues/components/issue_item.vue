<script>
import eventHub from '../event_hub';
import tooltip from '../../../vue_shared/directives/tooltip';

export default {
  name: 'IssueItem',
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
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  directives: {
    tooltip,
  },

  computed: {
    hasState() {
      return this.state && this.state.length > 0;
    },
    stateTitle() {
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
  <div
    class="flex"
    :class="{ 'issue-info-container': !canReorder }"
  >
    <div class="block-truncated append-right-10">
      <a
        class="issue-token-title-text sortable-link"
        :href="computedPath"
      >
        {{ title }}
      </a>
      <div class="block text-secondary">
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
      </div>
    </div>
    <button
      v-if="canRemove"
      v-tooltip
      ref="removeButton"
      type="button"
      class="btn btn-default js-issue-token-remove-button flex-align-self-center flex-right"
      title="Remove"
      aria-label="Remove"
      :disabled="removeDisabled"
      @click="onRemoveRequest"
    >
      <i
        class="fa fa-times"
        aria-hidden="true"
      >
      </i>
    </button>
  </div>
</template>
