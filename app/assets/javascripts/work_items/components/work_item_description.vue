<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { generateDescriptionAction } from 'ee_else_ce/ai/editor_actions/generate_description';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import EditedAt from '~/issues/show/components/edited.vue';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import {
  findDescriptionWidget,
  newWorkItemId,
  newWorkItemFullPath,
  autocompleteDataSources,
} from '~/work_items/utils';
import projectPermissionsQuery from '../graphql/ai_permissions_for_project.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import workItemDescriptionTemplateQuery from '../graphql/work_item_description_template.query.graphql';
import namespacePathsQuery from '../graphql/namespace_paths.query.graphql';
import { i18n, NEW_WORK_ITEM_IID, TRACKING_CATEGORY_SHOW, ROUTES } from '../constants';
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
  mixins: [Tracking.mixin()],
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
    newWorkItemType: {
      type: String,
      required: false,
      default: '',
    },
    withoutHeadingAnchors: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCreateFlow: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideFullscreenMarkdownButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    truncationEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  markdownDocsPath: helpPagePath('user/markdown'),
  data() {
    return {
      workItem: {},
      wasEdited: false,
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
      workspacePermissions: {},
      markdownPaths: {},
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
        const hasContent = this.descriptionText.trim() !== '';
        if (this.descriptionTemplate === this.descriptionText) {
          return;
        }

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
    workspacePermissions: {
      query() {
        return projectPermissionsQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace || {};
      },
      skip() {
        return this.isGroup;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    markdownPaths: {
      query: namespacePathsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
          workItemTypeId: this.workItem?.workItemType?.id,
        };
      },
      update(data) {
        return data?.namespace?.markdownPaths || {};
      },
      skip() {
        return !this.fullPath || !this.workItemIid || !this.workItem?.workItemType?.id;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    createFlow() {
      return this.workItemId === newWorkItemId(this.newWorkItemType);
    },
    editorAiActions() {
      const { id, userPermissions } = this.workspacePermissions;
      return userPermissions?.generateDescription
        ? [generateDescriptionAction({ resourceId: id })]
        : [];
    },
    workItemFullPath() {
      return this.createFlow
        ? newWorkItemFullPath(this.fullPath, this.newWorkItemType)
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
    // eslint-disable-next-line vue/no-unused-properties
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_description',
        property: `type_${this.workItemType}`,
      };
    },
    workItemDescription() {
      const descriptionWidget = findDescriptionWidget(this.workItem);
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
      return this.workItemNamespaceId.includes(TYPENAME_GROUP);
    },
    workItemNamespaceId() {
      return this.workItem?.namespace?.id || '';
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
    restrictedToolBarItems() {
      if (this.hideFullscreenMarkdownButton) {
        return ['full-screen'];
      }
      return [];
    },
    enableTruncation() {
      /* truncationEnabled uses the local storage based setting,
         wasEdited is a localized override for when user actions on this work item
         should result in a full description shown. */
      return this.truncationEnabled && !this.wasEdited;
    },
    markdownPathsLoaded() {
      return !isEmpty(this.markdownPaths);
    },
    uploadsPath() {
      return this.markdownPaths.uploadsPath;
    },
    markdownPreviewPath() {
      return this.markdownPaths.markdownPreviewPath;
    },
    autocompleteDataSources() {
      const isNewWorkItemInGroup = this.isGroup && this.workItemIid === NEW_WORK_ITEM_IID;
      const sources = autocompleteDataSources({
        fullPath: this.fullPath,
        isGroup: this.isGroupWorkItem || isNewWorkItemInGroup,
        iid: this.workItemIid,
        workItemTypeId: this.workItem?.workItemType?.id,
        markdownPaths: this.markdownPaths,
      });

      return sources;
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
    const DEFAULT_TEMPLATE_NAME = 'default';
    const templateNameFromRoute =
      this.$route?.query[paramName] || this.$route?.query[oldParamNameFromPreWorkItems];
    const templateName = !this.isNewWorkItemRoute
      ? DEFAULT_TEMPLATE_NAME
      : templateNameFromRoute || DEFAULT_TEMPLATE_NAME;

    // Ensure that template is set during Create Flow only if any of the following is true:;
    // - Template name is present in URL.
    // - Description is empty.
    if (this.isCreateFlow && (templateNameFromRoute || this.descriptionText.trim() === '')) {
      this.selectedTemplate = {
        name: templateName,
        projectId: null,
        category: null,
      };
    }
  },
  methods: {
    checkForConflicts() {
      if (this.initialDescriptionText.trim() !== this.workItemDescription?.description.trim()) {
        this.conflictedDescription = this.workItemDescription?.description;
      }
    },
    async startEditing() {
      this.isEditing = true;
      this.wasEdited = true;

      if (this.createFlow) {
        this.descriptionText = this.workItemDescription?.description;
      } else {
        const draftDescription = getDraft(this.autosaveKey) || '';
        if (draftDescription.trim() !== '') {
          this.descriptionText = draftDescription;
        } else {
          this.descriptionText = this.workItemDescription?.description;
        }
      }

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
    setDescriptionText(newText, onMountInit = false) {
      this.descriptionText = newText;
      // Ensure that we don't update the draft on mount during create mode as
      // it will otherwise overwrite localStorage and previously saved data
      // will be lost. See vue_shared/components/markdown/markdown_editor.vue
      // mounted hook where onMountInit boolean is passed with $emit('input').
      if (!onMountInit || !this.isCreateFlow) {
        this.$emit('updateDraft', this.descriptionText);
      }
      updateDraft(this.autosaveKey, this.descriptionText);
    },
    handleDescriptionTextUpdated(newText) {
      this.wasEdited = true;
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

      const params = new URLSearchParams(this.$route?.query);
      params.delete(paramName);
      params.delete(oldParamNameFromPreWorkItems);
      if (this.selectedTemplate && this.isNewWorkItemRoute) {
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
    handleEscape() {
      // Don't cancel if autosuggest open in plain text editor
      if (
        !this.$refs.markdownEditor.$el
          .querySelector('textarea')
          ?.classList.contains('at-who-active')
      ) {
        if (this.isCreateFlow) {
          this.$emit('cancelCreate');
        } else {
          this.cancelEditing();
        }
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
      >
        <work-item-description-template-listbox
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
          v-if="markdownPathsLoaded"
          ref="markdownEditor"
          :value="descriptionText"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="$options.markdownDocsPath"
          :form-field-props="formFieldProps"
          :quick-actions-docs-path="$options.quickActionsDocsPath"
          :autocomplete-data-sources="autocompleteDataSources"
          :restricted-tool-bar-items="restrictedToolBarItems"
          :uploads-path="uploadsPath"
          :editor-ai-actions="editorAiActions"
          enable-autocomplete
          supports-quick-actions
          :autofocus="autofocus"
          class="gl-mt-3"
          @input="setDescriptionText"
          @keydown.meta.enter="updateWorkItem"
          @keydown.ctrl.enter="updateWorkItem"
          @keydown.esc.stop="handleEscape"
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
      :full-path="fullPath"
      :work-item-description="workItemDescription"
      :work-item-id="workItemId"
      :work-item-type="workItemType"
      :can-edit="canEdit"
      :enable-truncation="enableTruncation"
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
