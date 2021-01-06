<script>
import { mapGetters, mapActions } from 'vuex';
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { joinPaths } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { __ } from '~/locale';

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
    ...mapGetters({ issue: 'activeIssue' }),
    pendingChangesStorageKey() {
      return this.getPendingChangesKey(this.issue);
    },
    projectPath() {
      const referencePath = this.issue.referencePath || '';
      return referencePath.slice(0, referencePath.indexOf('#'));
    },
    validationState() {
      return Boolean(this.title);
    },
  },
  watch: {
    issue: {
      handler(updatedIssue, formerIssue) {
        if (formerIssue?.title !== this.title) {
          localStorage.setItem(this.getPendingChangesKey(formerIssue), this.title);
        }

        this.title = updatedIssue.title;
        this.setPendingState();
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['setActiveIssueTitle']),
    getPendingChangesKey(issue) {
      if (!issue) {
        return '';
      }

      return joinPaths(
        window.location.pathname.slice(1),
        String(issue.id),
        'issue-title-pending-changes',
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
      this.title = this.issue.title;
      this.$refs.sidebarItem.collapse();
      this.showChangesAlert = false;
      localStorage.removeItem(this.pendingChangesStorageKey);
    },
    async setTitle() {
      this.$refs.sidebarItem.collapse();

      if (!this.title || this.title === this.issue.title) {
        return;
      }

      try {
        this.loading = true;
        await this.setActiveIssueTitle({ title: this.title, projectPath: this.projectPath });
        localStorage.removeItem(this.pendingChangesStorageKey);
        this.showChangesAlert = false;
      } catch (e) {
        this.title = this.issue.title;
        createFlash({ message: this.$options.i18n.updateTitleError });
      } finally {
        this.loading = false;
      }
    },
    handleOffClick() {
      if (this.title !== this.issue.title) {
        this.showChangesAlert = true;
        localStorage.setItem(this.pendingChangesStorageKey, this.title);
      } else {
        this.$refs.sidebarItem.collapse();
      }
    },
  },
  i18n: {
    issueTitlePlaceholder: __('Issue title'),
    submitButton: __('Save changes'),
    cancelButton: __('Cancel'),
    updateTitleError: __('An error occurred when updating the issue title'),
    invalidFeedback: __('An issue title is required'),
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
      <span class="gl-font-weight-bold" data-testid="issue-title">{{ issue.title }}</span>
    </template>
    <template #collapsed>
      <span class="gl-text-gray-800">{{ issue.referencePath }}</span>
    </template>
    <template>
      <gl-alert v-if="showChangesAlert" variant="warning" class="gl-mb-5" :dismissible="false">
        {{ $options.i18n.reviewYourChanges }}
      </gl-alert>
      <gl-form @submit.prevent="setTitle">
        <gl-form-group :invalid-feedback="$options.i18n.invalidFeedback" :state="validationState">
          <gl-form-input
            v-model="title"
            v-autofocusonshow
            :placeholder="$options.i18n.issueTitlePlaceholder"
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
    </template>
  </board-editable-item>
</template>
