<script>
import { GlTable, GlButton, GlPagination, GlLoadingIcon, GlEmptyState, GlModal } from '@gitlab/ui';

import { __ } from '~/locale';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import csrf from '~/lib/utils/csrf';

export default {
  name: 'DeployKeysTable',
  i18n: {
    pageTitle: __('Public deploy keys'),
    newDeployKeyButtonText: __('New deploy key'),
    emptyStateTitle: __('No public deploy keys'),
    emptyStateDescription: __(
      'Deploy keys grant read/write access to all repositories in your instance',
    ),
    delete: __('Delete deploy key'),
    edit: __('Edit deploy key'),
    pagination: {
      next: __('Next'),
      prev: __('Prev'),
    },
    modal: {
      title: __('Are you sure?'),
      body: __('Are you sure you want to delete this deploy key?'),
    },
    apiErrorMessage: __('An error occurred fetching the public deploy keys. Please try again.'),
  },
  fields: [
    {
      key: 'title',
      label: __('Title'),
    },
    {
      key: 'fingerprint_sha256',
      label: __('Fingerprint (SHA256)'),
    },
    {
      key: 'fingerprint',
      label: __('Fingerprint (MD5)'),
    },
    {
      key: 'projects',
      label: __('Projects with write access'),
    },
    {
      key: 'created',
      label: __('Created'),
    },
    {
      key: 'actions',
      label: __('Actions'),
      tdClass: 'gl-lg-w-1px gl-white-space-nowrap',
      thClass: 'gl-lg-w-1px gl-white-space-nowrap',
    },
  ],
  modal: {
    id: 'delete-deploy-key-modal',
    actionPrimary: {
      text: __('Delete'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  csrf,
  DEFAULT_PER_PAGE,
  components: {
    GlTable,
    GlButton,
    GlPagination,
    TimeAgoTooltip,
    GlLoadingIcon,
    GlEmptyState,
    GlModal,
  },
  inject: ['editPath', 'deletePath', 'createPath', 'emptyStateSvgPath'],
  data() {
    return {
      page: 1,
      totalItems: 0,
      loading: false,
      items: [],
      deployKeyToDelete: null,
    };
  },
  computed: {
    shouldShowTable() {
      return this.totalItems !== 0 || this.loading;
    },
    isModalVisible() {
      return this.deployKeyToDelete !== null;
    },
    deleteAction() {
      return this.deployKeyToDelete === null
        ? null
        : this.deletePath.replace(':id', this.deployKeyToDelete);
    },
  },
  watch: {
    page(newPage) {
      this.fetchDeployKeys(newPage);
    },
  },
  mounted() {
    this.fetchDeployKeys();
  },
  methods: {
    editHref(id) {
      return this.editPath.replace(':id', id);
    },
    projectHref(project) {
      return `/${cleanLeadingSeparator(project.path_with_namespace)}`;
    },
    async fetchDeployKeys(page) {
      this.loading = true;
      try {
        const { headers, data: items } = await Api.deployKeys({
          page,
          public: true,
        });

        if (this.totalItems === 0) {
          this.totalItems = parseInt(headers?.['x-total'], 10) || 0;
        }

        this.items = items.map(
          ({
            id,
            title,
            fingerprint,
            fingerprint_sha256,
            projects_with_write_access: projects,
            created_at: created,
          }) => ({
            id,
            title,
            fingerprint,
            fingerprint_sha256,
            projects,
            created,
          }),
        );
      } catch (error) {
        createAlert({
          message: this.$options.i18n.apiErrorMessage,
          captureError: true,
          error,
        });

        this.totalItems = 0;

        this.items = [];
      }
      this.loading = false;
    },
    handleDeleteClick(id) {
      this.deployKeyToDelete = id;
    },
    handleModalHide() {
      this.deployKeyToDelete = null;
    },
    handleModalPrimary() {
      this.$refs.modalForm.submit();
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-py-5">
      <h4 class="gl-m-0">
        {{ $options.i18n.pageTitle }}
      </h4>
      <gl-button variant="confirm" :href="createPath" data-testid="new-deploy-key-button">{{
        $options.i18n.newDeployKeyButtonText
      }}</gl-button>
    </div>
    <template v-if="shouldShowTable">
      <gl-table
        :busy="loading"
        :items="items"
        :fields="$options.fields"
        stacked="lg"
        data-testid="deploy-keys-list"
      >
        <template #table-busy>
          <gl-loading-icon size="lg" class="gl-my-5" />
        </template>

        <template #cell(projects)="{ item: { projects } }">
          <a
            v-for="project in projects"
            :key="project.id"
            :href="projectHref(project)"
            class="gl-display-block"
            >{{ project.name_with_namespace }}</a
          >
        </template>

        <template #cell(fingerprint_sha256)="{ item: { fingerprint_sha256 } }">
          <span v-if="fingerprint_sha256" class="monospace">{{ fingerprint_sha256 }}</span>
        </template>

        <template #cell(fingerprint)="{ item: { fingerprint } }">
          <span v-if="fingerprint" class="monospace">{{ fingerprint }}</span>
        </template>

        <template #cell(created)="{ item: { created } }">
          <time-ago-tooltip :time="created" />
        </template>

        <template #head(actions)="{ label }">
          <span class="gl-sr-only">{{ label }}</span>
        </template>

        <template #cell(actions)="{ item: { id } }">
          <gl-button
            icon="pencil"
            :aria-label="$options.i18n.edit"
            :href="editHref(id)"
            class="gl-mr-2"
          />
          <gl-button
            variant="danger"
            icon="remove"
            :aria-label="$options.i18n.delete"
            @click="handleDeleteClick(id)"
          />
        </template>
      </gl-table>
      <gl-pagination
        v-if="!loading"
        v-model="page"
        :per-page="$options.DEFAULT_PER_PAGE"
        :total-items="totalItems"
        :next-text="$options.i18n.pagination.next"
        :prev-text="$options.i18n.pagination.prev"
        align="center"
      />
    </template>
    <gl-empty-state
      v-else
      :svg-path="emptyStateSvgPath"
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.emptyStateDescription"
      :primary-button-text="$options.i18n.newDeployKeyButtonText"
      :primary-button-link="createPath"
    />
    <gl-modal
      :modal-id="$options.modal.id"
      :visible="isModalVisible"
      :title="$options.i18n.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="sm"
      @hide="handleModalHide"
      @primary="handleModalPrimary"
    >
      <form ref="modalForm" :action="deleteAction" method="post">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      </form>
      {{ $options.i18n.modal.body }}
    </gl-modal>
  </div>
</template>
