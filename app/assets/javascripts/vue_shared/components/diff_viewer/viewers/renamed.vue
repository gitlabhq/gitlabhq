<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';

import {
  TRANSITION_LOAD_START,
  TRANSITION_LOAD_ERROR,
  TRANSITION_LOAD_SUCCEED,
  TRANSITION_ACKNOWLEDGE_ERROR,
  STATE_IDLING,
  STATE_LOADING,
  STATE_ERRORED,
} from '~/diffs/constants';
import { truncateSha } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import { transition } from '../utils';

export default {
  STATE_LOADING,
  STATE_ERRORED,
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
    is(state) {
      return this.state === state;
    },
    switchToFull() {
      this.transitionState(TRANSITION_LOAD_START);

      this.switchToFullDiffFromRenamedFile({ diffFile: this.diffFile })
        .then(() => {
          this.transitionState(TRANSITION_LOAD_SUCCEED);
        })
        .catch(() => {
          this.transitionState(TRANSITION_LOAD_ERROR);
        });
    },
    transitionState(transitionEvent) {
      this.state = transition(this.state, transitionEvent);
    },
    clickLink(event) {
      if (this.canLoadFullDiff) {
        event.preventDefault();

        this.switchToFull();
      }
    },
    dismissError() {
      this.transitionState(TRANSITION_ACKNOWLEDGE_ERROR);
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
