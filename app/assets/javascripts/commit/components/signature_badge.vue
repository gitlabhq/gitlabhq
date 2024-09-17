<script>
import { GlBadge, GlLink, GlPopover } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { typeConfig, statusConfig } from 'ee_else_ce/commit/constants';
import X509CertificateDetails from './x509_certificate_details.vue';

export default {
  components: {
    GlBadge,
    GlPopover,
    GlLink,
    X509CertificateDetails,
  },
  props: {
    signature: {
      type: Object,
      required: true,
    },
  },
  computed: {
    statusConfig() {
      return this.$options.statusConfig?.[this.signature?.verificationStatus];
    },
    typeConfig() {
      // eslint-disable-next-line no-underscore-dangle
      return this.$options.typeConfig?.[this.signature?.__typename];
    },
  },
  methods: {
    helpPagePath,
    getSubjectKeyIdentifierToDisplay(subjectKeyIdentifier) {
      // we need to remove : to not trigger secret detection scan
      return subjectKeyIdentifier.replaceAll(':', ' ');
    },
  },
  typeConfig,
  statusConfig,
};
</script>
<template>
  <span
    v-if="statusConfig && typeConfig"
    class="gl-ml-2 gl-flex gl-items-center hover:gl-cursor-pointer"
  >
    <button
      id="signature"
      tabindex="0"
      data-testid="signature-badge"
      role="button"
      variant="link"
      class="gl-border-0 gl-bg-transparent gl-p-0 gl-outline-none"
      :aria-label="statusConfig.label"
    >
      <gl-badge :variant="statusConfig.variant">
        {{ statusConfig.label }}
      </gl-badge>
    </button>
    <gl-popover target="signature" triggers="focus">
      <template #title>
        {{ statusConfig.title }}
      </template>
      <p data-testid="signature-description">
        {{ statusConfig.description }}
      </p>
      <p v-if="typeConfig.keyLabel" data-testid="signature-key-label">
        {{ typeConfig.keyLabel }}
        <span class="gl-font-monospace" data-testid="signature-key">
          {{ signature[typeConfig.keyNamespace] || __('Unknown') }}
        </span>
      </p>
      <x509-certificate-details
        v-if="signature.x509Certificate"
        :title="typeConfig.subjectTitle"
        :subject="signature.x509Certificate.subject"
        :subject-key-identifier="
          getSubjectKeyIdentifierToDisplay(signature.x509Certificate.subjectKeyIdentifier)
        "
      />
      <x509-certificate-details
        v-if="signature.x509Certificate && signature.x509Certificate.x509Issuer"
        :title="typeConfig.issuerTitle"
        :subject="signature.x509Certificate.x509Issuer.subject"
        :subject-key-identifier="
          getSubjectKeyIdentifierToDisplay(
            signature.x509Certificate.x509Issuer.subjectKeyIdentifier,
          )
        "
      />
      <gl-link :href="helpPagePath(typeConfig.helpLink.path)">
        {{ typeConfig.helpLink.label }}
      </gl-link>
    </gl-popover>
  </span>
</template>
