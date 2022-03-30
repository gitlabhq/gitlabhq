<script>
import { GlButton, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import checkedRunnerIdsQuery from '../graphql/list/checked_runner_ids.query.graphql';

export default {
  components: {
    GlButton,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['localMutations'],
  data() {
    return {
      checkedRunnerIds: [],
    };
  },
  apollo: {
    checkedRunnerIds: {
      query: checkedRunnerIdsQuery,
    },
  },
  computed: {
    checkedCount() {
      return this.checkedRunnerIds.length || 0;
    },
    bannerMessage() {
      return sprintf(
        n__(
          'Runners|%{strongStart}%{count}%{strongEnd} runner selected',
          'Runners|%{strongStart}%{count}%{strongEnd} runners selected',
          this.checkedCount,
        ),
        {
          count: this.checkedCount,
        },
      );
    },
    modalTitle() {
      return n__('Runners|Delete %d runner', 'Runners|Delete %d runners', this.checkedCount);
    },
    modalHtmlMessage() {
      return sprintf(
        n__(
          'Runners|%{strongStart}%{count}%{strongEnd} runner will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
          'Runners|%{strongStart}%{count}%{strongEnd} runners will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
          this.checkedCount,
        ),
        {
          strongStart: '<strong>',
          strongEnd: '</strong>',
          count: this.checkedCount,
        },
        false,
      );
    },
    primaryBtnText() {
      return n__(
        'Runners|Permanently delete %d runner',
        'Runners|Permanently delete %d runners',
        this.checkedCount,
      );
    },
  },
  methods: {
    onClearChecked() {
      this.localMutations.clearChecked();
    },
    onClickDelete: ignoreWhilePending(async function onClickDelete() {
      const confirmed = await confirmAction(null, {
        title: this.modalTitle,
        modalHtmlMessage: this.modalHtmlMessage,
        primaryBtnVariant: 'danger',
        primaryBtnText: this.primaryBtnText,
      });

      if (confirmed) {
        // TODO Call $apollo.mutate with list of runner
        // ids in `this.checkedRunnerIds`.
        // See https://gitlab.com/gitlab-org/gitlab/-/issues/339525/
      }
    }),
  },
};
</script>

<template>
  <div v-if="checkedCount" class="gl-my-4 gl-p-4 gl-border-1 gl-border-solid gl-border-gray-100">
    <div class="gl-display-flex gl-align-items-center">
      <div>
        <gl-sprintf :message="bannerMessage">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-ml-auto">
        <gl-button data-testid="clear-btn" variant="default" @click="onClearChecked">{{
          s__('Runners|Clear selection')
        }}</gl-button>
        <gl-button data-testid="delete-btn" variant="danger" @click="onClickDelete">{{
          s__('Runners|Delete selected')
        }}</gl-button>
      </div>
    </div>
  </div>
</template>
