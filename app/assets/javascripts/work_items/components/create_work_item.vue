<script>
import {
  GlButton,
  GlAlert,
  GlLoadingIcon,
  GlFormCheckbox,
  GlFormGroup,
  GlFormSelect,
} from '@gitlab/ui';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { getPreferredLocales, s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  sprintfWorkItem,
} from '../constants';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import groupWorkItemTypesQuery from '../graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

import WorkItemTitle from './work_item_title.vue';
import WorkItemAttributesWrapper from './work_item_attributes_wrapper.vue';
import WorkItemDescription from './work_item_description.vue';

export default {
  components: {
    GlButton,
    GlAlert,
    GlLoadingIcon,
    GlFormGroup,
    GlFormCheckbox,
    GlFormSelect,
    WorkItemAttributesWrapper,
    WorkItemDescription,
    WorkItemTitle,
  },
  inject: ['fullPath', 'isGroup'],
  props: {
    initialTitle: {
      type: String,
      required: false,
      default: '',
    },
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
      draft: {
        title: this.initialTitle,
        description: '',
      },
      isTitleValid: true,
      isConfidential: false,
      error: null,
      workItemTypes: [],
      selectedWorkItemTypeId: null,
      loading: false,
      showWorkItemTypeSelect: false,
    };
  },
  apollo: {
    workItemTypes: {
      query() {
        return this.isGroup ? groupWorkItemTypesQuery : projectWorkItemTypesQuery;
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
        if (this.workItemTypes.length === 1) {
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
    hasWidgets() {
      return this.draft.widgets?.length > 0;
    },
    workItemTypesForSelect() {
      return this.workItemTypes.map((node) => ({
        value: node.id,
        text: capitalizeFirstCharacter(node.name.toLocaleLowerCase(getPreferredLocales()[0])),
      }));
    },
    selectedWorkItemType() {
      return this.workItemTypes.find((item) => item.id === this.selectedWorkItemTypeId);
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
  },
  methods: {
    validate() {
      this.isTitleValid = Boolean(this.draft.title.trim());
    },
    updateDraftData(type, value) {
      this.draft = {
        ...this.draft,
        [type]: value,
      };
      this.$emit(`updateDraft`, { type, value });

      if (type === 'title') {
        this.validate();
      }
    },
    async createWorkItem() {
      this.validate();

      if (!this.isTitleValid) {
        return;
      }

      this.loading = true;

      try {
        const response = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.draft.title,
              workItemTypeId: this.selectedWorkItemTypeId,
              namespacePath: this.fullPath,
              confidential: this.draft.confidential,
              descriptionWidget: {
                description: this.draft.description,
              },
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
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
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
        />
      </gl-form-group>
    </div>
    <work-item-title
      ref="title"
      data-testid="title-input"
      is-editing
      :is-valid="isTitleValid"
      :title="draft.title"
      @updateDraft="updateDraftData('title', $event)"
      @updateWorkItem="createWorkItem"
    />
    <div data-testid="work-item-overview" class="work-item-overview">
      <section>
        <work-item-description
          edit-mode
          disable-inline-editing
          :autofocus="false"
          :full-path="fullPath"
          :show-buttons-below-field="false"
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
        class="work-item-overview-right-sidebar gl-block"
        :class="{ 'is-modal': true }"
      >
        <work-item-attributes-wrapper
          is-create-view
          :full-path="fullPath"
          :work-item="draft"
          @error="updateError = $event"
          @updateWorkItem="updateDraftData"
          @updateWorkItemAttribute="updateDraftData"
        />
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
  </form>
</template>
