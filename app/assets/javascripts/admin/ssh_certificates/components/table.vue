<script>
import {
  GlTable,
  GlPagination,
  GlLink,
  GlDisclosureDropdown,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import {
  getAdminSshCertificates,
  deleteAdminSshCertificate,
} from '~/api/admin_ssh_certificates_api';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import toast from '~/vue_shared/plugins/global_toast';
import CertificateAuthorityForm from './certificate_authority_form.vue';

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
    emptyMessage: s__(
      "SshCertificates|This instance doesn't have any SSH certificate authorities.",
    ),
    copyFingerprint: s__('SshCertificates|Copy fingerprint'),
    deleteCertificateAuthority: s__('SshCertificates|Delete certificate authority'),
    addToggleText: s__('SshCertificates|Add certificate authority'),
    addedMessage: s__('SshCertificates|Certificate authority added.'),
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
    GlDisclosureDropdown,
    GlSprintf,
    ConfirmActionModal,
    TimeAgoTooltip,
    ClipboardButton,
    CertificateAuthorityForm,
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
      certificateToView: null,
      certificateToDelete: null,
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
        this.items = data.map(({ id, title, fingerprint, key, created_at: created }) => ({
          id,
          title,
          fingerprint,
          key,
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
    rowActions(certificate) {
      return [
        {
          text: s__('SshCertificates|View details'),
          action: () => this.viewCertificate(certificate),
        },
        {
          text: this.$options.i18n.deleteCertificateAuthority,
          action: () => {
            this.certificateToDelete = certificate;
          },
          variant: 'danger',
        },
      ];
    },
    async viewCertificate(certificate) {
      if (this.$refs.form?.hasUnsavedChanges()) {
        const confirmed = await confirmAction(
          s__(
            'SshCertificates|Viewing this certificate authority discards the title and public key you entered.',
          ),
          {
            title: s__('SshCertificates|Discard unsaved changes?'),
            primaryBtnText: s__('SshCertificates|Discard changes'),
            primaryBtnVariant: 'danger',
          },
        );

        if (!confirmed) return;
      }

      this.certificateToView = certificate;
      this.$refs.crud.showForm();
    },
    onFormHidden() {
      this.certificateToView = null;
    },
    onCertificateAdded(hideForm) {
      hideForm();
      toast(this.$options.i18n.addedMessage);

      if (this.page === 1) {
        this.fetchCertificates();
      } else {
        this.page = 1;
      }
    },
    // Passed to ConfirmActionModal, which keeps the modal open with a loading
    // state until the promise settles and shows the rejection message inline.
    async deleteCertificate() {
      try {
        await deleteAdminSshCertificate(this.certificateToDelete.id);
      } catch (error) {
        Sentry.captureException(error);
        return Promise.reject(
          s__(
            'SshCertificates|An error occurred while deleting the SSH certificate authority. Please try again.',
          ),
        );
      }

      this.onCertificateDeleted();
      return Promise.resolve();
    },
    onCertificateDeleted() {
      if (this.certificateToView?.id === this.certificateToDelete.id) {
        this.$refs.crud.hideForm();
      }

      toast(s__('SshCertificates|Certificate authority deleted.'));

      // Step back a page when the only row on this page was removed.
      if (this.items.length === 1 && this.page > 1) {
        this.page -= 1;
      } else {
        this.fetchCertificates();
      }
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
  <div>
    <crud-component
      ref="crud"
      :title="$options.i18n.title"
      icon="credentials"
      :count="totalItems"
      :is-loading="loading"
      :toggle-text="$options.i18n.addToggleText"
      @hide-form="onFormHidden"
    >
      <template #description>
        {{ $options.i18n.description }}
        <gl-link :href="$options.helpPath" target="_blank">{{
          $options.i18n.helpLinkText
        }}</gl-link>
      </template>

      <template #form="{ hideForm }">
        <certificate-authority-form
          ref="form"
          :certificate="certificateToView"
          @added="onCertificateAdded(hideForm)"
          @cancel="hideForm"
        />
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

        <template #cell(actions)="{ item }">
          <div class="gl-flex gl-justify-end gl-gap-2">
            <clipboard-button
              v-if="item.fingerprint"
              :text="item.fingerprint"
              :title="$options.i18n.copyFingerprint"
              category="tertiary"
              size="small"
            />
            <gl-disclosure-dropdown
              :items="rowActions(item)"
              :toggle-text="s__('SshCertificates|More actions')"
              text-sr-only
              icon="ellipsis_v"
              category="tertiary"
              size="small"
              no-caret
              placement="bottom-end"
              data-testid="certificate-authority-actions"
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

    <!-- Kept outside the CRUD card: its default slot is replaced by the skeleton
         loader while refetching, which would unmount the modal mid-close and
         remount it once loading finishes. -->
    <confirm-action-modal
      v-if="certificateToDelete"
      modal-id="delete-certificate-authority-modal"
      :title="s__('SshCertificates|Delete certificate authority?')"
      :action-fn="deleteCertificate"
      :action-text="$options.i18n.deleteCertificateAuthority"
      @close="certificateToDelete = null"
    >
      <gl-sprintf
        :message="
          s__(
            'SshCertificates|Are you sure you want to delete %{title}? Trust in this certificate authority is revoked immediately, and any certificates it signed stop working at once. This action cannot be undone.',
          )
        "
      >
        <template #title>
          <strong>{{ certificateToDelete.title }}</strong>
        </template>
      </gl-sprintf>
    </confirm-action-modal>
  </div>
</template>
