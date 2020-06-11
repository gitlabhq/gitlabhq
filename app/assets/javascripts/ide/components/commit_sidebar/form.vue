<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { n__, __ } from '~/locale';
import { GlModal } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import CommitMessageField from './message_field.vue';
import Actions from './actions.vue';
import SuccessMessage from './success_message.vue';
import { leftSidebarViews, MAX_WINDOW_HEIGHT_COMPACT } from '../../constants';
import consts from '../../stores/modules/commit/constants';

export default {
  components: {
    Actions,
    LoadingButton,
    CommitMessageField,
    SuccessMessage,
    GlModal,
  },
  data() {
    return {
      isCompact: true,
      componentHeight: null,
    };
  },
  computed: {
    ...mapState(['changedFiles', 'stagedFiles', 'currentActivityView', 'lastCommitMsg']),
    ...mapState('commit', ['commitMessage', 'submitCommitLoading']),
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
  },
  watch: {
    currentActivityView: 'handleCompactState',
    someUncommittedChanges: 'handleCompactState',
    lastCommitMsg: 'handleCompactState',
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
      return this.commitChanges().catch(() => {
        this.$refs.createBranchModal.show();
      });
    },
    forceCreateNewBranch() {
      return this.updateCommitAction(consts.COMMIT_TO_NEW_BRANCH).then(() => this.commit());
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
        <div class="clearfix prepend-top-15">
          <actions />
          <loading-button
            :loading="submitCommitLoading"
            :label="commitButtonText"
            container-class="btn btn-success btn-sm float-left qa-commit-button"
            @click="commit"
          />
          <button
            v-if="!discardDraftButtonDisabled"
            type="button"
            class="btn btn-default btn-sm float-right"
            @click="discardDraft"
          >
            {{ __('Discard draft') }}
          </button>
          <button
            v-else
            type="button"
            class="btn btn-default btn-sm float-right"
            @click="toggleIsCompact"
          >
            {{ __('Collapse') }}
          </button>
        </div>
        <gl-modal
          ref="createBranchModal"
          modal-id="ide-create-branch-modal"
          :ok-title="__('Create new branch')"
          :title="__('Branch has changed')"
          ok-variant="success"
          @ok="forceCreateNewBranch"
        >
          {{
            __(`This branch has changed since you started editing.
                Would you like to create a new branch?`)
          }}
        </gl-modal>
      </form>
    </transition>
  </div>
</template>
