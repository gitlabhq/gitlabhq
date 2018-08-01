<script>
import { mapActions } from 'vuex';
import { s__ } from '~/locale/index';

import LicensePackages from './license_packages.vue';
import { LICENSE_APPROVAL_STATUS } from '../constants';

export default {
  name: 'LicenseIssueBody',
  components: { LicensePackages },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    status() {
      switch (this.issue.approvalStatus) {
        case LICENSE_APPROVAL_STATUS.APPROVED:
          return s__('LicenseManagement|Approved');
        case LICENSE_APPROVAL_STATUS.BLACKLISTED:
          return s__('LicenseManagement|Blacklisted');
        default:
          return s__('LicenseManagement|Unapproved');
      }
    },
  },
  methods: { ...mapActions(['setLicenseInModal']) },
};
</script>

<template>
  <div class="report-block-info license-item">
    <span class="append-right-5">{{ status }}:</span>
    <button
      class="btn-blank btn-link append-right-5"
      type="button"
      data-toggle="modal"
      data-target="#modal-set-license-approval"
      @click="setLicenseInModal(issue)"
    >
      {{ issue.name }}
    </button>
    <license-packages
      :packages="issue.packages"
      class="text-secondary"
    />
  </div>
</template>
