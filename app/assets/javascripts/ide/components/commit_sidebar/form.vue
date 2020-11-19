<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlModal, GlSafeHtmlDirective, GlButton } from '@gitlab/ui';
import { n__, __ } from '~/locale';
import CommitMessageField from './message_field.vue';
import Actions from './actions.vue';
import SuccessMessage from './success_message.vue';
import { leftSidebarViews, MAX_WINDOW_HEIGHT_COMPACT } from '../../constants';
import { createUnexpectedCommitError } from '../../lib/errors';

export default {
  components: {
    Actions,
    CommitMessageField,
    SuccessMessage,
    GlModal,
    GlButton,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  data() {
    return {
      isCompact: true,
      componentHeight: null,
      // Keep track of "lastCommitError" so we hold onto the value even when "commitError" is cleared.
      lastCommitError: createUnexpectedCommitError(),
    };
  },
  computed: {
    ...mapState(['changedFiles', 'stagedFiles', 'currentActivityView', 'lastCommitMsg']),
    ...mapState('commit', ['commitMessage', 'submitCommitLoading', 'commitError']),
    ...mapGetters(['someUncommittedChanges']),
    ...mapGetters('commit', ['discardDraftButtonDisabled', 'preBuiltCommitMessage']),
    overviewText() {
      return n__('%d changed file', '%d changed files', this.stagedFiles.length);
    },
    commitButtonText() {
      return this.stagedFiles.length ? __('Commit') : __('Stage & Commit');
    },

    currentViewIsCommitView() {
      return this.currentActivityView === leftSidebarViews.commit.name;
    },
    commitErrorPrimaryAction() {
      const { primaryAction } = this.lastCommitError || {};

      return {
        button: primaryAction ? { text: primaryAction.text } : undefined,
        callback: primaryAction?.callback?.bind(this, this.$store) || (() => {}),
      };
    },
  },
  watch: {
    currentActivityView: 'handleCompactState',
    someUncommittedChanges: 'handleCompactState',
    lastCommitMsg: 'handleCompactState',
    commitError(val) {
      if (!val) {
        return;
      }

      this.lastCommitError = val;
      this.$refs.commitErrorModal.show();
    },
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
    ...mapActions('commit', [
      'updateCommitMessage',
      'discardDraft',
      'commitChanges',
      'updateCommitAction',
    ]),
    commit() {
      return this.commitChanges();
    },
    handleCompactState() {
      if (this.lastCommitMsg) {
        this.isCompact = false;
      } else {
        this.isCompact =
          !this.someUncommittedChanges ||
          !this.currentViewIsCommitView ||
          window.innerHeight < MAX_WINDOW_HEIGHT_COMPACT;
      }
    },
    toggleIsCompact() {
      this.isCompact = !this.isCompact;
    },
    beginCommit() {
      return this.updateActivityBarView(leftSidebarViews.commit.name).then(() => {
        this.isCompact = false;
      });
    },
    beforeEnterTransition() {
      const elHeight = this.isCompact
        ? this.$refs.formEl && this.$refs.formEl.offsetHeight
        : this.$refs.compactEl && this.$refs.compactEl.offsetHeight;

      this.componentHeight = elHeight;
    },
    enterTransition() {
      this.$nextTick(() => {
        const elHeight = this.isCompact
          ? this.$refs.compactEl && this.$refs.compactEl.offsetHeight
          : this.$refs.formEl && this.$refs.formEl.offsetHeight;

        this.componentHeight = elHeight;
      });
    },
    afterEndTransition() {
      this.componentHeight = null;
    },
  },
};
</script>

<template>
  <div
    :class="{
      'is-compact': isCompact,
      'is-full': !isCompact,
    }"
    :style="{
      height: componentHeight ? `${componentHeight}px` : null,
    }"
    class="multi-file-commit-form"
  >
    <transition
      name="commit-form-slide-up"
      @before-enter="beforeEnterTransition"
      @enter="enterTransition"
      @after-enter="afterEndTransition"
    >
      <div v-if="isCompact" ref="compactEl" class="commit-form-compact">
        <button
          :disabled="!someUncommittedChanges"
          type="button"
          class="btn btn-primary btn-sm btn-block qa-begin-commit-button"
          data-testid="begin-commit-button"
          @click="beginCommit"
        >
          {{ __('Commit…') }}
        </button>
        <p class="text-center bold">{{ overviewText }}</p>
      </div>
      <form v-else ref="formEl" @submit.prevent.stop="commit">
        <transition name="fade"> <success-message v-show="lastCommitMsg" /> </transition>
        <commit-message-field
          :text="commitMessage"
          :placeholder="preBuiltCommitMessage"
          @input="updateCommitMessage"
          @submit="commit"
        />
        <div class="clearfix gl-mt-5">
          <actions />
          <gl-button
            :loading="submitCommitLoading"
            class="float-left qa-commit-button"
            size="small"
            category="primary"
            variant="success"
            @click="commit"
          >
            {{ __('Commit') }}
          </gl-button>
          <button
            v-if="!discardDraftButtonDisabled"
            type="button"
            class="btn btn-default btn-sm float-right"
            @click="discardDraft"
          >
            {{ __('Discard draft') }}
          </button>
          <gl-button
            v-else
            type="button"
            class="float-right"
            category="secondary"
            variant="default"
            size="small"
            @click="toggleIsCompact"
          >
            {{ __('Collapse') }}
          </gl-button>
        </div>
        <gl-modal
          ref="commitErrorModal"
          modal-id="ide-commit-error-modal"
          :title="lastCommitError.title"
          :action-primary="commitErrorPrimaryAction.button"
          :action-cancel="{ text: __('Cancel') }"
          @ok="commitErrorPrimaryAction.callback"
        >
          <div v-safe-html="lastCommitError.messageHTML"></div>
        </gl-modal>
      </form>
    </transition>
  </div>
</template>
