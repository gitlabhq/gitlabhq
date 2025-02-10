<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import EditedAt from '~/issues/show/components/edited.vue';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  newWorkItemId,
  newWorkItemFullPath,
  autocompleteDataSources,
  markdownPreviewPath,
} from '~/work_items/utils';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import workItemDescriptionTemplateQuery from '../graphql/work_item_description_template.query.graphql';
import {
  i18n,
  NEW_WORK_ITEM_IID,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_DESCRIPTION,
  ROUTES,
} from '../constants';
import WorkItemDescriptionRendered from './work_item_description_rendered.vue';
import WorkItemDescriptionTemplateListbox from './work_item_description_template_listbox.vue';

const paramName = 'description_template';
const oldParamNameFromPreWorkItems = 'issuable_template';

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
    WorkItemDescriptionTemplateListbox,
  },
  mixins: [Tracking.mixin(), glFeatureFlagMixin()],
  inject: ['isGroup'],
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
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
    withoutHeadingAnchors: {
      type: Boolean,
      required: false,
      default: false,
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
      descriptionText: this.description,
      initialDescriptionText: this.description,
      conflictedDescription: '',
      formFieldProps: {
        'aria-label': __('Description'),
        placeholder: __('Write a comment or drag your files here…'),
        id: 'work-item-description',
        name: 'work-item-description',
      },
      selectedTemplate: null,
      descriptionTemplate: null,
      appliedTemplate: '',
      showTemplateApplyWarning: false,
    };
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
        workItem: { iid },
      } = this;
      return markdownPreviewPath({ fullPath, iid, isGroup: this.isGroupWorkItem });
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
        'common-note-form': true,
      };
    },
    showEditedAt() {
      return (this.taskCompletionStatus || this.lastEditedAt) && !this.editMode;
    },
    canShowDescriptionTemplateSelector() {
      return this.glFeatures.workItemDescriptionTemplates;
    },
    descriptionTemplateContent() {
      return this.descriptionTemplate || '';
    },
    canResetTemplate() {
      const hasAppliedTemplate = this.appliedTemplate !== '';
      const hasEditedTemplate = this.descriptionText !== this.appliedTemplate;
      return hasAppliedTemplate && hasEditedTemplate;
    },
    isNewWorkItemRoute() {
      return this.$route?.name === ROUTES.new;
    },
  },
  watch: {
    updateInProgress(newValue) {
      this.isSubmitting = newValue;
    },
    editMode(newValue) {
      this.isEditing = newValue;
      this.selectedTemplate = null;
      this.appliedTemplate = '';
      this.showTemplateApplyWarning = false;
      if (newValue) {
        this.startEditing();
      }
    },
  },
  mounted() {
    if (this.isNewWorkItemRoute) {
      this.selectedTemplate = {
        name: this.$route.query[paramName] || this.$route.query[oldParamNameFromPreWorkItems],
        projectId: null,
        category: null,
      };
    }
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
        if (this.isEditing && !this.createFlow) {
          this.checkForConflicts();
        }
        if (this.isEditing && this.createFlow) {
          this.startEditing();
        }
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
    descriptionTemplate: {
      query: workItemDescriptionTemplateQuery,
      skip() {
        return !this.selectedTemplate?.projectId;
      },
      variables() {
        return {
          name: this.selectedTemplate.name,
          projectId: this.selectedTemplate.projectId,
        };
      },
      update(data) {
        return data.workItemDescriptionTemplateContent.content;
      },
      result() {
        const isDirty = this.descriptionText !== this.workItemDescription?.description;
        const isUnchangedTemplate = this.descriptionText === this.appliedTemplate;
        const hasContent = this.descriptionText !== '';
        if (!isUnchangedTemplate && (isDirty || hasContent)) {
          this.showTemplateApplyWarning = true;
        } else {
          this.applyTemplate();
        }
      },
      error(e) {
        Sentry.captureException(e);
        this.$emit('error', s__('WorkItem|Unable to find selected template.'));
      },
    },
  },
  methods: {
    checkForConflicts() {
      if (this.initialDescriptionText.trim() !== this.workItemDescription?.description.trim()) {
        this.conflictedDescription = this.workItemDescription?.description;
      }
    },
    async startEditing() {
      this.isEditing = true;
      this.disableTruncation = true;

      this.descriptionText = this.createFlow
        ? this.workItemDescription?.description
        : getDraft(this.autosaveKey) || this.workItemDescription?.description;
      this.initialDescriptionText = this.descriptionText;

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
      this.conflictedDescription = '';
      this.initialDescriptionText = this.descriptionText;
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

      this.$emit('updateWorkItem', { clearDraft: () => clearDraft(this.autosaveKey) });

      this.conflictedDescription = '';
      this.initialDescriptionText = this.descriptionText;
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
    handleSelectTemplate(templateData) {
      this.selectedTemplate = templateData;
    },
    resetQueryParams() {
      if (!this.isNewWorkItemRoute) {
        return;
      }

      const params = new URLSearchParams(this.$route.query);
      params.delete(paramName);
      params.delete(oldParamNameFromPreWorkItems);
      if (this.selectedTemplate) {
        params.set(paramName, this.selectedTemplate.name);
      }

      this.$router.replace({
        query: Object.fromEntries(params),
      });
    },
    applyTemplate() {
      this.appliedTemplate = this.descriptionTemplateContent;
      this.setDescriptionText(this.descriptionTemplateContent);
      this.onInput();
      this.showTemplateApplyWarning = false;
      this.resetQueryParams();
    },
    cancelApplyTemplate() {
      this.selectedTemplate = null;
      this.descriptionTemplate = null;
      this.showTemplateApplyWarning = false;
      this.resetQueryParams();
    },
    handleClearTemplate() {
      if (this.appliedTemplate) {
        this.setDescriptionText('');
        this.selectedTemplate = null;
        this.descriptionTemplate = null;
        this.appliedTemplate = '';
      }
    },
    handleResetTemplate() {
      if (this.canResetTemplate) {
        this.setDescriptionText(this.appliedTemplate);
        this.onInput();
      }
    },
  },
};
</script>

<template>
  <div data-testid="work-item-description-wrapper">
    <gl-form v-if="isEditing" @submit.prevent="updateWorkItem" @reset.prevent="cancelEditing">
      <gl-form-group
        :class="formGroupClass"
        :label="__('Description')"
        label-for="work-item-description"
        :label-sr-only="!canShowDescriptionTemplateSelector"
      >
        <work-item-description-template-listbox
          v-if="canShowDescriptionTemplateSelector"
          :full-path="fullPath"
          :template="selectedTemplate"
          @selectTemplate="handleSelectTemplate"
          @clear="handleClearTemplate"
          @reset="handleResetTemplate"
        />
        <gl-alert
          v-if="showTemplateApplyWarning"
          :dismissible="false"
          variant="warning"
          class="gl-mt-2"
          data-testid="description-template-warning"
        >
          <p>
            {{
              s__(
                'WorkItem|Applying a template will replace the existing description. Any changes you have made will be lost.',
              )
            }}
          </p>
          <template #actions>
            <gl-button variant="confirm" data-testid="template-apply" @click="applyTemplate"
              >{{ s__('WorkItem|Apply template') }}
            </gl-button>
            <gl-button
              category="secondary"
              class="gl-ml-3"
              data-testid="template-cancel"
              @click="cancelApplyTemplate"
              >{{ s__('WorkItem|Cancel') }}
            </gl-button>
          </template>
        </gl-alert>
        <markdown-editor
          :value="descriptionText"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="$options.markdownDocsPath"
          :form-field-props="formFieldProps"
          :quick-actions-docs-path="$options.quickActionsDocsPath"
          :autocomplete-data-sources="autocompleteDataSources"
          enable-autocomplete
          supports-quick-actions
          :autofocus="autofocus"
          :class="{ 'gl-mt-3': canShowDescriptionTemplateSelector }"
          @input="setDescriptionText"
          @keydown.meta.enter="updateWorkItem"
          @keydown.ctrl.enter="updateWorkItem"
        />
        <div class="gl-flex">
          <gl-alert
            v-if="hasConflicts"
            :dismissible="false"
            variant="danger"
            class="gl-mt-5 gl-w-full"
          >
            <p>
              {{
                s__(
                  "WorkItem|Someone edited the description at the same time you did. If you save it will overwrite their changes. Please confirm you'd like to save your edits.",
                )
              }}
            </p>
            <details class="gl-mb-5">
              <summary class="gl-text-link">{{ s__('WorkItem|View current version') }}</summary>
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
          <div v-else-if="showButtonsBelowField" class="gl-mt-5 gl-flex gl-gap-3">
            <gl-button
              category="primary"
              variant="confirm"
              :loading="isSubmitting"
              data-testid="save-description"
              type="submit"
              >{{ saveButtonText }}
            </gl-button>
            <gl-button category="secondary" data-testid="cancel" type="reset"
              >{{ __('Cancel') }}
            </gl-button>
          </div>
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
      :is-group="isGroup"
      :is-updating="isSubmitting"
      :without-heading-anchors="withoutHeadingAnchors"
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
