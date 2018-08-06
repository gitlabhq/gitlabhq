<script>
import { s__ } from '~/locale';
import { mapActions, mapState } from 'vuex';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import LicensePackages from './license_packages.vue';
import { LICENSE_APPROVAL_STATUS } from '../constants';

export default {
  name: 'LicenseSetApprovalStatusModal',
  components: { LicensePackages, GlModal },
  computed: {
    ...mapState(['currentLicenseInModal', 'canManageLicenses']),
    headerTitleText() {
      if (!this.canManageLicenses) {
        return s__('LicenseManagement|License details');
      }
      if (this.canApprove) {
        return s__('LicenseManagement|Approve license?');
      }
      return s__('LicenseManagement|Blacklist license?');
    },
    canApprove() {
      return (
        this.canManageLicenses &&
        this.currentLicenseInModal &&
        this.currentLicenseInModal.approvalStatus !== LICENSE_APPROVAL_STATUS.APPROVED
      );
    },
    canBlacklist() {
      return (
        this.canManageLicenses &&
        this.currentLicenseInModal &&
        this.currentLicenseInModal.approvalStatus !== LICENSE_APPROVAL_STATUS.BLACKLISTED
      );
    },
  },
  methods: {
    ...mapActions(['resetLicenseInModal', 'approveLicense', 'blacklistLicense']),
  },
};
</script>
<template>
  <gl-modal
    id="modal-set-license-approval"
    :header-title-text="headerTitleText"
    modal-size="lg"
    @cancel="resetLicenseInModal"
  >
    <slot v-if="currentLicenseInModal">
      <div class="row prepend-top-10 append-bottom-10 js-license-name">
        <label class="col-sm-3 text-right font-weight-bold">
          {{ s__('LicenseManagement|License') }}:
        </label>
        <div class="col-sm-9 text-secondary">
          {{ currentLicenseInModal.name }}
        </div>
      </div>
      <div
        v-if="currentLicenseInModal.url"
        class="row prepend-top-10 append-bottom-10 js-license-url"
      >
        <label class="col-sm-3 text-right font-weight-bold">
          {{ s__('LicenseManagement|URL') }}:
        </label>
        <div class="col-sm-9 text-secondary">
          <a
            :href="currentLicenseInModal.url"
            target="_blank"
            rel="noopener noreferrer nofollow"
          >{{ currentLicenseInModal.url }}</a>
        </div>
      </div>
      <div class="row prepend-top-10 append-bottom-10 js-license-packages">
        <label class="col-sm-3 text-right font-weight-bold">
          {{ s__('LicenseManagement|Packages') }}:
        </label>
        <license-packages
          :packages="currentLicenseInModal.packages"
          class="col-sm-9 text-secondary"
        />
      </div>
    </slot>
    <template slot="footer">
      <button
        type="button"
        class="btn js-modal-cancel-action"
        data-dismiss="modal"
        @click="resetLicenseInModal"
      >
        {{ s__('Modal|Cancel') }}
      </button>
      <button
        v-if="canBlacklist"
        class="btn btn-remove btn-inverted js-modal-secondary-action"
        data-dismiss="modal"
        @click="blacklistLicense(currentLicenseInModal)"
      >
        {{ s__('LicenseManagement|Blacklist license') }}
      </button>
      <button
        v-if="canApprove"
        type="button"
        class="btn btn-success js-modal-primary-action"
        data-dismiss="modal"
        @click="approveLicense(currentLicenseInModal)"
      >
        {{ s__('LicenseManagement|Approve license') }}
      </button>
    </template>
  </gl-modal>
</template>
