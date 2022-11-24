<script>
import { GlButton, GlFormGroup } from '@gitlab/ui';
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
import { getWorkItemQuery } from '../utils';
import workItemDescriptionSubscription from '../graphql/work_item_description.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW, WIDGET_TYPE_DESCRIPTION } from '../constants';
import WorkItemDescriptionRendered from './work_item_description_rendered.vue';

export default {
  components: {
    EditedAt,
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
    fetchByIid: {
      type: Boolean,
      required: false,
      default: false,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  markdownDocsPath: helpPagePath('user/markdown'),
  data() {
    return {
      workItem: {},
      isEditing: false,
      isSubmitting: false,
      isSubmittingWithKeydown: false,
      descriptionText: '',
      descriptionHtml: '',
    };
  },
  apollo: {
    workItem: {
      query() {
        return getWorkItemQuery(this.fetchByIid);
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return this.fetchByIid ? data.workspace.workItems.nodes[0] : data.workItem;
      },
      skip() {
        return !this.queryVariables.id && !this.queryVariables.iid;
      },
      result() {
        this.descriptionText = this.workItemDescription?.description;
        this.descriptionHtml = this.workItemDescription?.descriptionHtml;
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
      return `${gon.relative_url_root || ''}/${this.fullPath}/preview_markdown?target_type=${
        this.workItemType
      }`;
    },
  },
  methods: {
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
        :form-field-aria-label="__('Description')"
        :form-field-placeholder="__('Write a comment or drag your files here…')"
        form-field-id="work-item-description"
        form-field-name="work-item-description"
        enable-autocomplete
        init-on-autofocus
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
        class="gl-p-3 bordered-box gl-mt-5"
      >
        <template #textarea>
          <textarea
            id="work-item-description"
            ref="textarea"
            v-model="descriptionText"
            :disabled="isSubmitting"
            class="note-textarea js-gfm-input js-autosize markdown-area"
            dir="auto"
            data-supports-quick-actions="false"
            :aria-label="__('Description')"
            :placeholder="__('Write a comment or drag your files here…')"
            @keydown.meta.enter="updateWorkItem"
            @keydown.ctrl.enter="updateWorkItem"
            @keydown.exact.esc.stop="cancelEditing"
            @input="onInput"
          ></textarea>
        </template>
      </markdown-field>
      <div class="gl-display-flex">
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
