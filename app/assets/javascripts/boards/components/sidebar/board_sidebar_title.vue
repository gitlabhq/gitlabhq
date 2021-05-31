<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import { joinPaths } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  components: {
    GlForm,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    BoardEditableItem,
  },
  directives: {
    autofocusonshow,
  },
  data() {
    return {
      title: '',
      loading: false,
      showChangesAlert: false,
    };
  },
  computed: {
    ...mapGetters({ item: 'activeBoardItem' }),
    pendingChangesStorageKey() {
      return this.getPendingChangesKey(this.item);
    },
    projectPath() {
      const referencePath = this.item.referencePath || '';
      return referencePath.slice(0, referencePath.indexOf('#'));
    },
    validationState() {
      return Boolean(this.title);
    },
  },
  watch: {
    item: {
      handler(updatedItem, formerItem) {
        if (formerItem?.title !== this.title) {
          localStorage.setItem(this.getPendingChangesKey(formerItem), this.title);
        }

        this.title = updatedItem.title;
        this.setPendingState();
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['setActiveItemTitle', 'setError']),
    getPendingChangesKey(item) {
      if (!item) {
        return '';
      }

      return joinPaths(
        window.location.pathname.slice(1),
        String(item.id),
        'item-title-pending-changes',
      );
    },
    async setPendingState() {
      const pendingChanges = localStorage.getItem(this.pendingChangesStorageKey);

      if (pendingChanges) {
        this.title = pendingChanges;
        this.showChangesAlert = true;
        await this.$nextTick();
        this.$refs.sidebarItem.expand();
      } else {
        this.showChangesAlert = false;
      }
    },
    cancel() {
      this.title = this.item.title;
      this.$refs.sidebarItem.collapse();
      this.showChangesAlert = false;
      localStorage.removeItem(this.pendingChangesStorageKey);
    },
    async setTitle() {
      this.$refs.sidebarItem.collapse();

      if (!this.title || this.title === this.item.title) {
        return;
      }

      try {
        this.loading = true;
        await this.setActiveItemTitle({ title: this.title, projectPath: this.projectPath });
        localStorage.removeItem(this.pendingChangesStorageKey);
        this.showChangesAlert = false;
      } catch (e) {
        this.title = this.item.title;
        this.setError({ error: e, message: this.$options.i18n.updateTitleError });
      } finally {
        this.loading = false;
      }
    },
    handleOffClick() {
      if (this.title !== this.item.title) {
        this.showChangesAlert = true;
        localStorage.setItem(this.pendingChangesStorageKey, this.title);
      } else {
        this.$refs.sidebarItem.collapse();
      }
    },
  },
  i18n: {
    titlePlaceholder: __('Title'),
    submitButton: __('Save changes'),
    cancelButton: __('Cancel'),
    updateTitleError: __('An error occurred when updating the title'),
    invalidFeedback: __('A title is required'),
    reviewYourChanges: __('Changes to the title have not been saved'),
  },
};
</script>

<template>
  <board-editable-item
    ref="sidebarItem"
    toggle-header
    :loading="loading"
    :handle-off-click="false"
    @off-click="handleOffClick"
  >
    <template #title>
      <span class="gl-font-weight-bold" data-testid="item-title">{{ item.title }}</span>
    </template>
    <template #collapsed>
      <span class="gl-text-gray-800">{{ item.referencePath }}</span>
    </template>
    <gl-alert v-if="showChangesAlert" variant="warning" class="gl-mb-5" :dismissible="false">
      {{ $options.i18n.reviewYourChanges }}
    </gl-alert>
    <gl-form @submit.prevent="setTitle">
      <gl-form-group :invalid-feedback="$options.i18n.invalidFeedback" :state="validationState">
        <gl-form-input
          v-model="title"
          v-autofocusonshow
          :placeholder="$options.i18n.titlePlaceholder"
          :state="validationState"
        />
      </gl-form-group>

      <div class="gl-display-flex gl-w-full gl-justify-content-space-between gl-mt-5">
        <gl-button
          variant="success"
          size="small"
          data-testid="submit-button"
          :disabled="!title"
          @click="setTitle"
        >
          {{ $options.i18n.submitButton }}
        </gl-button>

        <gl-button size="small" data-testid="cancel-button" @click="cancel">
          {{ $options.i18n.cancelButton }}
        </gl-button>
      </div>
    </gl-form>
  </board-editable-item>
</template>
