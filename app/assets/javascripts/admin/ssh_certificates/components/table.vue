<script>
import { GlTable, GlPagination, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getAdminSshCertificates } from '~/api/admin_ssh_certificates_api';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

// 10 rather than the usual 20: the CRUD card is compact and 20 rows take up
// too much of the Admin Area screen.
const PER_PAGE = 10;

export default {
  name: 'SshCertificatesTable',
  i18n: {
    title: __('SSH certificate authorities'),
    description: s__(
      'SshCertificates|Trusted certificate authorities that allow anyone with a signed certificate to authenticate over SSH. Short-lived certificates are recommended.',
    ),
    helpLinkText: s__('SshCertificates|What are SSH certificates?'),
    emptyMessage: s__('SshCertificates|There are no trusted SSH certificates on this instance.'),
    copyFingerprint: s__('SshCertificates|Copy fingerprint'),
    apiErrorMessage: s__(
      'SshCertificates|An error occurred while fetching the SSH certificate authorities. Please try again.',
    ),
  },
  fields: [
    {
      key: 'title',
      label: __('Title'),
      thClass: '@md/panel:gl-w-8/20',
    },
    {
      key: 'fingerprint',
      label: __('Fingerprint (SHA256)'),
      thClass: '@md/panel:gl-w-6/20',
    },
    {
      key: 'created',
      label: __('Created'),
    },
    {
      key: 'actions',
      label: __('Actions'),
      thClass: '@md/panel:gl-w-px',
      tdClass: '@md/panel:gl-w-px gl-whitespace-nowrap',
    },
  ],
  PER_PAGE,
  helpPath: helpPagePath('administration/operations/gitlab_sshd_ssh_certificates'),
  components: {
    CrudComponent,
    GlTable,
    GlPagination,
    GlLink,
    TimeAgoTooltip,
    ClipboardButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      page: 1,
      totalItems: 0,
      loading: false,
      items: [],
    };
  },
  computed: {
    hasCertificates() {
      return this.items.length > 0;
    },
    showPagination() {
      return this.totalItems > PER_PAGE;
    },
  },
  watch: {
    page(newPage) {
      this.fetchCertificates(newPage);
    },
  },
  mounted() {
    this.fetchCertificates();
  },
  methods: {
    async fetchCertificates(page = this.page) {
      this.loading = true;

      try {
        const { headers, data } = await getAdminSshCertificates({ page, perPage: PER_PAGE });

        this.totalItems = parseInt(headers?.['x-total'], 10) || 0;
        this.items = data.map(({ id, title, fingerprint, created_at: created }) => ({
          id,
          title,
          fingerprint,
          created,
        }));
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
    // Fixed-length middle truncation, e.g. `SHA256:k3F9pQz1…8xLm`, so the column
    // width stays predictable and the full value is available in the tooltip.
    truncateFingerprint(fingerprint) {
      return `${fingerprint.slice(0, 15)}…${fingerprint.slice(-4)}`;
    },
  },
};
</script>

<template>
  <crud-component
    :title="$options.i18n.title"
    icon="credentials"
    :count="totalItems"
    :is-loading="loading"
  >
    <template #description>
      {{ $options.i18n.description }}
      <gl-link :href="$options.helpPath" target="_blank">{{ $options.i18n.helpLinkText }}</gl-link>
    </template>

    <template v-if="!hasCertificates" #empty>
      {{ $options.i18n.emptyMessage }}
    </template>

    <gl-table
      :items="items"
      :fields="$options.fields"
      stacked="md"
      class="-gl-mb-2 -gl-mt-1"
      data-testid="ssh-certificates-list"
    >
      <template #head(actions)="{ label }">
        <span class="gl-sr-only">{{ label }}</span>
      </template>

      <template #cell(fingerprint)="{ item: { fingerprint } }">
        <span v-if="fingerprint" v-gl-tooltip :title="fingerprint" data-testid="fingerprint">
          {{ truncateFingerprint(fingerprint) }}
        </span>
      </template>

      <template #cell(created)="{ item: { created } }">
        <time-ago-tooltip :time="created" />
      </template>

      <template #cell(actions)="{ item: { fingerprint } }">
        <div class="gl-flex gl-justify-end gl-gap-2">
          <clipboard-button
            v-if="fingerprint"
            :text="fingerprint"
            :title="$options.i18n.copyFingerprint"
            category="tertiary"
            size="small"
          />
        </div>
      </template>
    </gl-table>

    <template v-if="showPagination" #pagination>
      <gl-pagination
        v-model="page"
        :per-page="$options.PER_PAGE"
        :total-items="totalItems"
        :disabled="loading"
        align="center"
      />
    </template>
  </crud-component>
</template>
