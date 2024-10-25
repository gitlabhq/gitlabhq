<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';

export default {
  name: 'PackageErrorsCount',
  components: {
    GlAlert,
    GlButton,
  },
  props: {
    errorPackages: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    errorTitleAlert() {
      if (this.singleErrorPackage) {
        return sprintf(s__('PackageRegistry|There was an error publishing %{packageName}'), {
          packageName: this.singleErrorPackage.name,
        });
      }
      return sprintf(s__('PackageRegistry|There was an error publishing %{count} packages'), {
        count: this.errorPackages.length,
      });
    },
    errorMessageBodyAlert() {
      if (this.singleErrorPackage) {
        return this.singleErrorPackage.statusMessage || this.$options.i18n.errorMessageBodyAlert;
      }

      return sprintf(
        s__(
          'PackageRegistry|Failed to publish %{count} packages. Delete these packages and try again.',
        ),
        {
          count: this.errorPackages.length,
        },
      );
    },
    singleErrorPackage() {
      if (this.errorPackages.length === 1) {
        const [errorPackage] = this.errorPackages;
        return errorPackage;
      }

      return null;
    },
    showErrorPackageAlert() {
      return this.errorPackages.length > 0;
    },
    errorPackagesHref() {
      // For reactivity we depend on showErrorPackageAlert so we update accordingly
      if (!this.showErrorPackageAlert) {
        return '';
      }

      const pageParams = { after: null, before: null };
      return mergeUrlParams({ status: 'error', ...pageParams }, window.location.href);
    },
  },
  methods: {
    handleClick() {
      this.$emit('confirm-delete', [this.singleErrorPackage]);
    },
  },
  i18n: {
    errorMessageBodyAlert: s__(
      'PackageRegistry|There was a timeout and the package was not published. Delete this package and try again.',
    ),
  },
};
</script>

<template>
  <gl-alert v-if="showErrorPackageAlert" class="gl-mt-5" variant="danger" :title="errorTitleAlert">
    {{ errorMessageBodyAlert }}
    <template #actions>
      <gl-button v-if="singleErrorPackage" variant="confirm" @click="handleClick">{{
        s__('PackageRegistry|Delete this package')
      }}</gl-button>
      <gl-button v-else :href="errorPackagesHref" variant="confirm">{{
        s__('PackageRegistry|Show packages with errors')
      }}</gl-button>
    </template>
  </gl-alert>
</template>
