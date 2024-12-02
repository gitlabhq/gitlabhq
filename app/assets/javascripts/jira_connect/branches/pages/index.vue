<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlEmptyState } from '@gitlab/ui';
import { sprintf } from '~/locale';
import NewBranchForm from '../components/new_branch_form.vue';
import {
  I18N_PAGE_TITLE_WITH_BRANCH_NAME,
  I18N_PAGE_TITLE_DEFAULT,
  I18N_NEW_BRANCH_SUCCESS_TITLE,
  I18N_NEW_BRANCH_SUCCESS_MESSAGE,
} from '../constants';

export default {
  components: {
    GlEmptyState,
    NewBranchForm,
  },
  inject: ['initialBranchName', 'successStateSvgPath'],
  data() {
    return {
      showForm: true,
    };
  },
  computed: {
    pageTitle() {
      return this.initialBranchName
        ? sprintf(this.$options.i18n.I18N_PAGE_TITLE_WITH_BRANCH_NAME, {
            jiraIssue: this.initialBranchName,
          })
        : this.$options.i18n.I18N_PAGE_TITLE_DEFAULT;
    },
  },
  methods: {
    onNewBranchFormSuccess() {
      // light-weight toggle to hide the form and show the success state
      this.showForm = false;
    },
  },
  i18n: {
    I18N_PAGE_TITLE_WITH_BRANCH_NAME,
    I18N_PAGE_TITLE_DEFAULT,
    I18N_NEW_BRANCH_SUCCESS_TITLE,
    I18N_NEW_BRANCH_SUCCESS_MESSAGE,
  },
};
</script>
<template>
  <div>
    <div class="gl-mb-5 gl-mt-7 gl-border-1 gl-border-default gl-border-b-solid">
      <h1 data-testid="page-title" class="page-title gl-text-size-h-display">{{ pageTitle }}</h1>
    </div>

    <new-branch-form v-if="showForm" @success="onNewBranchFormSuccess" />
    <gl-empty-state
      v-else
      :title="$options.i18n.I18N_NEW_BRANCH_SUCCESS_TITLE"
      :description="$options.i18n.I18N_NEW_BRANCH_SUCCESS_MESSAGE"
      :svg-path="successStateSvgPath"
      :svg-height="null"
    />
  </div>
</template>
