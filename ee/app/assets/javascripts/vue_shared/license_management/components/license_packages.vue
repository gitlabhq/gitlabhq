<script>
import { s__, sprintf } from '~/locale';
import { getPackagesString } from '../store/utils';

export default {
  name: 'LicensePackages',
  props: {
    packages: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      displayPackageCount: 3,
      showAllPackages: false,
    };
  },
  computed: {
    packageString() {
      return getPackagesString(this.packages, !this.showAllPackages, this.displayPackageCount);
    },
    remainingPackages() {
      const { packages } = this;
      if (packages.length > this.displayPackageCount) {
        return sprintf(s__('ciReport|%{remainingPackagesCount} more'), {
          remainingPackagesCount: packages.length - this.displayPackageCount,
        });
      }
      return '';
    },
  },
  methods: {
    handleShowPackages() {
      this.showAllPackages = true;
    },
  },
};
</script>
<template>
  <div class="license-packages d-inline">
    <div class="js-license-dependencies d-inline">{{ packageString }}</div>
    <button
      v-if="!showAllPackages && remainingPackages"
      type="button"
      class="btn-link btn-show-all-packages"
      @click="handleShowPackages"
    >
      {{ remainingPackages }}
    </button>
  </div>
</template>
