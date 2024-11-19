<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput, GlLink } from '@gitlab/ui';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import { joinPaths } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { titleQueries } from 'ee_else_ce/boards/constants';
import { setError } from '../../graphql/cache_updates';

export default {
  components: {
    GlForm,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLink,
    BoardEditableItem,
  },
  directives: {
    autofocusonshow,
  },
  inject: ['fullPath', 'issuableType', 'isEpicBoard'],
  props: {
    activeItem: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      title: '',
      loading: false,
      showChangesAlert: false,
    };
  },
  computed: {
    pendingChangesStorageKey() {
      return this.getPendingChangesKey(this.activeItem);
    },
    projectPath() {
      const referencePath = this.activeItem.referencePath || '';
      return referencePath.slice(0, referencePath.indexOf('#'));
    },
    validationState() {
      return Boolean(this.title);
    },
  },
  watch: {
    activeItem: {
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
      const shouldOpen = pendingChanges !== this.title;

      if (pendingChanges && shouldOpen) {
        this.title = pendingChanges;
        this.showChangesAlert = true;
        await this.$nextTick();
        this.$refs.sidebarItem.expand();
      } else {
        this.showChangesAlert = false;
      }
    },
    cancel() {
      this.title = this.activeItem.title;
      this.$refs.sidebarItem.collapse();
      this.showChangesAlert = false;
      localStorage.removeItem(this.pendingChangesStorageKey);
    },
    async setActiveBoardItemTitle() {
      const { fullPath, issuableType, isEpicBoard, title } = this;
      const workspacePath = isEpicBoard
        ? { groupPath: fullPath }
        : { projectPath: this.projectPath };
      await this.$apollo.mutate({
        mutation: titleQueries[issuableType].mutation,
        variables: {
          input: {
            ...workspacePath,
            iid: String(this.activeItem.iid),
            title,
          },
        },
      });
    },
    async setTitle() {
      this.$refs.sidebarItem.collapse();

      if (!this.title || this.title === this.activeItem.title) {
        return;
      }

      try {
        this.loading = true;
        await this.setActiveBoardItemTitle();
        localStorage.removeItem(this.pendingChangesStorageKey);
        this.showChangesAlert = false;
      } catch (e) {
        this.title = this.activeItem.title;
        setError({ error: e, message: this.$options.i18n.updateTitleError });
      } finally {
        this.loading = false;
      }
    },
    handleOffClick() {
      if (this.title !== this.activeItem.title) {
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
      <span data-testid="item-title">
        <gl-link class="gl-text-inherit hover:gl-text-blue-800" :href="activeItem.webUrl">
          {{ activeItem.title }}
        </gl-link>
      </span>
    </template>
    <template #collapsed>
      <span class="gl-text-default">{{ activeItem.referencePath }}</span>
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

      <div class="gl-mt-5 gl-flex gl-w-full gl-justify-between">
        <gl-button
          variant="confirm"
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
