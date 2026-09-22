import {
  GlDisclosureDropdown,
  GlIcon,
  GlLink,
  GlModal,
  GlPagination,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import SshCertificatesTable from '~/admin/ssh_certificates/components/table.vue';
import CertificateAuthorityForm from '~/admin/ssh_certificates/components/certificate_authority_form.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import toast from '~/vue_shared/plugins/global_toast';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  getAdminSshCertificates,
  deleteAdminSshCertificate,
} from '~/api/admin_ssh_certificates_api';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

jest.mock('~/api/admin_ssh_certificates_api');
jest.mock('~/alert');
jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/sentry/sentry_browser_wrapper');

const certificates = [
  {
    id: 1,
    title: 'Production CA',
    fingerprint: 'SHA256:k3F9pQz1UH7nNR2vD8sE1qgA6tY3wZ0cL9ObN4xM5jK',
    key: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIProduction',
    created_at: '2026-09-01T10:00:00Z',
  },
  {
    id: 2,
    title: 'Staging CA',
    fingerprint: 'SHA256:9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8',
    key: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIStaging',
    created_at: '2026-09-02T10:00:00Z',
  },
];

// Shape of a row after the table maps the API response.
const toRow = ({ id, title, fingerprint, key, created_at: created }) => ({
  id,
  title,
  fingerprint,
  key,
  created,
});

describe('SshCertificatesTable', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(SshCertificatesTable, {
      stubs: {
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
    });
  };

  const mockResponse = (data, total = data.length) => {
    getAdminSshCertificates.mockResolvedValue({ data, headers: { 'x-total': String(total) } });
  };

  const findCrudTitle = () => wrapper.findByTestId('crud-title');
  const findCrudCount = () => wrapper.findByTestId('crud-count');
  const findCrudDescription = () => wrapper.findByTestId('crud-description');
  const findCrudLoading = () => wrapper.findComponent(GlSkeletonLoader);
  const findCrudEmpty = () => wrapper.findByTestId('crud-empty');
  const findTable = () => wrapper.findByTestId('ssh-certificates-list');
  const findRows = () => findTable().findAll('tbody tr');
  const findFingerprint = (row) => row.find('[data-testid="fingerprint"]');
  const findActionsDropdown = (row) => row.findComponent(GlDisclosureDropdown);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findFormToggle = () => wrapper.findByTestId('crud-form-toggle');
  const findForm = () => wrapper.findComponent(CertificateAuthorityForm);
  const findTitleInput = () => wrapper.findByTestId('certificate-authority-title-input');
  const findDeleteModal = () => wrapper.findComponent(ConfirmActionModal);

  const selectRowAction = (rowIndex, actionIndex) =>
    findActionsDropdown(findRows().at(rowIndex)).props('items')[actionIndex].action();

  const confirmDelete = () => {
    findDeleteModal().findComponent(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
    return waitForPromises();
  };

  describe('while loading', () => {
    it('renders the skeleton loader instead of the table', async () => {
      getAdminSshCertificates.mockReturnValue(new Promise(() => {}));
      createComponent();
      await nextTick();

      expect(findCrudLoading().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
      expect(findCrudEmpty().exists()).toBe(false);
    });
  });

  describe('when certificates are returned', () => {
    beforeEach(async () => {
      mockResponse(certificates, 25);
      createComponent();
      await waitForPromises();
    });

    it('requests the first page', () => {
      expect(getAdminSshCertificates).toHaveBeenCalledWith({ page: 1, perPage: 10 });
    });

    it('renders the card title, total count, and description with a help link', () => {
      expect(findCrudTitle().text()).toContain('SSH certificate authorities');
      expect(findCrudCount().text()).toBe('25');
      expect(findCrudCount().findComponent(GlIcon).props('name')).toBe('credentials');
      expect(findCrudDescription().text()).toContain(
        'Trusted certificate authorities that allow anyone with a signed certificate to authenticate over SSH. Short-lived certificates are recommended.',
      );
      expect(findCrudDescription().findComponent(GlLink).attributes('href')).toBe(
        helpPagePath('administration/operations/gitlab_sshd_ssh_certificates'),
      );
    });

    it('renders a row per certificate with title, truncated fingerprint, created date, and copy button', () => {
      expect(findRows()).toHaveLength(certificates.length);

      certificates.forEach((certificate, index) => {
        const row = findRows().at(index);

        expect(row.text()).toContain(certificate.title);
        expect(findFingerprint(row).text()).toBe(
          `${certificate.fingerprint.slice(0, 15)}…${certificate.fingerprint.slice(-4)}`,
        );
        expect(findFingerprint(row).attributes('title')).toBe(certificate.fingerprint);
        expect(row.findComponent(TimeAgoTooltip).props('time')).toBe(certificate.created_at);
        expect(row.findComponent(ClipboardButton).props()).toMatchObject({
          text: certificate.fingerprint,
          title: 'Copy fingerprint',
        });
      });
    });

    it('renders a more actions dropdown per row with view details and delete items', () => {
      const dropdown = findActionsDropdown(findRows().at(0));

      expect(dropdown.props()).toMatchObject({
        toggleText: 'More actions',
        textSrOnly: true,
        icon: 'ellipsis_v',
        noCaret: true,
      });
      expect(dropdown.props('items').map(({ text, variant }) => ({ text, variant }))).toEqual([
        { text: 'View details', variant: undefined },
        { text: 'Delete certificate authority', variant: 'danger' },
      ]);
    });

    it('renders pagination using the total from the response headers', () => {
      expect(findPagination().props()).toMatchObject({
        value: 1,
        perPage: 10,
        totalItems: 25,
      });
    });

    it('fetches the selected page', async () => {
      findPagination().vm.$emit('input', 2);
      await waitForPromises();

      expect(getAdminSshCertificates).toHaveBeenLastCalledWith({ page: 2, perPage: 10 });
    });
  });

  describe('adding a certificate authority', () => {
    beforeEach(async () => {
      mockResponse(certificates, 25);
      createComponent();
      await waitForPromises();
    });

    it('renders the toggle and shows the empty form when it is clicked', async () => {
      expect(findFormToggle().text()).toBe('Add certificate authority');
      expect(findForm().exists()).toBe(false);

      await findFormToggle().trigger('click');

      expect(findForm().props('certificate')).toBe(null);
    });

    it('hides the form on cancel', async () => {
      await findFormToggle().trigger('click');

      findForm().vm.$emit('cancel');
      await nextTick();

      expect(findForm().exists()).toBe(false);
    });

    it('hides the form, shows a toast, and refetches the first page when a certificate is added', async () => {
      await findFormToggle().trigger('click');
      getAdminSshCertificates.mockClear();

      findForm().vm.$emit('added');
      await waitForPromises();

      expect(findForm().exists()).toBe(false);
      expect(toast).toHaveBeenCalledWith('Certificate authority added.');
      expect(getAdminSshCertificates).toHaveBeenCalledTimes(1);
      expect(getAdminSshCertificates).toHaveBeenCalledWith({ page: 1, perPage: 10 });
    });

    it('returns to the first page when a certificate is added from another page', async () => {
      findPagination().vm.$emit('input', 2);
      await waitForPromises();
      await findFormToggle().trigger('click');

      findForm().vm.$emit('added');
      await waitForPromises();

      expect(getAdminSshCertificates).toHaveBeenLastCalledWith({ page: 1, perPage: 10 });
      expect(findPagination().props('value')).toBe(1);
    });
  });

  describe('viewing certificate authority details', () => {
    beforeEach(async () => {
      mockResponse(certificates, 25);
      createComponent();
      await waitForPromises();
    });

    it('opens the form read-only with the selected certificate', async () => {
      expect(findForm().exists()).toBe(false);

      selectRowAction(1, 0);
      await nextTick();

      expect(findForm().props('certificate')).toEqual(toRow(certificates[1]));
      expect(findFormToggle().exists()).toBe(false);
    });

    it('switches to another certificate when a different row is selected', async () => {
      selectRowAction(0, 0);
      await nextTick();
      selectRowAction(1, 0);
      await nextTick();

      expect(findForm().props('certificate')).toEqual(toRow(certificates[1]));
    });

    it('hides the form and clears the certificate on close', async () => {
      selectRowAction(1, 0);
      await nextTick();

      findForm().vm.$emit('cancel');
      await nextTick();

      expect(findForm().exists()).toBe(false);

      await findFormToggle().trigger('click');

      expect(findForm().props('certificate')).toBe(null);
    });

    it('does not ask for confirmation when the add form is open but empty', async () => {
      await findFormToggle().trigger('click');

      await selectRowAction(0, 0);
      await waitForPromises();

      expect(confirmAction).not.toHaveBeenCalled();
      expect(findForm().props('certificate')).toEqual(toRow(certificates[0]));
    });

    describe('when the add form has unsaved changes', () => {
      beforeEach(async () => {
        await findFormToggle().trigger('click');
        await findTitleInput().setValue('Draft CA');
      });

      it('asks for confirmation before discarding them', async () => {
        confirmAction.mockResolvedValueOnce(false);

        await selectRowAction(0, 0);
        await waitForPromises();

        expect(confirmAction).toHaveBeenCalledWith(
          'Viewing this certificate authority discards the title and public key you entered.',
          {
            title: 'Discard unsaved changes?',
            primaryBtnText: 'Discard changes',
            primaryBtnVariant: 'danger',
          },
        );
      });

      it('keeps the add form and its input when declined', async () => {
        confirmAction.mockResolvedValueOnce(false);

        await selectRowAction(0, 0);
        await waitForPromises();

        expect(findForm().props('certificate')).toBe(null);
        expect(findTitleInput().element.value).toBe('Draft CA');
      });

      it('opens the details when confirmed', async () => {
        confirmAction.mockResolvedValueOnce(true);

        await selectRowAction(0, 0);
        await waitForPromises();

        expect(findForm().props('certificate')).toEqual(toRow(certificates[0]));
        expect(findTitleInput().element.value).toBe(certificates[0].title);
      });
    });
  });

  describe('deleting a certificate authority', () => {
    beforeEach(async () => {
      deleteAdminSshCertificate.mockResolvedValue({});
      mockResponse(certificates, 25);
      createComponent();
      await waitForPromises();
    });

    it('does not render the delete modal until a row action is selected', () => {
      expect(findDeleteModal().exists()).toBe(false);
    });

    it('opens the delete modal naming the certificate and stating that trust is revoked immediately', async () => {
      selectRowAction(0, 1);
      await nextTick();

      expect(findDeleteModal().props()).toMatchObject({
        modalId: 'delete-certificate-authority-modal',
        title: 'Delete certificate authority?',
        actionText: 'Delete certificate authority',
        actionFn: wrapper.vm.deleteCertificate,
      });
      expect(findDeleteModal().find('strong').text()).toBe(certificates[0].title);
      expect(findDeleteModal().text()).toContain(
        'Trust in this certificate authority is revoked immediately, and any certificates it signed stop working at once. This action cannot be undone.',
      );
    });

    it('removes the modal when it is closed', async () => {
      selectRowAction(0, 1);
      await nextTick();

      findDeleteModal().vm.$emit('close');
      await nextTick();

      expect(findDeleteModal().exists()).toBe(false);
      expect(deleteAdminSshCertificate).not.toHaveBeenCalled();
    });

    it('deletes the certificate, shows a toast, and refetches the current page when confirmed', async () => {
      findPagination().vm.$emit('input', 2);
      await waitForPromises();
      selectRowAction(0, 1);
      await nextTick();
      getAdminSshCertificates.mockClear();

      await confirmDelete();

      expect(deleteAdminSshCertificate).toHaveBeenCalledWith(certificates[0].id);
      expect(toast).toHaveBeenCalledWith('Certificate authority deleted.');
      expect(getAdminSshCertificates).toHaveBeenCalledTimes(1);
      expect(getAdminSshCertificates).toHaveBeenCalledWith({ page: 2, perPage: 10 });
      expect(findPagination().props('value')).toBe(2);
    });

    it('keeps the modal mounted through the refetch so it can close and does not reappear', async () => {
      let resolveFetch;
      selectRowAction(0, 1);
      await nextTick();
      getAdminSshCertificates.mockReturnValue(
        new Promise((resolve) => {
          resolveFetch = resolve;
        }),
      );

      await confirmDelete();

      // The card shows the skeleton while refetching; the modal must not be torn down with it.
      expect(findCrudLoading().exists()).toBe(true);
      expect(findDeleteModal().exists()).toBe(true);

      // ConfirmActionModal hides itself after the action and emits close once hidden.
      findDeleteModal().findComponent(GlModal).vm.$emit('hidden');
      await nextTick();

      expect(findDeleteModal().exists()).toBe(false);

      resolveFetch({ data: [certificates[1]], headers: { 'x-total': '24' } });
      await waitForPromises();

      expect(findCrudLoading().exists()).toBe(false);
      expect(findRows()).toHaveLength(1);
      expect(findDeleteModal().exists()).toBe(false);
    });

    it('closes the details form when the viewed certificate is deleted', async () => {
      selectRowAction(0, 0);
      await nextTick();
      selectRowAction(0, 1);
      await nextTick();

      await confirmDelete();

      expect(findForm().exists()).toBe(false);
      expect(findFormToggle().exists()).toBe(true);
    });

    it('keeps the details form open when a different certificate is deleted', async () => {
      selectRowAction(0, 0);
      await nextTick();
      selectRowAction(1, 1);
      await nextTick();

      await confirmDelete();

      expect(findForm().props('certificate')).toEqual(toRow(certificates[0]));
    });

    it('goes back a page when the only certificate on the current page is deleted', async () => {
      mockResponse([certificates[0]], 21);
      findPagination().vm.$emit('input', 3);
      await waitForPromises();
      selectRowAction(0, 1);
      await nextTick();

      await confirmDelete();

      expect(getAdminSshCertificates).toHaveBeenLastCalledWith({ page: 2, perPage: 10 });
      expect(findPagination().props('value')).toBe(2);
    });

    it('refetches the first page when the only certificate on the first page is deleted', async () => {
      mockResponse([certificates[0]]);
      createComponent();
      await waitForPromises();
      selectRowAction(0, 1);
      await nextTick();
      getAdminSshCertificates.mockClear();

      await confirmDelete();

      expect(getAdminSshCertificates).toHaveBeenCalledTimes(1);
      expect(getAdminSshCertificates).toHaveBeenCalledWith({ page: 1, perPage: 10 });
    });

    describe('when the request fails', () => {
      const error = new Error('Request failed');

      beforeEach(async () => {
        deleteAdminSshCertificate.mockRejectedValue(error);
        selectRowAction(0, 1);
        await nextTick();
        getAdminSshCertificates.mockClear();

        await confirmDelete();
      });

      it('shows the error inside the modal, reports it, and does not refetch', () => {
        expect(findDeleteModal().exists()).toBe(true);
        expect(findDeleteModal().text()).toContain(
          'An error occurred while deleting the SSH certificate authority. Please try again.',
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(error);
        expect(toast).not.toHaveBeenCalled();
        expect(getAdminSshCertificates).not.toHaveBeenCalled();
      });
    });
  });

  describe('when a certificate has no fingerprint', () => {
    beforeEach(async () => {
      mockResponse([{ ...certificates[0], fingerprint: null }]);
      createComponent();
      await waitForPromises();
    });

    it('renders the row without the truncated fingerprint or copy button', () => {
      const row = findRows().at(0);

      expect(row.text()).toContain(certificates[0].title);
      expect(findFingerprint(row).exists()).toBe(false);
      expect(row.findComponent(ClipboardButton).exists()).toBe(false);
    });

    it('still renders the actions dropdown', () => {
      expect(findActionsDropdown(findRows().at(0)).exists()).toBe(true);
    });
  });

  describe('when all certificates fit on one page', () => {
    beforeEach(async () => {
      mockResponse(certificates);
      createComponent();
      await waitForPromises();
    });

    it('does not render pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('when no certificates are returned', () => {
    beforeEach(async () => {
      mockResponse([]);
      createComponent();
      await waitForPromises();
    });

    it('renders the empty message instead of the table', () => {
      expect(findTable().exists()).toBe(false);
      expect(findCrudEmpty().text()).toBe(
        "This instance doesn't have any SSH certificate authorities.",
      );
      expect(findPagination().exists()).toBe(false);
    });

    it('still renders the toggle so the form can be opened', () => {
      expect(findFormToggle().exists()).toBe(true);
    });
  });

  describe('when the request fails', () => {
    const error = new Error('Request failed');

    beforeEach(async () => {
      getAdminSshCertificates.mockRejectedValue(error);
      createComponent();
      await waitForPromises();
    });

    it('shows an alert and falls back to the empty message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message:
          'An error occurred while fetching the SSH certificate authorities. Please try again.',
        captureError: true,
        error,
      });
      expect(findCrudEmpty().text()).toBe(
        "This instance doesn't have any SSH certificate authorities.",
      );
    });
  });
});
