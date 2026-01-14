<script>
import { GlModal, GlButton, GlSkeletonLoader, GlIcon, GlPopover } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import queryProfile from '~/security_configuration/graphql/scan_profiles/security_scan_profile.query.graphql';
import CollapsibleSection from './collapsible_section.vue';
import ScanTriggersDetail from './scan_triggers_detail.vue';

const i18n = {
  modalTitle: s__('ScanProfiles|Secret push protection profile'),
  infoPopoverTitle: s__('ScanProfiles|What are configuration profiles?'),
  infoPopoverDetails: s__(
    'ScanProfiles|Configuration profiles are reusable settings templates for security tools. Create and manage profiles once, then apply them to multiple projects to ensure consistent security coverage.',
  ),
  profileSubtitle: s__('ScanProfiles|View profile settings and associated projects.'),
  applyProfile: s__('ScanProfiles|Apply profile'),
  generalDetails: s__('ScanProfiles|General Details'),
  generalDetailsInfo: s__('ScanProfiles|Information about this configuration profile.'),
  scanTriggers: s__('ScanProfiles|Scan triggers'),
  scanTriggersInfo: s__('ScanProfiles|When and how scans are run.'),
  description: __('Description'),
  analyzerType: __('Analyzer type'),
  secretDetection: __('Secret Detection'),
};

const SCAN_TYPE_LABELS = {
  SECRET_DETECTION: i18n.secretDetection,
};

export default {
  name: 'ScanProfileDetailsModal',

  components: {
    GlModal,
    GlButton,
    GlSkeletonLoader,
    GlIcon,
    GlPopover,
    CollapsibleSection,
    ScanTriggersDetail,
  },

  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['close', 'apply'],

  data() {
    return {
      modalId: 'scan-profile-details-modal',
      profile: null,
      loading: 0, // Initialized to 0 as this is used by a "loadingKey". See https://apollo.vuejs.org/api/smart-query.html#options
    };
  },

  apollo: {
    profile: {
      query: queryProfile,
      variables() {
        return { id: 'gid://gitlab/Security::ScanProfile/secret_detection' };
      },
      update(data) {
        return data?.securityScanProfile || null;
      },
      loadingKey: 'loading',
      error() {
        this.profile = null;
      },
    },
  },

  computed: {
    scanTypeLabel() {
      return SCAN_TYPE_LABELS[this.profile?.scanType] || this.profile?.scanType;
    },
    profileName() {
      return this.profile?.name;
    },
  },
  methods: {
    close() {
      this.$emit('close');
    },
    applyProfile() {
      this.$emit('apply', this.profile.id);
    },
  },

  i18n,
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :visible="visible"
    size="lg"
    modal-class="scanner-profile-modal"
    @close="close"
  >
    <template #modal-title>
      <span>{{ $options.i18n.modalTitle }}</span>
      <gl-icon id="header-info" name="question-o" class="gl-link gl-mb-1 gl-ml-1" />
      <gl-popover target="header-info" :title="$options.i18n.infoPopoverTitle">
        {{ $options.i18n.infoPopoverDetails }}
      </gl-popover>
    </template>

    <div v-if="loading > 0" class="gl-py-6">
      <gl-skeleton-loader :lines="3" />
    </div>

    <div v-else-if="profile">
      <div class="gl-border-t gl-border-b gl-mb-5 gl-border-gray-100 gl-py-5">
        <div
          class="gl-display-flex gl-align-items-start gl-justify-content-space-between"
          style="display: flex; justify-content: space-between"
        >
          <div class="gl-display-flex gl-flex-direction-column gl-gap-2">
            <h3 class="gl-font-lg gl-font-weight-bold gl-m-0 gl-mb-1">
              {{ profileName }}
            </h3>
            <span class="gl-font-sm gl-text-secondary">
              {{ $options.i18n.profileSubtitle }}
            </span>
          </div>
          <gl-button variant="confirm" class="gl-self-center" @click="applyProfile">
            {{ $options.i18n.applyProfile }}
          </gl-button>
        </div>
      </div>
      <collapsible-section
        :title="$options.i18n.generalDetails"
        :subtitle="$options.i18n.generalDetailsInfo"
        :default-expanded="true"
      >
        <div class="gl-mb-5">
          <h4 class="gl-font-sm gl-heading-4 gl-mb-2">
            {{ $options.i18n.description }}
          </h4>
          <p class="gl-font-sm gl-m-0 gl-text-secondary">
            {{ profile.description }}
          </p>
        </div>

        <div>
          <h4 class="gl-font-sm gl-heading-4 gl-mb-2">
            {{ $options.i18n.analyzerType }}
          </h4>
          <p class="gl-font-sm gl-m-0 gl-text-secondary">
            {{ scanTypeLabel }}
          </p>
        </div>
      </collapsible-section>

      <collapsible-section
        :title="$options.i18n.scanTriggers"
        :subtitle="$options.i18n.scanTriggersInfo"
        :default-expanded="true"
      >
        <scan-triggers-detail />
      </collapsible-section>
    </div>
    <template #modal-footer>
      <div></div>
    </template>
  </gl-modal>
</template>
