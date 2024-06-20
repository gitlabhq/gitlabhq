<script>
import {
  GlButton,
  GlAlert,
  GlLoadingIcon,
  GlFormCheckbox,
  GlFormGroup,
  GlFormSelect,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { getPreferredLocales, s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { fetchPolicies } from '~/lib/graphql';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { findWidget } from '~/issues/list/utils';
import { newWorkItemFullPath, isWorkItemItemValidEnum } from '~/work_items/utils';
import {
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  sprintfWorkItem,
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  NEW_WORK_ITEM_IID,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_PARTICIPANTS,
  WIDGET_TYPE_DESCRIPTION,
  NEW_WORK_ITEM_GID,
} from '../constants';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import groupWorkItemTypesQuery from '../graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';

import WorkItemTitle from './work_item_title.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLoading from './work_item_loading.vue';

export default {
  components: {
    GlButton,
    GlAlert,
    GlLoadingIcon,
    GlFormGroup,
    GlFormCheckbox,
    GlFormSelect,
    WorkItemDescription,
    WorkItemTitle,
    WorkItemAssignees,
    WorkItemLoading,
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status.vue'),
    WorkItemColor: () => import('ee_component/work_items/components/work_item_color.vue'),
  },
  inject: ['fullPath', 'isGroup'],
  props: {
    workItemTypeName: {
      type: String,
      required: false,
      default: null,
    },
    hideFormTitle: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isTitleValid: true,
      isConfidential: false,
      error: null,
      workItemTypes: [],
      selectedWorkItemTypeId: null,
      loading: false,
      showWorkItemTypeSelect: false,
      newWorkItemPath: newWorkItemFullPath(this.fullPath),
    };
  },
  apollo: {
    workItem: {
      query() {
        return this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery;
      },
      variables() {
        return {
          fullPath: this.newWorkItemPath,
          iid: NEW_WORK_ITEM_IID,
        };
      },
      skip() {
        return !this.fullPath;
      },
      update(data) {
        return data?.workspace?.workItem ?? {};
      },
      error() {
        this.error = i18n.fetchError;
      },
    },
    workItemTypes: {
      query() {
        return this.isGroup ? groupWorkItemTypesQuery : projectWorkItemTypesQuery;
      },
      fetchPolicy() {
        return this.workItemTypeName ? fetchPolicies.CACHE_ONLY : fetchPolicies.CACHE_FIRST;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          name: this.workItemTypeName,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      result() {
        if (!this.workItemTypes?.length) {
          return;
        }
        if (this.workItemTypes?.length === 1) {
          this.selectedWorkItemTypeId = this.workItemTypes[0].id;
        } else {
          this.showWorkItemTypeSelect = true;
        }
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.workItemTypes.loading || this.$apollo.queries.workItem.loading;
    },
    hasWidgets() {
      return this.workItem?.widgets?.length > 0;
    },
    workItemAssignees() {
      return findWidget(WIDGET_TYPE_ASSIGNEES, this.workItem);
    },
    workItemHealthStatus() {
      return findWidget(WIDGET_TYPE_HEALTH_STATUS, this.workItem);
    },
    workItemColor() {
      return findWidget(WIDGET_TYPE_COLOR, this.workItem);
    },
    workItemTypesForSelect() {
      return this.workItemTypes
        ? this.workItemTypes.map((node) => ({
            value: node.id,
            text: capitalizeFirstCharacter(node.name.toLocaleLowerCase(getPreferredLocales()[0])),
          }))
        : [];
    },
    selectedWorkItemType() {
      return this.workItemTypes?.find((item) => item.id === this.selectedWorkItemTypeId);
    },
    formOptions() {
      return [{ value: null, text: s__('WorkItem|Select type') }, ...this.workItemTypesForSelect];
    },
    createErrorText() {
      const workItemType = this.selectedWorkItemType?.name;
      return sprintfWorkItem(I18N_WORK_ITEM_ERROR_CREATING, workItemType);
    },
    createWorkItemText() {
      const workItemType = this.selectedWorkItemType?.name;
      return sprintfWorkItem(I18N_WORK_ITEM_CREATE_BUTTON_LABEL, workItemType);
    },
    makeConfidentialText() {
      return sprintfWorkItem(
        s__(
          'WorkItem|This %{workItemType} is confidential and should only be visible to users having at least Reporter access.',
        ),
        this.selectedWorkItemType?.name,
      );
    },
    titleText() {
      return sprintfWorkItem(s__('WorkItem|New %{workItemType}'), this.selectedWorkItemType?.name);
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    workItemParticipantNodes() {
      return this.workItemParticipants?.participants?.nodes ?? [];
    },
    workItemParticipants() {
      return findWidget(WIDGET_TYPE_PARTICIPANTS, this.workItem);
    },
    workItemAssigneeIds() {
      const assigneesWidget = findWidget(WIDGET_TYPE_ASSIGNEES, this.workItem);
      return assigneesWidget?.assignees?.nodes?.map((assignee) => assignee.id) || [];
    },
    workItemColorValue() {
      const colorWidget = findWidget(WIDGET_TYPE_COLOR, this.workItem);
      return colorWidget?.color || '';
    },
    workItemHealthStatusValue() {
      const healthStatusWidget = findWidget(WIDGET_TYPE_HEALTH_STATUS, this.workItem);
      return healthStatusWidget?.healthStatus || null;
    },
    workItemAuthor() {
      return this.workItem?.author;
    },
    workItemTitle() {
      return this.workItem?.title || '';
    },
    workItemDescription() {
      const descriptionWidget = findWidget(WIDGET_TYPE_DESCRIPTION, this.workItem);
      return descriptionWidget?.description;
    },
  },
  methods: {
    isWidgetSupported(widgetType) {
      const widgetDefinitions =
        this.selectedWorkItemType?.widgetDefinitions?.flatMap((i) => i.type) || [];
      return widgetDefinitions.indexOf(widgetType) !== -1;
    },
    validate(newValue) {
      const title = newValue || this.workItemTitle;
      this.isTitleValid = Boolean(title.trim());
    },
    updateCache() {
      if (!this.selectedWorkItemTypeId || !isWorkItemItemValidEnum(this.workItemType)) {
        return;
      }
      setNewWorkItemCache(
        this.isGroup,
        this.fullPath,
        this.selectedWorkItemType?.widgetDefinitions,
        this.workItemType,
      );
    },
    async updateDraftData(type, value) {
      if (type === 'title') {
        this.validate(value);
      }

      try {
        this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              isGroup: this.isGroup,
              fullPath: this.fullPath,
              [type]: value,
            },
          },
        });
      } catch {
        this.error = this.createErrorText;
        Sentry.captureException(this.error);
      }
    },
    async createWorkItem() {
      this.validate();

      if (!this.isTitleValid) {
        return;
      }

      this.loading = true;

      const workItemCreateInput = {
        title: this.workItemTitle,
        workItemTypeId: this.selectedWorkItemTypeId,
        namespacePath: this.fullPath,
        confidential: this.workItem.confidential,
        descriptionWidget: {
          description: this.workItemDescription || '',
        },
      };

      // TODO , we can move this to util, currently objectives with other widgets not being supported is causing issues

      if (this.isWidgetSupported(WIDGET_TYPE_COLOR)) {
        workItemCreateInput.colorWidget = {
          color: this.workItemColorValue,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_ASSIGNEES)) {
        workItemCreateInput.assigneesWidget = {
          assigneeIds: this.workItemAssigneeIds,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_HEALTH_STATUS)) {
        workItemCreateInput.healthStatusWidget = {
          healthStatus: this.workItemHealthStatusValue,
        };
      }

      try {
        const response = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              ...workItemCreateInput,
            },
          },
          update: (store, { data: { workItemCreate } }) => {
            const { workItem } = workItemCreate;

            store.writeQuery({
              query: this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery,
              variables: {
                fullPath: this.fullPath,
                iid: workItem.iid,
              },
              data: {
                workspace: {
                  __typename: TYPENAME_PROJECT,
                  id: workItem.namespace.id,
                  workItem: {
                    __typename: 'WorkItem',
                    ...workItem,
                  },
                },
              },
            });
          },
        });

        this.$emit('workItemCreated', response.data.workItemCreate.workItem);
      } catch {
        this.error = this.createErrorText;
        this.loading = false;
      }
    },
    handleCancelClick() {
      this.$emit('cancel');
    },
  },
  NEW_WORK_ITEM_IID,
  NEW_WORK_ITEM_GID,
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <work-item-loading v-if="isLoading" />
    <template v-else>
      <gl-alert v-if="error" variant="danger" @dismiss="error = null">{{ error }}</gl-alert>
      <h1 v-if="!hideFormTitle" class="page-title gl-text-xl gl-pb-5">{{ titleText }}</h1>
      <div class="gl-mb-5">
        <gl-loading-icon
          v-if="$apollo.queries.workItemTypes.loading"
          size="lg"
          data-testid="loading-types"
        />
        <gl-form-group
          v-else-if="showWorkItemTypeSelect"
          :label="__('Type')"
          label-for="work-item-type"
        >
          <gl-form-select
            id="work-item-type"
            v-model="selectedWorkItemTypeId"
            :options="formOptions"
            class="gl-max-w-26"
            @change="updateCache"
          />
        </gl-form-group>
      </div>
      <work-item-title
        ref="title"
        data-testid="title-input"
        is-editing
        :is-valid="isTitleValid"
        :title="workItemTitle"
        @updateDraft="updateDraftData('title', $event)"
        @updateWorkItem="createWorkItem"
      />
      <div data-testid="work-item-overview" class="work-item-overview">
        <section>
          <work-item-description
            edit-mode
            :autofocus="false"
            :full-path="fullPath"
            create-flow
            :show-buttons-below-field="false"
            :work-item-id="$options.NEW_WORK_ITEM_GID"
            :work-item-iid="$options.NEW_WORK_ITEM_IID"
            @error="updateError = $event"
            @updateDraft="updateDraftData('description', $event)"
          />
          <gl-form-group :label="__('Confidentiality')" label-for="work-item-confidential">
            <gl-form-checkbox
              id="work-item-confidential"
              v-model="isConfidential"
              data-testid="confidential-checkbox"
              @change="updateDraftData('confidential', $event)"
            >
              {{ makeConfidentialText }}
            </gl-form-checkbox>
          </gl-form-group>
        </section>
        <aside
          v-if="hasWidgets"
          data-testid="work-item-overview-right-sidebar"
          class="work-item-overview-right-sidebar"
          :class="{ 'is-modal': true }"
        >
          <template v-if="workItemAssignees">
            <work-item-assignees
              class="gl-mb-5 js-assignee"
              :can-update="canUpdate"
              :full-path="fullPath"
              :work-item-id="workItem.id"
              :assignees="workItemAssignees.assignees.nodes"
              :participants="workItemParticipantNodes"
              :work-item-author="workItemAuthor"
              :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
              :work-item-type="workItemType"
              :can-invite-members="workItemAssignees.canInviteMembers"
              @error="$emit('error', $event)"
            />
          </template>
          <template v-if="workItemHealthStatus">
            <work-item-health-status
              class="gl-mb-5"
              :health-status="workItemHealthStatus.healthStatus"
              :can-update="canUpdate"
              :work-item-id="workItem.id"
              :work-item-iid="workItem.iid"
              :work-item-type="workItemType"
              :full-path="fullPath"
              @error="$emit('error', $event)"
            />
          </template>
          <template v-if="workItemColor">
            <work-item-color
              class="gl-mb-5"
              :work-item="workItem"
              :full-path="fullPath"
              :can-update="canUpdate"
              @error="$emit('error', $event)"
            />
          </template>
        </aside>
        <div class="gl-py-3 gl-flex gl-gap-3 gl-col-start-1">
          <gl-button
            variant="confirm"
            :loading="loading"
            data-testid="create-button"
            @click="createWorkItem"
          >
            {{ createWorkItemText }}
          </gl-button>
          <gl-button type="button" data-testid="cancel-button" @click="handleCancelClick">
            {{ __('Cancel') }}
          </gl-button>
        </div>
      </div>
    </template>
  </form>
</template>
