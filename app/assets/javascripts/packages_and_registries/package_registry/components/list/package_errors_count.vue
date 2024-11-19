<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { setUrlParams } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { ERRORED_PACKAGE_TEXT } from '~/packages_and_registries/package_registry/constants';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import getPackageErrorsCountQuery from '~/packages_and_registries/package_registry/graphql/queries/get_package_errors_count.query.graphql';

export default {
  name: 'PackageErrorsCount',
  components: {
    GlAlert,
    GlButton,
    DeleteModal,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['isGroupPage', 'fullPath'],
  apollo: {
    errorPackages: {
      query: getPackageErrorsCountQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          isGroupPage: this.isGroupPage,
        };
      },
      update(data) {
        if (!data[this.graphqlResource]) {
          this.reportToSentry();
        }
        return data[this.graphqlResource]?.packages ?? {};
      },
      error(error) {
        this.reportToSentry(error);
      },
    },
  },
  data() {
    return {
      errorPackages: {},
      itemsToBeDeleted: [],
    };
  },
  computed: {
    errorPackagesCount() {
      return this.errorPackages.count;
    },
    errorTitleAlert() {
      if (this.singleErrorPackage) {
        return sprintf(s__('PackageRegistry|There was an error publishing %{packageName}'), {
          packageName: this.singleErrorPackage.name,
        });
      }
      return sprintf(s__('PackageRegistry|There was an error publishing %{count} packages'), {
        count: this.errorPackagesCount,
      });
    },
    errorMessageBodyAlert() {
      if (this.singleErrorPackage) {
        return sprintf(this.$options.i18n.errorMessageBodyAlert, {
          message: this.singleErrorPackage.statusMessage || ERRORED_PACKAGE_TEXT,
        });
      }

      return sprintf(
        s__(
          'PackageRegistry|Failed to publish %{count} packages. Delete these packages and try again.',
        ),
        {
          count: this.errorPackagesCount,
        },
      );
    },
    graphqlResource() {
      return this.isGroupPage ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    singleErrorPackage() {
      if (this.errorPackagesCount === 1) {
        const [errorPackage] = this.errorPackages.nodes;
        return errorPackage;
      }

      return null;
    },
    showErrorPackageAlert() {
      return this.errorPackagesCount > 0;
    },
    errorPackagesHref() {
      if (this.singleErrorPackage) {
        return '';
      }

      return setUrlParams({ status: 'error' }, window.location.href, true);
    },
  },
  methods: {
    deleteItemsConfirmation() {
      this.$emit('confirm-delete', this.itemsToBeDeleted);
    },
    showConfirmationModal() {
      this.itemsToBeDeleted = [this.singleErrorPackage];
      this.$refs.deletePackagesModal.show();
    },
    reportToSentry(error) {
      Sentry.captureException(error);
    },
  },
  i18n: {
    errorMessageBodyAlert: s__('PackageRegistry|%{message}. Delete this package and try again.'),
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showErrorPackageAlert"
      class="gl-mb-5 gl-mt-2"
      variant="danger"
      :title="errorTitleAlert"
    >
      {{ errorMessageBodyAlert }}
      <template #actions>
        <gl-button
          v-if="singleErrorPackage"
          variant="confirm"
          data-event-label="package_errors_alert"
          data-event-tracking="click_delete_package_button"
          @click="showConfirmationModal"
          >{{ s__('PackageRegistry|Delete this package') }}</gl-button
        >
        <gl-button
          v-else
          :href="errorPackagesHref"
          variant="confirm"
          data-event-label="package_errors_alert"
          data-event-tracking="click_show_packages_with_errors_link"
          >{{ s__('PackageRegistry|Show packages with errors') }}</gl-button
        >
      </template>
    </gl-alert>
    <delete-modal
      ref="deletePackagesModal"
      :items-to-be-deleted="itemsToBeDeleted"
      @confirm="deleteItemsConfirmation"
    />
  </div>
</template>
