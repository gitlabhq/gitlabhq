<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlCard,
  GlIcon,
  GlLink,
  GlModal,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  i18n: {
    modalDelete: __('Delete'),
    modalDescription: s__('Incident|Are you sure you wish to delete this image?'),
    modalCancel: __('Cancel'),
    modalTitle: s__('Incident|Deleting %{filename}'),
    editModalUpdate: __('Update'),
    editModalTitle: s__('Incident|Editing %{filename}'),
    editIconTitle: s__('Incident|Edit image text or link'),
    deleteIconTitle: s__('Incident|Delete image'),
  },
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlCard,
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canUpdate'],
  props: {
    id: {
      type: Number,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    filename: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: false,
      default: null,
    },
    urlText: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isCollapsed: false,
      isDeleting: false,
      isUpdating: false,
      modalVisible: false,
      editModalVisible: false,
      modalUrl: this.url,
      modalUrlText: this.urlText,
    };
  },
  computed: {
    deleteActionPrimaryProps() {
      return {
        text: this.$options.i18n.modalDelete,
        attributes: {
          loading: this.isDeleting,
          disabled: this.isDeleting,
          category: 'primary',
          variant: 'danger',
        },
      };
    },
    updateActionPrimaryProps() {
      return {
        text: this.$options.i18n.editModalUpdate,
        attributes: {
          loading: this.isUpdating,
          disabled: this.isUpdating,
          category: 'primary',
          variant: 'confirm',
        },
      };
    },
    arrowIconName() {
      return this.isCollapsed ? 'chevron-right' : 'chevron-down';
    },
    bodyClass() {
      return [
        'gl-border-1',
        'gl-border-t-solid',
        'gl-border-gray-100',
        { 'gl-display-none': this.isCollapsed },
      ];
    },
  },
  methods: {
    ...mapActions(['deleteImage', 'updateImage']),
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
    resetEditFields() {
      this.modalUrl = this.url;
      this.modalUrlText = this.urlText;
      this.editModalVisible = false;
      this.modalVisible = false;
    },
    async onDelete() {
      try {
        this.isDeleting = true;
        await this.deleteImage(this.id);
      } finally {
        this.isDeleting = false;
        this.modalVisible = false;
      }
    },
    async onUpdate() {
      try {
        this.isUpdating = true;
        await this.updateImage({
          imageId: this.id,
          url: this.modalUrl,
          urlText: this.modalUrlText,
        });
      } finally {
        this.isUpdating = false;
        this.modalUrl = '';
        this.modalUrlText = '';
        this.editModalVisible = false;
      }
    },
  },
};
</script>

<template>
  <gl-card
    class="collapsible-card border gl-p-0 gl-mb-5"
    header-class="gl-display-flex gl-align-items-center gl-border-b-0 gl-py-3"
    :body-class="bodyClass"
  >
    <gl-modal
      body-class="gl-pb-0! gl-min-h-6!"
      modal-id="delete-metric-modal"
      size="sm"
      :visible="modalVisible"
      :action-primary="deleteActionPrimaryProps"
      :action-cancel="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.modalCancel,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      @primary.prevent="onDelete"
      @hidden="resetEditFields"
    >
      <template #modal-title>
        <gl-sprintf :message="$options.i18n.modalTitle">
          <template #filename>
            {{ filename }}
          </template>
        </gl-sprintf>
      </template>
      <p>{{ $options.i18n.modalDescription }}</p>
    </gl-modal>

    <gl-modal
      modal-id="edit-metric-modal"
      size="sm"
      :action-primary="updateActionPrimaryProps"
      :action-cancel="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.modalCancel,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :visible="editModalVisible"
      data-testid="metric-image-edit-modal"
      @hidden="resetEditFields"
      @primary.prevent="onUpdate"
    >
      <template #modal-title>
        <gl-sprintf :message="$options.i18n.editModalTitle">
          <template #filename>
            {{ filename }}
          </template>
        </gl-sprintf>
      </template>

      <gl-form-group :label="__('Text (optional)')" label-for="upload-text-input">
        <gl-form-input
          id="upload-text-input"
          v-model="modalUrlText"
          data-testid="metric-image-text-field"
        />
      </gl-form-group>

      <gl-form-group
        :label="__('Link (optional)')"
        label-for="upload-url-input"
        :description="s__('Incidents|Must start with http or https')"
      >
        <gl-form-input
          id="upload-url-input"
          v-model="modalUrl"
          data-testid="metric-image-url-field"
        />
      </gl-form-group>
    </gl-modal>

    <template #header>
      <div class="gl-w-full gl-display-flex gl-flex-direction-row gl-justify-content-space-between">
        <div class="gl-display-flex gl-flex-direction-row gl-align-items-center gl-w-full">
          <gl-button
            class="collapsible-card-btn gl-display-flex gl-text-decoration-none gl-reset-color! gl-hover-text-blue-800! gl-shadow-none!"
            :aria-label="filename"
            variant="link"
            category="tertiary"
            data-testid="collapse-button"
            @click="toggleCollapsed"
          >
            <gl-icon class="gl-mr-2" :name="arrowIconName" />
          </gl-button>
          <gl-link v-if="url" :href="url" target="_blank" data-testid="metric-image-label-span">
            {{ urlText == null || urlText == '' ? filename : urlText }}
            <gl-icon name="external-link" class="gl-vertical-align-middle" />
          </gl-link>
          <span v-else data-testid="metric-image-label-span">{{
            urlText == null || urlText == '' ? filename : urlText
          }}</span>
          <div class="gl-ml-auto btn-group">
            <gl-button
              v-if="canUpdate"
              v-gl-tooltip.bottom
              icon="pencil"
              :aria-label="__('Edit')"
              :title="$options.i18n.editIconTitle"
              data-testid="edit-button"
              @click="editModalVisible = true"
            />
            <gl-button
              v-if="canUpdate"
              v-gl-tooltip.bottom
              icon="remove"
              :aria-label="__('Delete')"
              :title="$options.i18n.deleteIconTitle"
              data-testid="delete-button"
              @click="modalVisible = true"
            />
          </div>
        </div>
      </div>
    </template>
    <div
      v-show="!isCollapsed"
      class="gl-display-flex gl-flex-direction-column"
      data-testid="metric-image-body"
    >
      <img class="gl-max-w-full gl-align-self-center" :src="filePath" />
    </div>
  </gl-card>
</template>
