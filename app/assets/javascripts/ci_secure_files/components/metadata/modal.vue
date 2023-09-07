<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlModal, GlSprintf, GlModalDirective } from '@gitlab/ui';
import { __, s__, createDateTimeFormat } from '~/locale';
import Tracking from '~/tracking';
import MetadataTable from './table.vue';

const dateFormat = createDateTimeFormat({
  dateStyle: 'long',
  timeStyle: 'long',
});

export default {
  components: {
    GlModal,
    GlSprintf,
    MetadataTable,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    name: {
      type: String,
      required: false,
      default: '',
    },
    fileExtension: {
      type: String,
      required: false,
      default: '',
    },
    metadata: {
      type: Object,
      required: false,
      default: Object.new,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  i18n: {
    metadataLabel: __('View File Metadata'),
    metadataModalTitle: s__('SecureFiles|%{name} Metadata'),
  },
  metadataModalId: 'metadataModalId',
  methods: {
    teamName() {
      return `${this.metadata.subject.O} (${this.metadata.subject.OU})`;
    },
    issuerName() {
      return [this.metadata.issuer.CN, '-', this.metadata.issuer.OU].join(' ');
    },
    expiresAt() {
      return dateFormat.format(new Date(this.metadata.expires_at));
    },
    mobileprovisionTeamName() {
      return `${this.metadata.team_name} (${this.metadata.team_id.join(', ')})`;
    },
    platformNames() {
      return this.metadata.platforms.join(', ');
    },
    appName() {
      return [this.metadata.app_name, '-', this.metadata.app_id].join(' ');
    },
    certificates() {
      return this.metadata.certificate_ids.join(', ');
    },
    cerItems() {
      return [
        { name: s__('SecureFiles|Name'), data: this.metadata.subject.CN },
        { name: s__('SecureFiles|Serial'), data: this.metadata.id },
        { name: s__('SecureFiles|Team'), data: this.teamName() },
        { name: s__('SecureFiles|Issuer'), data: this.issuerName() },
        { name: s__('SecureFiles|Expires at'), data: this.expiresAt() },
      ];
    },
    p12Items() {
      return [
        { name: s__('SecureFiles|Name'), data: this.metadata.subject.CN },
        { name: s__('SecureFiles|Serial'), data: this.metadata.id },
        { name: s__('SecureFiles|Team'), data: this.teamName() },
        { name: s__('SecureFiles|Issuer'), data: this.issuerName() },
        { name: s__('SecureFiles|Expires at'), data: this.expiresAt() },
      ];
    },
    mobileprovisionItems() {
      return [
        { name: s__('SecureFiles|UUID'), data: this.metadata.id },
        { name: s__('SecureFiles|Platforms'), data: this.platformNames() },
        { name: s__('SecureFiles|Team'), data: this.mobileprovisionTeamName() },
        { name: s__('SecureFiles|App'), data: this.appName() },
        { name: s__('SecureFiles|Certificates'), data: this.certificates() },
        { name: s__('SecureFiles|Expires at'), data: this.expiresAt() },
      ];
    },
    items() {
      if (this.metadata) {
        if (this.fileExtension === 'cer') {
          this.track('load_secure_file_metadata_cer');
          return this.cerItems();
        }
        if (this.fileExtension === 'p12') {
          this.track('load_secure_file_metadata_p12');
          return this.p12Items();
        }
        if (this.fileExtension === 'mobileprovision') {
          this.track('load_secure_file_metadata_mobileprovision');
          return this.mobileprovisionItems(this.metadata);
        }
      }

      return [];
    },
  },
};
</script>
``

<template>
  <gl-modal :ref="modalId" :modal-id="modalId" title-tag="h4" category="primary" hide-footer>
    <template #modal-title>
      <gl-sprintf :message="$options.i18n.metadataModalTitle">
        <template #name>{{ name }}</template>
      </gl-sprintf>
    </template>

    <metadata-table :items="items()" />
  </gl-modal>
</template>
