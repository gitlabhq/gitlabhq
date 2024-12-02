<script>
import { GlButton, GlModalDirective, GlModal, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, n__, sprintf } from '~/locale';
import checkedRunnerIdsQuery from '../graphql/list/checked_runner_ids.query.graphql';
import BulkRunnerDelete from '../graphql/list/bulk_runner_delete.mutation.graphql';
import { RUNNER_TYPENAME } from '../constants';

export default {
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['localMutations'],
  props: {
    runners: {
      type: Array,
      default: () => [],
      required: false,
    },
  },
  data() {
    return {
      isDeleting: false,
      checkedRunnerIds: [],
    };
  },
  apollo: {
    checkedRunnerIds: {
      query: checkedRunnerIdsQuery,
    },
  },
  computed: {
    currentCheckedRunnerIds() {
      return this.runners
        .map(({ id }) => id)
        .filter((id) => this.checkedRunnerIds.indexOf(id) >= 0);
    },
    checkedCount() {
      return this.currentCheckedRunnerIds.length || 0;
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
    modalActionPrimary() {
      return {
        text: n__(
          'Runners|Permanently delete %d runner',
          'Runners|Permanently delete %d runners',
          this.checkedCount,
        ),
        attributes: {
          loading: this.isDeleting,
          variant: 'danger',
        },
      };
    },
    modalActionCancel() {
      return {
        text: __('Cancel'),
        attributes: {
          loading: this.isDeleting,
        },
      };
    },
    modalMessage() {
      return sprintf(
        n__(
          'Runners|%{strongStart}%{count}%{strongEnd} runner will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
          'Runners|%{strongStart}%{count}%{strongEnd} runners will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
          this.checkedCount,
        ),
        { count: this.checkedCount },
      );
    },
  },
  methods: {
    toastConfirmationMessage(deletedCount) {
      return n__(
        'Runners|%d selected runner deleted',
        'Runners|%d selected runners deleted',
        deletedCount,
      );
    },
    onClearChecked() {
      this.localMutations.clearChecked();
    },
    async onConfirmDelete(e) {
      this.isDeleting = true;
      e.preventDefault(); // don't close modal until deletion is complete

      try {
        await this.$apollo.mutate({
          mutation: BulkRunnerDelete,
          variables: {
            input: {
              ids: this.currentCheckedRunnerIds,
            },
          },
          update: (cache, { data }) => {
            const { errors, deletedIds } = data.bulkRunnerDelete;

            if (errors?.length) {
              createAlert({
                message: s__(
                  'Runners|An error occurred while deleting. Some runners may not have been deleted.',
                ),
                captureError: true,
                error: new Error(errors.join(' ')),
              });
            }

            if (deletedIds?.length) {
              this.$emit('deleted', {
                message: this.toastConfirmationMessage(deletedIds.length),
              });

              // Remove deleted runners from the cache
              deletedIds.forEach((id) => {
                const cacheId = cache.identify({ __typename: RUNNER_TYPENAME, id });
                cache.evict({ id: cacheId });
              });
              cache.gc();
            }
          },
        });
      } catch (error) {
        this.onError(error);
      } finally {
        this.isDeleting = false;
        this.$refs.modal.hide();
      }
    },
    onError(error) {
      createAlert({
        message: s__(
          'Runners|Something went wrong while deleting. Please refresh the page to try again.',
        ),
        captureError: true,
        error,
      });
    },
  },
  BULK_DELETE_MODAL_ID: 'bulk-delete-modal',
};
</script>

<template>
  <div>
    <div
      v-if="checkedCount"
      data-testid="runner-bulk-delete-banner"
      class="gl-my-4 gl-border-1 gl-border-solid gl-border-default gl-p-4"
    >
      <div class="gl-flex gl-items-center">
        <div>
          <gl-sprintf :message="bannerMessage">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </div>
        <div class="gl-ml-auto">
          <gl-button data-testid="clear-selection" variant="default" @click="onClearChecked">{{
            s__('Runners|Clear selection')
          }}</gl-button>
          <gl-button
            v-gl-modal="$options.BULK_DELETE_MODAL_ID"
            variant="danger"
            data-testid="delete-selected"
            >{{ s__('Runners|Delete selected') }}</gl-button
          >
        </div>
      </div>
    </div>
    <gl-modal
      ref="modal"
      size="sm"
      :modal-id="$options.BULK_DELETE_MODAL_ID"
      :title="modalTitle"
      :action-primary="modalActionPrimary"
      :action-cancel="modalActionCancel"
      @primary="onConfirmDelete"
    >
      <gl-sprintf :message="modalMessage">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
