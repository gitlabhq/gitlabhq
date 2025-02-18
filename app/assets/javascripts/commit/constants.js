import { __, s__ } from '~/locale';

export const X509_CERTIFICATE_KEY_IDENTIFIER_TITLE = __('Subject Key Identifier:');

export const verificationStatuses = {
  VERIFIED: 'VERIFIED',
  UNVERIFIED: 'UNVERIFIED',
  UNVERIFIED_KEY: 'UNVERIFIED_KEY',
  UNKNOWN_KEY: 'UNKNOWN_KEY',
  OTHER_USER: 'OTHER_USER',
  SAME_USER_DIFFERENT_EMAIL: 'SAME_USER_DIFFERENT_EMAIL',
  MULTIPLE_SIGNATURES: 'MULTIPLE_SIGNATURES',
  REVOKED_KEY: 'REVOKED_KEY',
  VERIFIED_SYSTEM: 'VERIFIED_SYSTEM',
};

export const signatureTypes = {
  /* eslint-disable @gitlab/require-i18n-strings */
  GPG: 'GpgSignature',
  X509: 'X509Signature',
  SSH: 'SshSignature',
  /* eslint-enable @gitlab/require-i18n-strings */
};

const UNVERIFIED_CONFIG = {
  variant: 'muted',
  label: __('Unverified'),
  title: __('Unverified signature'),
  description: __('This commit was signed with an unverified signature.'),
};

export const VERIFIED_CONFIG = {
  variant: 'success',
  label: __('Verified'),
  title: __('Verified commit'),
};

export const statusConfig = {
  [verificationStatuses.VERIFIED]: {
    ...VERIFIED_CONFIG,
    description: __(
      'This commit was signed with a verified signature and the committer email was verified to belong to the same user.',
    ),
  },
  [verificationStatuses.VERIFIED_SYSTEM]: {
    ...VERIFIED_CONFIG,
    description: __(
      'This commit was created in the GitLab UI, and signed with a GitLab-verified signature.',
    ),
  },
  [verificationStatuses.UNVERIFIED]: {
    ...UNVERIFIED_CONFIG,
  },
  [verificationStatuses.UNVERIFIED_KEY]: {
    ...UNVERIFIED_CONFIG,
  },
  [verificationStatuses.UNKNOWN_KEY]: {
    ...UNVERIFIED_CONFIG,
  },
  [verificationStatuses.OTHER_USER]: {
    variant: 'muted',
    label: __('Unverified'),
    title: __("Different user's signature"),
    description: __('This commit was signed with an unverified signature.'),
  },
  [verificationStatuses.SAME_USER_DIFFERENT_EMAIL]: {
    variant: 'muted',
    label: __('Unverified'),
    title: __('GPG key mismatch'),
    description: __(
      'This commit was signed with a verified signature, but the committer email is not associated with the GPG Key.',
    ),
  },
  [verificationStatuses.MULTIPLE_SIGNATURES]: {
    variant: 'muted',
    label: __('Unverified'),
    title: __('Multiple signatures'),
    description: __('This commit was signed with multiple signatures.'),
  },
  [verificationStatuses.REVOKED_KEY]: {
    variant: 'muted',
    label: __('Unverified'),
    title: s__('CommitSignature|Unverified signature'),
    description: s__('CommitSignature|This commit was signed with a key that was revoked.'),
  },
};

export const typeConfig = {
  [signatureTypes.GPG]: {
    keyLabel: __('GPG Key ID:'),
    keyNamespace: 'gpgKeyPrimaryKeyid',
    helpLink: {
      label: __('Learn about signing commits'),
      path: 'user/project/repository/signed_commits/_index.md',
    },
  },
  [signatureTypes.X509]: {
    keyLabel: '',
    helpLink: {
      label: __('Learn more about X.509 signed commits'),
      path: '/user/project/repository/signed_commits/x509.md',
    },
    subjectTitle: __('Certificate Subject'),
    issuerTitle: __('Certificate Issuer'),
    keyIdentifierTitle: __('Subject Key Identifier:'),
  },
  [signatureTypes.SSH]: {
    keyLabel: __('SSH key fingerprint:'),
    keyNamespace: 'keyFingerprintSha256',
    helpLink: {
      label: __('Learn about signing commits with SSH keys.'),
      path: '/user/project/repository/signed_commits/ssh.md',
    },
  },
};
