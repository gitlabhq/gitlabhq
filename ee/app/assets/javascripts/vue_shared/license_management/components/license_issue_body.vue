<script>
import { mapActions } from 'vuex';

import LicensePackages from './license_packages.vue';

export default {
  name: 'LicenseIssueBody',
  components: { LicensePackages },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  methods: { ...mapActions(['setLicenseInModal']) },
};
</script>

<template>
  <div class="report-block-info license-item">
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
