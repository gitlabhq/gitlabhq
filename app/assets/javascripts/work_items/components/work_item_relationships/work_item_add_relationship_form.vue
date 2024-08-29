<script>
import { produce } from 'immer';
import { GlFormGroup, GlForm, GlFormRadioGroup, GlButton, GlAlert } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import WorkItemTokenInput from '../shared/work_item_token_input.vue';
import addLinkedItemsMutation from '../../graphql/add_linked_items.mutation.graphql';
import workItemLinkedItemsQuery from '../../graphql/work_item_linked_items.query.graphql';
import { findLinkedItemsWidget } from '../../utils';
import {
  LINK_ITEM_FORM_HEADER_LABEL,
  LINKED_ITEM_TYPE_VALUE,
  MAX_WORK_ITEMS,
  I18N_MAX_WORK_ITEMS_ERROR_MESSAGE,
  I18N_MAX_WORK_ITEMS_NOTE_LABEL,
} from '../../constants';

export default {
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormRadioGroup,
    GlAlert,
    WorkItemTokenInput,
  },
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    workItemFullPath: {
      type: String,
      required: false,
      default: null,
    },
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
    childrenIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      linkedItemType: LINKED_ITEM_TYPE_VALUE.RELATED,
      linkedItemTypes: [
        {
          text: this.$options.i18n.relatedToLabel,
          value: LINKED_ITEM_TYPE_VALUE.RELATED,
        },
        {
          text: this.$options.i18n.blockingLabel,
          value: LINKED_ITEM_TYPE_VALUE.BLOCKS,
        },
        {
          text: this.$options.i18n.blockedByLabel,
          value: LINKED_ITEM_TYPE_VALUE.BLOCKED_BY,
        },
      ],
      workItemsToAdd: [],
      error: null,
      showWorkItemsToAddInvalidMessage: false,
      isSubmitting: false,
      searchInProgress: false,
      maxWorkItems: MAX_WORK_ITEMS,
    };
  },
  computed: {
    linkItemFormHeaderLabel() {
      return LINK_ITEM_FORM_HEADER_LABEL[this.workItemType];
    },
    workItemsToAddInvalidMessage() {
      return this.$options.i18n.addChildErrorMessage;
    },
    isSubmitButtonDisabled() {
      return this.workItemsToAdd.length <= 0 || !this.areWorkItemsToAddValid;
    },
    areWorkItemsToAddValid() {
      return this.workItemsToAdd.length <= this.maxWorkItems;
    },
    errorMessage() {
      return !this.areWorkItemsToAddValid ? this.$options.i18n.maxItemsErrorMessage : '';
    },
  },
  methods: {
    async linkWorkItem() {
      try {
        if (this.searchInProgress) {
          return;
        }
        this.isSubmitting = true;
        const {
          data: {
            workItemAddLinkedItems: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: addLinkedItemsMutation,
          variables: {
            input: {
              id: this.workItemId,
              linkType: this.linkedItemType,
              workItemsIds: this.workItemsToAdd.map((wi) => wi.id),
            },
          },
          update: (
            cache,
            {
              data: {
                workItemAddLinkedItems: { workItem },
              },
            },
          ) => {
            const queryArgs = {
              query: workItemLinkedItemsQuery,
              variables: { fullPath: this.workItemFullPath, iid: this.workItemIid },
            };
            const sourceData = cache.readQuery(queryArgs);

            if (!sourceData) {
              return;
            }

            cache.writeQuery({
              ...queryArgs,
              data: produce(sourceData, (draftState) => {
                const linkedItemsWidget = findLinkedItemsWidget(draftState.workspace.workItem);

                linkedItemsWidget.linkedItems = findLinkedItemsWidget(workItem)?.linkedItems;
              }),
            });
          },
        });

        if (errors.length > 0) {
          [this.error] = errors;
          return;
        }

        this.workItemsToAdd = [];
        this.unsetError();
        this.showWorkItemsToAddInvalidMessage = false;
        this.linkedItemType = LINKED_ITEM_TYPE_VALUE.RELATED;
        this.$emit('submitted');
      } catch (e) {
        this.error = this.$options.i18n.addLinkedItemErrorMessage;
      } finally {
        this.isSubmitting = false;
      }
    },
    unsetError() {
      this.error = null;
    },
  },
  i18n: {
    addButtonLabel: __('Add'),
    relatedToLabel: s__('WorkItem|relates to'),
    blockingLabel: s__('WorkItem|blocks'),
    blockedByLabel: s__('WorkItem|is blocked by'),
    linkItemInputLabel: s__('WorkItem|the following items'),
    addLinkedItemErrorMessage: s__(
      'WorkItem|Something went wrong when trying to link a item. Please try again.',
    ),
    maxItemsNoteLabel: I18N_MAX_WORK_ITEMS_NOTE_LABEL,
    maxItemsErrorMessage: I18N_MAX_WORK_ITEMS_ERROR_MESSAGE,
  },
};
</script>

<template>
  <gl-form data-testid="link-work-item-form" @submit.stop.prevent="linkWorkItem">
    <gl-alert v-if="error" variant="danger" class="gl-mb-3" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <gl-form-group
      :label="linkItemFormHeaderLabel"
      label-for="linked-item-type-radio"
      label-class="label-bold"
      class="gl-mb-3"
    >
      <gl-form-radio-group
        id="linked-item-type-radio"
        v-model="linkedItemType"
        :options="linkedItemTypes"
        :checked="linkedItemType"
      />
    </gl-form-group>
    <p class="gl-mb-2 gl-font-bold">
      {{ $options.i18n.linkItemInputLabel }}
    </p>
    <div class="gl-mb-5">
      <work-item-token-input
        v-model="workItemsToAdd"
        class="gl-mb-2"
        :parent-work-item-id="workItemId"
        :children-ids="childrenIds"
        :are-work-items-to-add-valid="areWorkItemsToAddValid"
        :full-path="workItemFullPath"
        :is-group="isGroup"
        :max-selection-limit="maxWorkItems"
        @searching="searchInProgress = $event"
      />
      <div v-if="errorMessage" class="gl-mb-2 gl-text-danger">
        {{ $options.i18n.maxItemsErrorMessage }}
      </div>
      <div v-if="!errorMessage" data-testid="max-work-item-note" class="gl-text-subtle">
        {{ $options.i18n.maxItemsNoteLabel }}
      </div>
      <div
        v-if="showWorkItemsToAddInvalidMessage"
        class="gl-text-danger"
        data-testid="work-items-invalid"
      >
        {{ workItemsToAddInvalidMessage }}
      </div>
    </div>
    <div class="gl-flex gl-gap-3">
      <gl-button
        data-testid="link-work-item-button"
        category="primary"
        variant="confirm"
        size="small"
        type="submit"
        :disabled="isSubmitButtonDisabled"
        :loading="isSubmitting"
      >
        {{ $options.i18n.addButtonLabel }}
      </gl-button>
      <gl-button category="secondary" size="small" @click="$emit('cancel')">
        {{ s__('WorkItem|Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
