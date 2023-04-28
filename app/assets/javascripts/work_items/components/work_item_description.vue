<script>
import { GlAlert, GlButton, GlFormGroup } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { __, s__ } from '~/locale';
import EditedAt from '~/issues/show/components/edited.vue';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { autocompleteDataSources, markdownPreviewPath } from '../utils';
import workItemDescriptionSubscription from '../graphql/work_item_description.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { i18n, TRACKING_CATEGORY_SHOW, WIDGET_TYPE_DESCRIPTION } from '../constants';
import WorkItemDescriptionRendered from './work_item_description_rendered.vue';

export default {
  components: {
    EditedAt,
    GlAlert,
    GlButton,
    GlFormGroup,
    MarkdownEditor,
    MarkdownField,
    WorkItemDescriptionRendered,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin()],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  markdownDocsPath: helpPagePath('user/project/quick_actions'),
  quickActionsDocsPath: helpPagePath('user/project/quick_actions'),
  data() {
    return {
      workItem: {},
      isEditing: false,
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
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.workspace.workItems.nodes[0];
      },
      skip() {
        return !this.queryVariables.iid;
      },
      result() {
        if (this.isEditing) {
          this.checkForConflicts();
        }
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      subscribeToMore: {
        document: workItemDescriptionSubscription,
        variables() {
          return {
            issuableId: this.workItemId,
          };
        },
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
      return markdownPreviewPath(this.fullPath, this.workItem.iid);
    },
    autocompleteDataSources() {
      return autocompleteDataSources(this.fullPath, this.workItem.iid);
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
      updateDraft(this.autosaveKey, this.descriptionText);
    },
    handleDescriptionTextUpdated(newText) {
      this.descriptionText = newText;
      this.updateWorkItem();
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      v-if="isEditing"
      class="gl-mb-5 gl-border-t gl-pt-6"
      :label="__('Description')"
      label-for="work-item-description"
    >
      <markdown-editor
        v-if="glFeatures.workItemsMvc"
        class="gl-my-3 common-note-form"
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
      <markdown-field
        v-else
        can-attach-file
        :textarea-value="descriptionText"
        :is-submitting="isSubmitting"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="$options.markdownDocsPath"
        :quick-actions-docs-path="$options.quickActionsDocsPath"
        :autocomplete-data-sources="autocompleteDataSources"
        class="gl-px-3 bordered-box gl-mt-5"
      >
        <template #textarea>
          <textarea
            v-bind="formFieldProps"
            ref="textarea"
            v-model="descriptionText"
            :disabled="isSubmitting"
            class="note-textarea js-gfm-input js-autosize markdown-area"
            dir="auto"
            data-supports-quick-actions="true"
            @keydown.meta.enter="updateWorkItem"
            @keydown.ctrl.enter="updateWorkItem"
            @keydown.exact.esc.stop="cancelEditing"
            @input="onInput"
          ></textarea>
        </template>
      </markdown-field>
      <div class="gl-display-flex">
        <gl-alert
          v-if="hasConflicts"
          :dismissible="false"
          variant="danger"
          class="gl-w-full"
          data-testid="work-item-description-conflicts"
        >
          <p>
            {{
              s__(
                "WorkItem|Someone edited the description at the same time you did. If you save it will overwrite their changes. Please confirm you'd like to save your edits.",
              )
            }}
          </p>
          <details class="gl-mb-5">
            <summary class="gl-text-blue-500">{{ s__('WorkItem|View current version') }}</summary>
            <textarea
              class="note-textarea js-gfm-input js-autosize markdown-area gl-p-3"
              readonly
              :value="conflictedDescription"
            ></textarea>
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
            @click="updateWorkItem"
            >{{ __('Save') }}
          </gl-button>
          <gl-button category="tertiary" class="gl-ml-3" data-testid="cancel" @click="cancelEditing"
            >{{ __('Cancel') }}
          </gl-button>
        </template>
      </div>
    </gl-form-group>
    <work-item-description-rendered
      v-else
      :work-item-description="workItemDescription"
      :can-edit="canEdit"
      @startEditing="startEditing"
      @descriptionUpdated="handleDescriptionTextUpdated"
    />
    <edited-at
      v-if="lastEditedAt"
      :updated-at="lastEditedAt"
      :updated-by-name="lastEditedByName"
      :updated-by-path="lastEditedByPath"
    />
  </div>
</template>
