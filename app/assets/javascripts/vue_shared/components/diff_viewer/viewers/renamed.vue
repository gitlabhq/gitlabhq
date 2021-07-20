<script>
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { mapActions } from 'vuex';

import {
  TRANSITION_LOAD_START,
  TRANSITION_LOAD_ERROR,
  TRANSITION_LOAD_SUCCEED,
  TRANSITION_ACKNOWLEDGE_ERROR,
  STATE_IDLING,
  STATE_LOADING,
  STATE_ERRORED,
  RENAMED_DIFF_TRANSITIONS,
} from '~/diffs/constants';
import { truncateSha } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

export default {
  STATE_LOADING,
  STATE_ERRORED,
  TRANSITIONS: RENAMED_DIFF_TRANSITIONS,
  uiText: {
    showLink: __('Show file contents'),
    commitLink: __('View file @ %{commitSha}'),
    description: __('File renamed with no changes.'),
    loadError: __('Unable to load file contents. Try again later.'),
  },
  components: {
    GlAlert,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: STATE_IDLING,
    };
  },
  computed: {
    shortSha() {
      return truncateSha(this.diffFile.content_sha);
    },
    canLoadFullDiff() {
      return this.diffFile.alternate_viewer.name === 'text';
    },
  },
  methods: {
    ...mapActions('diffs', ['switchToFullDiffFromRenamedFile']),
    transition(transitionEvent) {
      const key = `${this.state}:${transitionEvent}`;

      if (this.$options.TRANSITIONS[key]) {
        this.state = this.$options.TRANSITIONS[key];
      }
    },
    is(state) {
      return this.state === state;
    },
    switchToFull() {
      this.transition(TRANSITION_LOAD_START);

      this.switchToFullDiffFromRenamedFile({ diffFile: this.diffFile })
        .then(() => {
          this.transition(TRANSITION_LOAD_SUCCEED);
        })
        .catch(() => {
          this.transition(TRANSITION_LOAD_ERROR);
        });
    },
    clickLink(event) {
      if (this.canLoadFullDiff) {
        event.preventDefault();

        this.switchToFull();
      }
    },
    dismissError() {
      this.transition(TRANSITION_ACKNOWLEDGE_ERROR);
    },
  },
};
</script>

<template>
  <div class="nothing-here-block">
    <gl-loading-icon v-if="is($options.STATE_LOADING)" size="sm" />
    <template v-else>
      <gl-alert
        v-show="is($options.STATE_ERRORED)"
        class="gl-mb-5 gl-text-left"
        variant="danger"
        @dismiss="dismissError"
        >{{ $options.uiText.loadError }}</gl-alert
      >
      <span test-id="plaintext">{{ $options.uiText.description }}</span>
      <gl-link :href="diffFile.view_path" @click="clickLink">
        <span v-if="canLoadFullDiff">{{ $options.uiText.showLink }}</span>
        <gl-sprintf v-else :message="$options.uiText.commitLink">
          <template #commitSha>{{ shortSha }}</template>
        </gl-sprintf>
      </gl-link>
    </template>
  </div>
</template>
