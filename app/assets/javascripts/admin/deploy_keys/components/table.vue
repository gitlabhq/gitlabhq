<script>
import {
  GlTable,
  GlButton,
  GlPagination,
  GlLoadingIcon,
  GlEmptyState,
  GlModal,
  GlTooltipDirective,
} from '@gitlab/ui';

import { VIEW_ADMIN_DEPLOY_KEYS_PAGELOAD } from '~/admin/deploy_keys/constants';
import { __ } from '~/locale';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { InternalEvents } from '~/tracking';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
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
      'Deploy keys grant read/write access to all repositories in your instance, start by creating a new one above.',
    ),
    delete: __('Delete deploy key'),
    edit: __('Edit deploy key'),
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
      tdClass: 'md:gl-max-w-26',
    },
    {
      key: 'fingerprint',
      label: __('Fingerprint (MD5)'),
      tdClass: 'md:gl-max-w-26',
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
      tdClass: 'lg:gl-w-px gl-whitespace-nowrap',
      thClass: 'lg:gl-w-px gl-whitespace-nowrap',
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
    CrudComponent,
    GlTable,
    GlButton,
    GlPagination,
    TimeAgoTooltip,
    GlLoadingIcon,
    GlEmptyState,
    GlModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
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
    this.trackEvent(VIEW_ADMIN_DEPLOY_KEYS_PAGELOAD);
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
  <crud-component
    :title="$options.i18n.pageTitle"
    :count="totalItems.toString()"
    icon="key"
    class="gl-mt-5"
  >
    <template #actions>
      <gl-button size="small" :href="createPath" data-testid="new-deploy-key-button">{{
        $options.i18n.newDeployKeyButtonText
      }}</gl-button>
    </template>

    <gl-table
      v-if="shouldShowTable"
      :busy="loading"
      :items="items"
      :fields="$options.fields"
      stacked="md"
      data-testid="deploy-keys-list"
      class="-gl-mb-2 -gl-mt-1"
    >
      <template #table-busy>
        <gl-loading-icon size="sm" class="gl-my-5" />
      </template>

      <template #cell(projects)="{ item: { projects } }">
        <a
          v-for="project in projects"
          :key="project.id"
          :href="projectHref(project)"
          class="gl-block"
          >{{ project.name_with_namespace }}</a
        >
      </template>
      <template #cell(fingerprint_sha256)="{ item: { fingerprint_sha256 } }">
        <div
          v-if="fingerprint_sha256"
          class="gl-truncate gl-font-monospace"
          :title="fingerprint_sha256"
        >
          {{ fingerprint_sha256 }}
        </div>
      </template>

      <template #cell(fingerprint)="{ item: { fingerprint } }">
        <div v-if="fingerprint" class="gl-truncate gl-font-monospace" :title="fingerprint">
          {{ fingerprint }}
        </div>
      </template>

      <template #cell(created)="{ item: { created } }">
        <time-ago-tooltip :time="created" />
      </template>

      <template #head(actions)="{ label }">
        <span class="gl-sr-only">{{ label }}</span>
      </template>

      <template #cell(actions)="{ item: { id } }">
        <div class="-gl-my-3 gl-flex gl-gap-2">
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.edit"
            category="tertiary"
            icon="pencil"
            :aria-label="$options.i18n.edit"
            :href="editHref(id)"
          />
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.delete"
            category="tertiary"
            icon="remove"
            :aria-label="$options.i18n.delete"
            @click="handleDeleteClick(id)"
          />
        </div>
      </template>
    </gl-table>
    <gl-empty-state
      v-else
      :svg-path="emptyStateSvgPath"
      :svg-height="150"
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.emptyStateDescription"
    />
    <gl-pagination
      v-if="!loading"
      v-model="page"
      :per-page="$options.DEFAULT_PER_PAGE"
      :total-items="totalItems"
      align="center"
      class="gl-mt-5"
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
  </crud-component>
</template>
