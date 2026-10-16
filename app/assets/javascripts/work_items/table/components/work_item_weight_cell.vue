<script>
import { GlButton, GlFormInput, GlLoadingIcon, GlToastMixin } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import { findWeightWidget } from '../../utils';

const ERROR_UPDATING_WEIGHT = s__('WorkItem|Something went wrong while updating the weight.');

export default {
  name: 'WorkItemWeightCell',
  components: {
    GlButton,
    GlFormInput,
    GlLoadingIcon,
  },
  mixins: [GlToastMixin, glFeatureFlagsMixin()],
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
      editedWeight: null,
    };
  },
  computed: {
    canEdit() {
      return Boolean(findWeightWidget(this.item)) && this.item.userPermissions?.updateWorkItem;
    },
    weight() {
      return findWeightWidget(this.item)?.weight;
    },
    displayWeight() {
      return this.weight ?? '';
    },
    isValid() {
      if (this.editedWeight === null || this.editedWeight === '') return true;
      const num = parseInt(this.editedWeight, 10);
      return !Number.isNaN(num) && num >= 0 && String(num) === String(this.editedWeight).trim();
    },
  },
  methods: {
    startEditing() {
      if (!this.canEdit) return;

      this.editedWeight = this.weight ?? '';
      this.isEditing = true;
      this.$nextTick(() => {
        this.$refs.weightInput?.$el?.focus();
        this.$refs.weightInput?.$el?.select();
      });
    },
    cancelEditing() {
      this.isEditing = false;
      this.editedWeight = null;
      this.$nextTick(() => {
        this.$refs.editButton?.$el?.focus();
      });
    },
    async saveWeight() {
      if (!this.isValid || this.isSaving) return;

      const isEmpty = this.editedWeight === '' || this.editedWeight === null;
      const newWeight = isEmpty ? null : parseInt(this.editedWeight, 10);

      if (newWeight === this.weight) {
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
              weightWidget: {
                weight: newWeight,
              },
            },
            useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
          },
        });

        const errors = data?.workItemUpdate?.errors;
        if (errors?.length) {
          this.$toast.show(ERROR_UPDATING_WEIGHT);
          Sentry.captureException(
            new Error(`Work item weight update failed on table view: ${errors.join(', ')}`),
          );
        } else {
          this.cancelEditing();
        }
      } catch (error) {
        this.$toast.show(ERROR_UPDATING_WEIGHT);
        Sentry.captureException(error);
      } finally {
        this.isSaving = false;
      }
    },
    handleBlur() {
      if (!this.isEditing) return;

      if (!this.isValid) {
        this.cancelEditing();
        return;
      }

      this.saveWeight();
    },
    handleKeydown(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        this.saveWeight();
      } else if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        this.cancelEditing();
      }
    },
  },
};
</script>

<template>
  <span class="gl-flex gl-items-center gl-gap-2" :class="{ 'gl-group': !isEditing }">
    <template v-if="!isEditing">
      <span data-testid="weight-value">{{ displayWeight }}</span>
      <gl-button
        v-if="canEdit"
        ref="editButton"
        icon="pencil"
        category="tertiary"
        size="small"
        :aria-label="s__('WorkItem|Edit weight')"
        class="gl-ml-auto gl-shrink-0 gl-opacity-0 gl-transition-opacity focus:gl-opacity-10 group-hover:gl-opacity-10"
        data-testid="edit-weight-button"
        @click.stop="startEditing"
      />
    </template>

    <template v-else>
      <span class="gl-contents" @click.stop>
        <gl-form-input
          ref="weightInput"
          v-model="editedWeight"
          type="number"
          :aria-label="s__('WorkItem|Weight')"
          min="0"
          step="1"
          :state="isValid"
          :disabled="isSaving"
          class="-gl-ml-1 gl-min-w-0 gl-flex-grow !gl-px-1 !gl-py-2 !gl-text-sm"
          data-testid="weight-input"
          @keydown="handleKeydown"
          @blur="handleBlur"
        />
      </span>
      <gl-loading-icon v-if="isSaving" size="sm" inline class="gl-shrink-0" />
      <span v-if="isSaving" class="gl-sr-only" aria-live="polite">
        {{ s__('WorkItem|Saving weight') }}
      </span>
    </template>
  </span>
</template>
