import { GlAlert } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CertificateAuthorityForm from '~/admin/ssh_certificates/components/certificate_authority_form.vue';
import { createAdminSshCertificate } from '~/api/admin_ssh_certificates_api';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

jest.mock('~/api/admin_ssh_certificates_api');
jest.mock('~/sentry/sentry_browser_wrapper');

const title = 'Production CA';
const key = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample';
const certificate = {
  id: 1,
  title,
  fingerprint: 'SHA256:k3F9pQz1UH7nNR2vD8sE1qgA6tY3wZ0cL9ObN4xM5jK',
  key,
  created: '2026-09-01T10:00:00Z',
};

describe('CertificateAuthorityForm', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(CertificateAuthorityForm, { propsData: props });
  };

  const findForm = () => wrapper.findByTestId('certificate-authority-form');
  // GlFormGroup forwards label/description/state/invalid-feedback as attrs to
  // the inner BFormGroup, so read them from there.
  const findFormGroup = (labelFor) =>
    wrapper
      .findAllComponents({ name: 'BFormGroup' })
      .wrappers.find((formGroup) => formGroup.props('labelFor') === labelFor);
  const findTitleGroup = () => findFormGroup('certificate-authority-title');
  const findFingerprintGroup = () => findFormGroup('certificate-authority-fingerprint');
  const findKeyGroup = () => findFormGroup('certificate-authority-key');
  const findTitleInput = () => wrapper.findByTestId('certificate-authority-title-input');
  const findFingerprintInput = () =>
    wrapper.findByTestId('certificate-authority-fingerprint-input');
  const findKeyInput = () => wrapper.findByTestId('certificate-authority-key-input');
  const findSubmitButton = () =>
    wrapper.findComponentByTestId('submit-certificate-authority-button');
  const findCancelButton = () =>
    wrapper.findComponentByTestId('cancel-certificate-authority-button');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const fillForm = async () => {
    await findTitleInput().setValue(title);
    await findKeyInput().setValue(key);
  };

  const submit = async () => {
    await findForm().trigger('submit');
    await waitForPromises();
  };

  const rejectWith = (status, data) => {
    createAdminSshCertificate.mockRejectedValue({ response: { status, data } });
  };

  beforeEach(() => {
    createAdminSshCertificate.mockResolvedValue({ data: {} });
  });

  describe('when adding a certificate authority', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title and public key fields with their descriptions', () => {
      expect(findTitleGroup().props()).toMatchObject({
        label: 'Title',
        description: 'Key titles are publicly visible.',
        state: null,
      });
      expect(findKeyGroup().props()).toMatchObject({
        label: 'Public key',
        description:
          "This is the CA's public key, not an individual user's key. Certificates it signs are trusted instance-wide.",
        state: null,
      });
      expect(findFingerprintGroup()).toBeUndefined();
      expect(findSubmitButton().text()).toBe('Add certificate authority');
      expect(findCancelButton().text()).toBe('Cancel');
    });

    it('renders the fields empty and editable', () => {
      expect(findTitleInput().element.value).toBe('');
      expect(findKeyInput().element.value).toBe('');
      expect(findTitleInput().attributes('disabled')).toBeUndefined();
      expect(findKeyInput().attributes('disabled')).toBeUndefined();
      expect(findTitleInput().attributes('readonly')).toBeUndefined();
      expect(findKeyInput().attributes('readonly')).toBeUndefined();
    });

    it('reports unsaved changes once either field has a value', async () => {
      expect(wrapper.vm.hasUnsavedChanges()).toBe(false);

      await findTitleInput().setValue(title);

      expect(wrapper.vm.hasUnsavedChanges()).toBe(true);

      await findTitleInput().setValue('   ');

      expect(wrapper.vm.hasUnsavedChanges()).toBe(false);

      await findKeyInput().setValue(key);

      expect(wrapper.vm.hasUnsavedChanges()).toBe(true);
    });

    it('limits the fields to the lengths accepted by the API', () => {
      expect(findTitleInput().attributes('maxlength')).toBe('255');
      expect(findKeyInput().attributes('maxlength')).toBe('5000');
    });

    it('emits cancel when the cancel button is clicked', async () => {
      await findCancelButton().trigger('click');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });

    describe('when submitted with empty fields', () => {
      beforeEach(async () => {
        await submit();
      });

      it('marks both fields invalid and does not call the API', () => {
        expect(findTitleGroup().props()).toMatchObject({
          state: false,
          invalidFeedback: 'Title is required.',
        });
        expect(findKeyGroup().props()).toMatchObject({
          state: false,
          invalidFeedback: 'Public key is required.',
        });
        expect(createAdminSshCertificate).not.toHaveBeenCalled();
        expect(wrapper.emitted('added')).toBeUndefined();
      });
    });

    describe('when submitted with valid fields', () => {
      beforeEach(async () => {
        await fillForm();
      });

      it('shows the loading state while the request is in flight', async () => {
        createAdminSshCertificate.mockReturnValue(new Promise(() => {}));

        await findForm().trigger('submit');

        expect(findSubmitButton().props('loading')).toBe(true);
        expect(findCancelButton().props('disabled')).toBe(true);
        expect(findTitleInput().attributes('disabled')).toBeDefined();
        expect(findKeyInput().attributes('disabled')).toBeDefined();
      });

      it('creates the certificate authority and emits added', async () => {
        await submit();

        expect(createAdminSshCertificate).toHaveBeenCalledWith({ title, key });
        expect(wrapper.emitted('added')).toHaveLength(1);
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('when the API rejects the key', () => {
      const message =
        'Validation failed: Fingerprint must be unique. This CA has already been configured.';

      beforeEach(async () => {
        rejectWith(HTTP_STATUS_UNPROCESSABLE_ENTITY, { message });
        await fillForm();
        await submit();
      });

      it('shows the message under the public key field without the ActiveRecord prefix', () => {
        expect(findKeyGroup().props()).toMatchObject({
          state: false,
          invalidFeedback: 'Fingerprint must be unique. This CA has already been configured.',
        });
        expect(findTitleGroup().props('state')).toBe(null);
        expect(findAlert().exists()).toBe(false);
        expect(wrapper.emitted('added')).toBeUndefined();
      });

      it('clears the error once the key is edited', async () => {
        await findKeyInput().setValue(`${key}X`);

        expect(findKeyGroup().props('state')).toBe(null);
      });
    });

    describe('when the request fails unexpectedly', () => {
      beforeEach(async () => {
        rejectWith(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
        await fillForm();
        await submit();
      });

      it('shows a generic alert, reports the error, and keeps the fields valid', () => {
        expect(findAlert().text()).toBe(
          'An error occurred while adding the SSH certificate authority. Please try again.',
        );
        expect(Sentry.captureException).toHaveBeenCalledTimes(1);
        expect(findKeyGroup().props('state')).toBe(null);
        expect(wrapper.emitted('added')).toBeUndefined();
      });
    });
  });

  describe('when viewing a certificate authority', () => {
    beforeEach(() => {
      createComponent({ certificate });
    });

    it('prefills the fields from the certificate and makes them read-only', () => {
      expect(findTitleInput().element.value).toBe(certificate.title);
      expect(findTitleInput().attributes('readonly')).toBeDefined();
      expect(findTitleInput().attributes('disabled')).toBeUndefined();

      expect(findFingerprintInput().element.value).toBe(certificate.fingerprint);
      expect(findFingerprintInput().attributes('readonly')).toBeDefined();
      expect(findFingerprintInput().attributes('disabled')).toBeUndefined();

      expect(findKeyInput().element.value).toBe(certificate.key);
      expect(findKeyInput().attributes('readonly')).toBeDefined();
      expect(findKeyInput().attributes('disabled')).toBeUndefined();
    });

    it('does not report unsaved changes', () => {
      expect(wrapper.vm.hasUnsavedChanges()).toBe(false);
    });

    it('renders the fingerprint field and the read-only public key description', () => {
      expect(findFingerprintGroup().props()).toMatchObject({
        label: 'Fingerprint (SHA256)',
        description: 'This matches what appears in your server logs and audit events.',
      });
      expect(findKeyGroup().props('description')).toBe(
        "This is the CA's public key, not an individual user's key. Certificates it signs are trusted instance-wide. Certificate authorities (CAs) can't be edited. To change this key, delete it and add a certificate authority.",
      );
    });

    it('renders only a close button that emits cancel', async () => {
      expect(findSubmitButton().exists()).toBe(false);
      expect(findCancelButton().text()).toBe('Close');

      await findCancelButton().trigger('click');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });

    it('does not call the API when the form is submitted', async () => {
      await submit();

      expect(createAdminSshCertificate).not.toHaveBeenCalled();
      expect(wrapper.emitted('added')).toBeUndefined();
    });

    it('resets to an empty add form when the certificate is cleared', async () => {
      await wrapper.setProps({ certificate: null });

      expect(findTitleInput().element.value).toBe('');
      expect(findKeyInput().element.value).toBe('');
      expect(findTitleInput().attributes('readonly')).toBeUndefined();
      expect(findKeyInput().attributes('readonly')).toBeUndefined();
      expect(findFingerprintGroup()).toBeUndefined();
      expect(findSubmitButton().exists()).toBe(true);
    });
  });

  describe('when viewing a certificate authority without a fingerprint', () => {
    beforeEach(() => {
      createComponent({ certificate: { ...certificate, fingerprint: null } });
    });

    it('renders a placeholder in the fingerprint field', () => {
      expect(findFingerprintInput().element.value).toBe('Not available');
    });
  });
});
