<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import EditedAt from '~/issues/show/components/edited.vue';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import {
  newWorkItemId,
  newWorkItemFullPath,
  autocompleteDataSources,
  markdownPreviewPath,
} from '~/work_items/utils';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import {
  i18n,
  NEW_WORK_ITEM_IID,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_DESCRIPTION,
} from '../constants';
import WorkItemDescriptionRendered from './work_item_description_rendered.vue';

export default {
  components: {
    EditedAt,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormTextarea,
    MarkdownEditor,
    WorkItemDescriptionRendered,
  },
  mixins: [Tracking.mixin()],
  inject: ['isGroup'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
    workItemIid: {
      type: String,
      required: false,
      default: '',
    },
    editMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
    updateInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    showButtonsBelowField: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemTypeName: {
      type: String,
      required: false,
      default: '',
    },
  },
  markdownDocsPath: helpPagePath('user/markdown'),
  data() {
    return {
      workItem: {},
      disableTruncation: false,
      isEditing: this.editMode,
      isSubmitting: false,
      isSubmittingWithKeydown: false,
      descriptionText: '',
      conflictedDescription: '',
      formFieldProps: {
        'aria-label': __('Description'),
        placeholder: __('Write a comment or drag your files here…'),
        id: 'work-item-description',
        name: 'work-item-description',
      },
    };
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      skip() {
        return !this.workItemIid;
      },
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data?.workspace?.workItem || {};
      },
      result() {
        if (this.isEditing) {
          this.checkForConflicts();
        }
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
  },
  computed: {
    createFlow() {
      return this.workItemId === newWorkItemId(this.workItemTypeName);
    },
    workItemFullPath() {
      return this.createFlow
        ? newWorkItemFullPath(this.fullPath, this.workItemTypeName)
        : this.fullPath;
    },
    autosaveKey() {
      return this.workItemId || `new-${this.workItemType}-description-draft`;
    },
    canEdit() {
      return this.workItem?.userPermissions?.updateWorkItem || false;
    },
    hasConflicts() {
      return Boolean(this.conflictedDescription);
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_description',
        property: `type_${this.workItemType}`,
      };
    },
    workItemDescription() {
      const descriptionWidget = this.workItem?.widgets?.find(
        (widget) => widget.type === WIDGET_TYPE_DESCRIPTION,
      );
      return {
        ...descriptionWidget,
        description: descriptionWidget?.description || '',
      };
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    taskCompletionStatus() {
      return this.workItemDescription?.taskCompletionStatus;
    },
    lastEditedAt() {
      return this.workItemDescription?.lastEditedAt;
    },
    lastEditedByName() {
      return this.workItemDescription?.lastEditedBy?.name;
    },
    lastEditedByPath() {
      return this.workItemDescription?.lastEditedBy?.webPath;
    },
    isGroupWorkItem() {
      return this.workItemNamespaceId.includes('Group');
    },
    workItemNamespaceId() {
      return this.workItem?.namespace?.id || '';
    },
    markdownPreviewPath() {
      const {
        fullPath,
        isGroup,
        workItem: { iid },
      } = this;
      return markdownPreviewPath({ fullPath, iid, isGroup });
    },
    autocompleteDataSources() {
      const isNewWorkItemInGroup = this.isGroup && this.workItemIid === NEW_WORK_ITEM_IID;
      return autocompleteDataSources({
        fullPath: this.fullPath,
        isGroup: this.isGroupWorkItem || isNewWorkItemInGroup,
        iid: this.workItemIid,
        workItemTypeId: this.workItem?.workItemType?.id,
      });
    },
    saveButtonText() {
      return this.editMode ? __('Save changes') : __('Save');
    },
    formGroupClass() {
      return {
        'gl-mb-5 common-note-form': true,
      };
    },
    showEditedAt() {
      return (this.taskCompletionStatus || this.lastEditedAt) && !this.editMode;
    },
  },
  watch: {
    updateInProgress(newValue) {
      this.isSubmitting = newValue;
    },
    editMode(newValue) {
      this.isEditing = newValue;
      if (newValue) {
        this.startEditing();
      }
    },
  },
  methods: {
    checkForConflicts() {
      if (this.descriptionText !== this.workItemDescription?.description) {
        this.conflictedDescription = this.workItemDescription?.description;
      }
    },
    async startEditing() {
      this.isEditing = true;
      this.disableTruncation = true;

      this.descriptionText = getDraft(this.autosaveKey) || this.workItemDescription?.description;

      await this.$nextTick();

      this.$refs.textarea?.focus();
    },
    async cancelEditing() {
      const isDirty = this.descriptionText !== this.workItemDescription?.description;

      if (isDirty) {
        const msg = s__('WorkItem|Are you sure you want to cancel editing?');

        const confirmed = await confirmAction(msg, {
          primaryBtnText: __('Discard changes'),
          cancelBtnText: __('Continue editing'),
        });

        if (!confirmed) {
          return;
        }
      }

      this.isEditing = false;
      this.$emit('cancelEditing');
      clearDraft(this.autosaveKey);
    },
    onInput() {
      if (this.isSubmittingWithKeydown) {
        return;
      }

      updateDraft(this.autosaveKey, this.descriptionText);
    },
    async updateWorkItem(event = {}) {
      const { key } = event;

      if (key) {
        this.isSubmittingWithKeydown = true;
      }

      this.$emit('updateWorkItem');
    },
    setDescriptionText(newText) {
      this.descriptionText = newText;
      this.$emit('updateDraft', this.descriptionText);
      updateDraft(this.autosaveKey, this.descriptionText);
    },
    handleDescriptionTextUpdated(newText) {
      this.disableTruncation = true;
      this.descriptionText = newText;
      this.$emit('updateDraft', this.descriptionText);
      this.updateWorkItem();
    },
  },
};
</script>

<template>
  <div>
    <gl-form v-if="isEditing" @submit.prevent="updateWorkItem" @reset.prevent="cancelEditing">
      <gl-form-group
        :class="formGroupClass"
        :label="__('Description')"
        label-sr-only
        label-for="work-item-description"
      >
        <markdown-editor
          class="gl-mb-5"
          :value="descriptionText"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="$options.markdownDocsPath"
          :form-field-props="formFieldProps"
          :quick-actions-docs-path="$options.quickActionsDocsPath"
          :autocomplete-data-sources="autocompleteDataSources"
          enable-autocomplete
          supports-quick-actions
          :autofocus="autofocus"
          @input="setDescriptionText"
          @keydown.meta.enter="updateWorkItem"
          @keydown.ctrl.enter="updateWorkItem"
        />
        <div class="gl-display-flex">
          <gl-alert v-if="hasConflicts" :dismissible="false" variant="danger" class="gl-w-full">
            <p>
              {{
                s__(
                  "WorkItem|Someone edited the description at the same time you did. If you save it will overwrite their changes. Please confirm you'd like to save your edits.",
                )
              }}
            </p>
            <details class="gl-mb-5">
              <summary class="gl-text-blue-500">{{ s__('WorkItem|View current version') }}</summary>
              <gl-form-textarea
                class="js-gfm-input js-autosize markdown-area !gl-font-monospace"
                data-testid="conflicted-description"
                readonly
                no-resize
                :value="conflictedDescription"
              />
            </details>
            <template #actions>
              <gl-button
                category="primary"
                variant="confirm"
                :loading="isSubmitting"
                data-testid="save-description"
                @click="updateWorkItem"
                >{{ s__('WorkItem|Save and overwrite') }}
              </gl-button>
              <gl-button
                category="secondary"
                class="gl-ml-3"
                data-testid="cancel"
                @click="cancelEditing"
                >{{ s__('WorkItem|Discard changes') }}
              </gl-button>
            </template>
          </gl-alert>
          <template v-else-if="showButtonsBelowField">
            <gl-button
              category="primary"
              variant="confirm"
              :loading="isSubmitting"
              data-testid="save-description"
              type="submit"
              >{{ saveButtonText }}
            </gl-button>
            <gl-button category="secondary" class="gl-ml-3" data-testid="cancel" type="reset"
              >{{ __('Cancel') }}
            </gl-button>
          </template>
        </div>
      </gl-form-group>
    </gl-form>
    <work-item-description-rendered
      v-else
      :work-item-description="workItemDescription"
      :work-item-id="workItemId"
      :work-item-type="workItemType"
      :can-edit="canEdit"
      :disable-truncation="disableTruncation"
      :is-updating="isSubmitting"
      @startEditing="startEditing"
      @descriptionUpdated="handleDescriptionTextUpdated"
    />
    <edited-at
      v-if="showEditedAt"
      :task-completion-status="taskCompletionStatus"
      :updated-at="lastEditedAt"
      :updated-by-name="lastEditedByName"
      :updated-by-path="lastEditedByPath"
    />
  </div>
</template>
