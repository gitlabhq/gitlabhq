<script>
import {
  GlFormGroup,
  GlFormInput,
  GlDatepicker,
  GlFormTextarea,
  GlModal,
  GlAlert,
  GlLink,
} from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { issuableTypeText, TYPE_ISSUE } from '~/issues/constants';
import { toISODateFormat } from '~/lib/utils/datetime_utility';
import { TYPENAME_ISSUE, TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import createTimelogMutation from '../../queries/create_timelog.mutation.graphql';
import { CREATE_TIMELOG_MODAL_ID } from './constants';

export default {
  components: {
    GlDatepicker,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlModal,
    GlAlert,
    GlLink,
  },
  inject: {
    issuableType: {
      default: null,
    },
  },
  props: {
    issuableId: {
      type: String,
      required: false,
      default: '',
    },
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      timeSpent: '',
      spentAt: null,
      summary: '',
      isLoading: false,
      saveError: '',
    };
  },
  computed: {
    modalText() {
      const issuableTypeName = issuableTypeText[this.issuableType || this.workItemType];
      return sprintf(s__('TimeTracking|Track time spent on this %{issuableTypeName}.'), {
        issuableTypeName,
      });
    },
    submitDisabled() {
      return this.isLoading || this.timeSpent?.length === 0;
    },
    primaryProps() {
      return {
        text: s__('CreateTimelogForm|Save'),
        attributes: {
          variant: 'confirm',
          disabled: this.submitDisabled,
          loading: this.isLoading,
        },
      };
    },
    cancelProps() {
      return {
        text: s__('CreateTimelogForm|Cancel'),
      };
    },
    timeTrackingDocsPath() {
      return joinPaths(gon.relative_url_root || '', '/help/user/project/time_tracking.md');
    },
    createTimelogModalId() {
      return this.workItemId
        ? `${CREATE_TIMELOG_MODAL_ID}-${this.workItemId}`
        : CREATE_TIMELOG_MODAL_ID;
    },
  },
  methods: {
    resetModal() {
      this.isLoading = false;
      this.timeSpent = '';
      this.spentAt = null;
      this.summary = '';
      this.saveError = '';
    },
    close() {
      this.resetModal();
      this.$refs.modal.close();
    },
    registerTimeSpent(event) {
      event.preventDefault();

      if (this.timeSpent?.length === 0) {
        return null;
      }

      this.isLoading = true;
      this.saveError = '';

      if (this.workItemId) {
        return this.$apollo
          .mutate({
            mutation: updateWorkItemMutation,
            variables: {
              input: {
                id: this.workItemId,
                timeTrackingWidget: {
                  timelog: {
                    spentAt: this.spentAt ? toISODateFormat(this.spentAt) : null,
                    summary: this.summary,
                    timeSpent: this.timeSpent,
                  },
                },
              },
            },
          })
          .then(({ data }) => {
            if (data.workItemUpdate.errors.length) {
              throw new Error(data.workItemUpdate.errors);
            }

            this.close();
          })
          .catch((error) => {
            this.saveError =
              error?.message ||
              s__('TimeTracking|An error occurred while saving the time estimate.');
          })
          .finally(() => {
            this.isLoading = false;
          });
      }

      return this.$apollo
        .mutate({
          mutation: createTimelogMutation,
          variables: {
            input: {
              timeSpent: this.timeSpent,
              spentAt: this.spentAt ? toISODateFormat(this.spentAt) : null,
              summary: this.summary,
              issuableId: this.getIssuableId(),
            },
          },
        })
        .then(({ data }) => {
          if (data.timelogCreate?.errors.length) {
            this.saveError = data.timelogCreate.errors[0].message || data.timelogCreate.errors[0];
          } else {
            this.close();
          }
        })
        .catch((error) => {
          this.saveError =
            error?.message ||
            s__('CreateTimelogForm|An error occurred while saving the time entry.');
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    getGraphQLEntityType() {
      return this.issuableType === TYPE_ISSUE ? TYPENAME_ISSUE : TYPENAME_MERGE_REQUEST;
    },
    updateSpentAtDate(val) {
      this.spentAt = val;
    },
    getIssuableId() {
      return convertToGraphQLId(this.getGraphQLEntityType(), this.issuableId);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :title="s__('CreateTimelogForm|Add time entry')"
    :modal-id="createTimelogModalId"
    size="sm"
    data-testid="create-timelog-modal"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="registerTimeSpent"
    @cancel="close"
    @close="close"
    @hide="close"
  >
    <p>
      {{ modalText }}
    </p>
    <form class="js-quick-submit gl-flex gl-flex-col" @submit.prevent="registerTimeSpent">
      <div class="gl-flex gl-gap-3">
        <gl-form-group
          key="time-spent"
          label-for="time-spent"
          :label="s__(`CreateTimelogForm|Time spent`)"
          :description="s__(`CreateTimelogForm|Example: 1h 30m`)"
        >
          <gl-form-input
            id="time-spent"
            ref="timeSpent"
            v-model="timeSpent"
            class="gl-form-input-sm"
            autocomplete="off"
          />
        </gl-form-group>
        <gl-form-group
          key="spent-at"
          optional
          :optional-text="__('(optional)')"
          label-for="spent-at"
          :label="s__(`CreateTimelogForm|Spent at`)"
        >
          <gl-datepicker
            :target="null"
            :value="spentAt"
            show-clear-button
            autocomplete="off"
            width="sm"
            @input="updateSpentAtDate"
            @clear="updateSpentAtDate(null)"
          />
        </gl-form-group>
      </div>
      <gl-form-group
        :label="s__('CreateTimelogForm|Summary')"
        optional
        :optional-text="__('(optional)')"
        label-for="summary"
      >
        <gl-form-textarea id="summary" v-model="summary" rows="3" no-resize />
      </gl-form-group>
      <gl-alert v-if="saveError" variant="danger" class="gl-mb-3" :dismissible="false">
        {{ saveError }}
      </gl-alert>
      <!-- This is needed to have the quick-submit behaviour (with Ctrl + Enter or Cmd + Enter) -->
      <input type="submit" hidden />
    </form>
    <gl-link :href="timeTrackingDocsPath">
      {{ s__('CreateTimelogForm|How do I track and estimate time?') }}
    </gl-link>
  </gl-modal>
</template>
