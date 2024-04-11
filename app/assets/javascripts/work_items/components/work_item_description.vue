<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import EditedAt from '~/issues/show/components/edited.vue';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { autocompleteDataSources, markdownPreviewPath } from '../utils';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { i18n, TRACKING_CATEGORY_SHOW, WIDGET_TYPE_DESCRIPTION } from '../constants';
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
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    disableInlineEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    editMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    updateInProgress: {
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
      query() {
        return this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItems.nodes[0];
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
    autosaveKey() {
      return this.workItemId;
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
    lastEditedAt() {
      return this.workItemDescription?.lastEditedAt;
    },
    lastEditedByName() {
      return this.workItemDescription?.lastEditedBy?.name;
    },
    lastEditedByPath() {
      return this.workItemDescription?.lastEditedBy?.webPath;
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
      const {
        fullPath,
        isGroup,
        workItem: { iid },
      } = this;
      return autocompleteDataSources({ fullPath, iid, isGroup });
    },
    saveButtonText() {
      return this.editMode ? __('Save changes') : __('Save');
    },
    formGroupClass() {
      return {
        'gl-border-t gl-pt-6': !this.disableInlineEditing,
        'gl-mb-5 common-note-form': true,
      };
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

      if (this.disableInlineEditing) {
        this.$emit('updateWorkItem');
        return;
      }

      this.isSubmitting = true;

      try {
        this.track('updated_description');

        const {
          data: { workItemUpdate },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItem.id,
              descriptionWidget: {
                description: this.descriptionText,
              },
            },
          },
        });

        if (workItemUpdate.errors?.length) {
          throw new Error(workItemUpdate.errors[0]);
        }

        this.isEditing = false;
        clearDraft(this.autosaveKey);
        this.conflictedDescription = '';
      } catch (error) {
        this.$emit('error', error.message);
        Sentry.captureException(error);
      }

      this.isSubmitting = false;
    },
    setDescriptionText(newText) {
      this.descriptionText = newText;
      if (this.disableInlineEditing) {
        this.$emit('updateDraft', this.descriptionText);
      }
      updateDraft(this.autosaveKey, this.descriptionText);
    },
    handleDescriptionTextUpdated(newText) {
      this.descriptionText = newText;
      if (this.disableInlineEditing) {
        this.$emit('updateDraft', this.descriptionText);
      }
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
        :label-sr-only="disableInlineEditing"
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
          autofocus
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
                class="js-gfm-input js-autosize markdown-area gl-font-monospace!"
                data-testid="conflicted-description"
                readonly
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
          <template v-else>
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
      :disable-inline-editing="disableInlineEditing"
      :work-item-description="workItemDescription"
      :can-edit="canEdit"
      :disable-truncation="disableTruncation"
      @startEditing="startEditing"
      @descriptionUpdated="handleDescriptionTextUpdated"
    />
    <edited-at
      v-if="lastEditedAt && !editMode"
      :updated-at="lastEditedAt"
      :updated-by-name="lastEditedByName"
      :updated-by-path="lastEditedByPath"
    />
  </div>
</template>
