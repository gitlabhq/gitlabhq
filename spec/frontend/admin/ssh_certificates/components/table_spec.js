import { GlIcon, GlLink, GlPagination, GlSkeletonLoader } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SshCertificatesTable from '~/admin/ssh_certificates/components/table.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getAdminSshCertificates } from '~/api/admin_ssh_certificates_api';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';

jest.mock('~/api/admin_ssh_certificates_api');
jest.mock('~/alert');

const certificates = [
  {
    id: 1,
    title: 'Production CA',
    fingerprint: 'SHA256:k3F9pQz1UH7nNR2vD8sE1qgA6tY3wZ0cL9ObN4xM5jK',
    created_at: '2026-09-01T10:00:00Z',
  },
  {
    id: 2,
    title: 'Staging CA',
    fingerprint: 'SHA256:9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8',
    created_at: '2026-09-02T10:00:00Z',
  },
];

describe('SshCertificatesTable', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(SshCertificatesTable);
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
  const findPagination = () => wrapper.findComponent(GlPagination);

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
      expect(findCrudTitle().text()).toContain(SshCertificatesTable.i18n.title);
      expect(findCrudCount().text()).toBe('25');
      expect(findCrudCount().findComponent(GlIcon).props('name')).toBe('credentials');
      expect(findCrudDescription().text()).toContain(SshCertificatesTable.i18n.description);
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
          title: SshCertificatesTable.i18n.copyFingerprint,
        });
      });
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
      expect(findCrudEmpty().text()).toBe(SshCertificatesTable.i18n.emptyMessage);
      expect(findPagination().exists()).toBe(false);
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
        message: SshCertificatesTable.i18n.apiErrorMessage,
        captureError: true,
        error,
      });
      expect(findCrudEmpty().text()).toBe(SshCertificatesTable.i18n.emptyMessage);
    });
  });
});
