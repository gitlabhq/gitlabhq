<script>
import { s__, sprintf } from '~/locale';

export default {
  props: {
    issue: {
      type: Object,
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
    packages() {
      return this.getPackagesString(!this.showAllPackages);
    },
    remainingPackages() {
      const { packages } = this.issue;
      if (packages.length > this.displayPackageCount) {
        return sprintf(s__('ciReport|%{remainingPackagesCount} more'), {
          remainingPackagesCount: packages.length - this.displayPackageCount,
        });
      }
      return '';
    },
  },
  methods: {
    getPackagesString(truncate) {
      const { packages } = this.issue;

      // When there is only 1 package name to show.
      if (packages.length === 1) {
        return packages[0].name;
      }

      // When packages count is higher than displayPackageCount
      // and truncate is true.
      if (truncate && packages.length > this.displayPackageCount) {
        return sprintf(s__('ciReport|%{packagesString} and '), {
          packagesString: packages
            .slice(0, this.displayPackageCount)
            .map(packageItem => packageItem.name)
            .join(', '),
        });
      }

      // Return all package names separated by comma with proper grammer
      return sprintf(s__('ciReport|%{packagesString} and %{lastPackage}'), {
        packagesString: packages
          .slice(0, packages.length - 1)
          .map(packageItem => packageItem.name)
          .join(', '),
        lastPackage: packages[packages.length - 1].name,
      });
    },
    handleShowPackages() {
      this.showAllPackages = true;
    },
  },
};
</script>

<template>
  <p
    class="prepend-left-4 append-bottom-0 report-block-info license-item"
  >
    <a
      target="_blank"
      rel="noopener noreferrer nofollow"
      :href="issue.url"
    >{{ issue.name }}</a>
    <span
      class="license-dependencies"
    >
      &nbsp;{{ packages }}
    </span>
    <button
      v-if="!showAllPackages"
      type="button"
      class="btn btn-link btn-show-all-packages"
      @click="handleShowPackages"
    >
      {{ remainingPackages }}
    </button>
  </p>
</template>
