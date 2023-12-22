import { GlBadge, GlLink, GlPopover } from '@gitlab/ui';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import X509CertificateDetails from '~/commit/components/x509_certificate_details.vue';
import { typeConfig, statusConfig, verificationStatuses, signatureTypes } from '~/commit/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sshSignatureProp, gpgSignatureProp, x509SignatureProp } from '../mock_data';

describe('Commit signature', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(SignatureBadge, {
      propsData: {
        signature: {
          ...props,
        },
        stubs: {
          GlBadge,
          GlLink,
          X509CertificateDetails,
          GlPopover: stubComponent(GlPopover, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        },
      },
    });
  };

  const signatureBadge = () => wrapper.findComponent(GlBadge);
  const signaturePopover = () => wrapper.findComponent(GlPopover);
  const signatureDescription = () => wrapper.findByTestId('signature-description');
  const signatureKeyLabel = () => wrapper.findByTestId('signature-key-label');
  const signatureKey = () => wrapper.findByTestId('signature-key');
  const helpLink = () => wrapper.findComponent(GlLink);
  const X509CertificateDetailsComponents = () => wrapper.findAllComponents(X509CertificateDetails);

  describe.each`
    signatureType          | verificationStatus
    ${signatureTypes.GPG}  | ${verificationStatuses.VERIFIED}
    ${signatureTypes.GPG}  | ${verificationStatuses.VERIFIED_SYSTEM}
    ${signatureTypes.GPG}  | ${verificationStatuses.UNVERIFIED}
    ${signatureTypes.GPG}  | ${verificationStatuses.UNVERIFIED_KEY}
    ${signatureTypes.GPG}  | ${verificationStatuses.UNKNOWN_KEY}
    ${signatureTypes.GPG}  | ${verificationStatuses.OTHER_USER}
    ${signatureTypes.GPG}  | ${verificationStatuses.SAME_USER_DIFFERENT_EMAIL}
    ${signatureTypes.GPG}  | ${verificationStatuses.MULTIPLE_SIGNATURES}
    ${signatureTypes.X509} | ${verificationStatuses.VERIFIED}
    ${signatureTypes.SSH}  | ${verificationStatuses.VERIFIED}
    ${signatureTypes.SSH}  | ${verificationStatuses.REVOKED_KEY}
  `(
    'For a specified `$signatureType` and `$verificationStatus` it renders component correctly',
    ({ signatureType, verificationStatus }) => {
      beforeEach(() => {
        createComponent({ __typename: signatureType, verificationStatus });
      });
      it('renders correct badge class', () => {
        expect(signatureBadge().props('variant')).toBe(statusConfig[verificationStatus].variant);
      });
      it('renders badge text', () => {
        expect(signatureBadge().text()).toBe(statusConfig[verificationStatus].label);
      });
      it('renders  popover header text', () => {
        expect(signaturePopover().text()).toMatch(statusConfig[verificationStatus].title);
      });
      it('renders signature description', () => {
        expect(signatureDescription().text()).toBe(statusConfig[verificationStatus].description);
      });
      it('renders help link with correct path', () => {
        expect(helpLink().text()).toBe(typeConfig[signatureType].helpLink.label);
        expect(helpLink().attributes('href')).toBe(
          helpPagePath(typeConfig[signatureType].helpLink.path),
        );
      });
    },
  );

  describe('SSH signature', () => {
    beforeEach(() => {
      createComponent(sshSignatureProp);
    });

    it('renders key label', () => {
      expect(signatureKeyLabel().text()).toMatch(typeConfig[signatureTypes.SSH].keyLabel);
    });

    it('renders key signature', () => {
      expect(signatureKey().text()).toBe(sshSignatureProp.keyFingerprintSha256);
    });
  });

  describe('GPG signature', () => {
    beforeEach(() => {
      createComponent(gpgSignatureProp);
    });

    it('renders key label', () => {
      expect(signatureKeyLabel().text()).toMatch(typeConfig[signatureTypes.GPG].keyLabel);
    });

    it('renders key signature for GGP signature', () => {
      expect(signatureKey().text()).toBe(gpgSignatureProp.gpgKeyPrimaryKeyid);
    });
  });

  describe('X509 signature', () => {
    beforeEach(() => {
      createComponent(x509SignatureProp);
    });

    it('does not render key label', () => {
      expect(signatureKeyLabel().exists()).toBe(false);
    });

    it('renders X509 certificate details components', () => {
      expect(X509CertificateDetailsComponents()).toHaveLength(2);
    });

    it('passes correct props', () => {
      expect(X509CertificateDetailsComponents().at(0).props()).toStrictEqual({
        subject: x509SignatureProp.x509Certificate.subject,
        title: typeConfig[signatureTypes.X509].subjectTitle,
        subjectKeyIdentifier: wrapper.vm.getSubjectKeyIdentifierToDisplay(
          x509SignatureProp.x509Certificate.subjectKeyIdentifier,
        ),
      });
      expect(X509CertificateDetailsComponents().at(1).props()).toStrictEqual({
        subject: x509SignatureProp.x509Certificate.x509Issuer.subject,
        title: typeConfig[signatureTypes.X509].issuerTitle,
        subjectKeyIdentifier: wrapper.vm.getSubjectKeyIdentifierToDisplay(
          x509SignatureProp.x509Certificate.x509Issuer.subjectKeyIdentifier,
        ),
      });
    });
  });
});
