<script>
import { GlButton, GlFormInput, GlLoadingIcon, GlToastMixin, GlTruncate } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import { TITLE_LENGTH_MAX } from '~/issues/constants';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';

export default {
  name: 'WorkItemTitleCell',
  components: {
    GlButton,
    GlFormInput,
    GlLoadingIcon,
    GlTruncate,
    WorkItemTypeIcon,
  },
  mixins: [GlToastMixin],
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      isSaving: false,
      editedTitle: '',
    };
  },
  computed: {
    canEdit() {
      return this.item.userPermissions?.updateWorkItem;
    },
    isValid() {
      return this.editedTitle.trim().length > 0 && this.editedTitle.length <= TITLE_LENGTH_MAX;
    },
  },
  methods: {
    startEditing() {
      if (!this.canEdit) return;

      this.editedTitle = this.item.title;
      this.isEditing = true;
      this.$nextTick(() => {
        this.$refs.titleInput?.$el?.focus();
      });
    },
    cancelEditing() {
      this.isEditing = false;
      this.editedTitle = '';
      this.$nextTick(() => {
        this.$refs.editButton?.$el?.focus();
      });
    },
    async saveTitle() {
      if (!this.isValid || this.isSaving) return;

      const trimmedTitle = this.editedTitle.trim();

      if (trimmedTitle === this.item.title) {
        this.cancelEditing();
        return;
      }

      this.isSaving = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.item.id,
              title: trimmedTitle,
            },
          },
        });

        const errors = data?.workItemUpdate?.errors;
        if (errors?.length) {
          this.$toast.show(s__('WorkItem|Something went wrong while updating the title.'));
          Sentry.captureException(new Error(`Work item title update failed: ${errors.join(', ')}`));
        } else {
          this.cancelEditing();
        }
      } catch (error) {
        this.$toast.show(s__('WorkItem|Something went wrong while updating the title.'));
        Sentry.captureException(error);
      } finally {
        this.isSaving = false;
      }
    },
    handleBlur() {
      if (!this.isEditing) return;
      this.saveTitle();
    },
    handleKeydown(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        this.saveTitle();
      } else if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        this.cancelEditing();
      }
    },
  },
  TITLE_LENGTH_MAX,
};
</script>

<template>
  <span class="gl-flex gl-items-center gl-gap-2" :class="{ 'gl-group': !isEditing }">
    <work-item-type-icon
      v-if="item.workItemType"
      :work-item-type="item.workItemType.name"
      :type-icon-name="item.workItemType.iconName"
      icon-variant="subtle"
      class="gl-shrink-0"
    />

    <template v-if="!isEditing">
      <a
        :href="item.webPath"
        class="gl-min-w-0 gl-text-default hover:gl-text-default"
        data-testid="work-item-link"
      >
        <gl-truncate :text="item.title" with-tooltip />
      </a>
      <gl-button
        v-if="canEdit"
        ref="editButton"
        icon="pencil"
        category="tertiary"
        size="small"
        :aria-label="s__('WorkItem|Edit title')"
        class="gl-ml-auto gl-shrink-0 gl-opacity-0 gl-transition-opacity focus:gl-opacity-10 group-hover:gl-opacity-10"
        data-testid="edit-title-button"
        @click.stop="startEditing"
      />
    </template>

    <template v-else>
      <span class="gl-contents" @click.stop>
        <gl-form-input
          ref="titleInput"
          v-model="editedTitle"
          :state="isValid"
          :disabled="isSaving"
          :maxlength="$options.TITLE_LENGTH_MAX"
          class="-gl-ml-1 gl-min-w-0 gl-flex-grow !gl-px-1 !gl-py-2 !gl-text-sm"
          @keydown="handleKeydown"
          @blur="handleBlur"
        />
      </span>
      <gl-loading-icon v-if="isSaving" size="sm" inline class="gl-shrink-0" />
      <span v-if="isSaving" class="gl-sr-only" aria-live="polite">
        {{ s__('WorkItem|Saving title') }}
      </span>
    </template>
  </span>
</template>
