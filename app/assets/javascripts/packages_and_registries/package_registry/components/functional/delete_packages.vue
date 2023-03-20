<script>
import destroyPackagesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_packages.mutation.graphql';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';

import {
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DELETE_PACKAGES_ERROR_MESSAGE,
  DELETE_PACKAGES_SUCCESS_MESSAGE,
} from '~/packages_and_registries/package_registry/constants';

export default {
  name: 'DeletePackages',
  props: {
    refetchQueries: {
      type: Array,
      required: false,
      default: null,
    },
    showSuccessAlert: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    errorMessage: DELETE_PACKAGE_ERROR_MESSAGE,
    errorMessageMultiple: DELETE_PACKAGES_ERROR_MESSAGE,
    successMessage: DELETE_PACKAGE_SUCCESS_MESSAGE,
    successMessageMultiple: DELETE_PACKAGES_SUCCESS_MESSAGE,
  },
  methods: {
    async deletePackages(packageEntities) {
      const isSinglePackage = packageEntities.length === 1;
      try {
        this.$emit('start');
        const ids = packageEntities.map((packageEntity) => packageEntity.id);
        const { data } = await this.$apollo.mutate({
          mutation: destroyPackagesMutation,
          variables: {
            ids,
          },
          awaitRefetchQueries: Boolean(this.refetchQueries),
          refetchQueries: this.refetchQueries,
        });

        if (data?.destroyPackages?.errors[0]) {
          throw data.destroyPackages.errors[0];
        }

        if (this.showSuccessAlert) {
          createAlert({
            message: isSinglePackage
              ? this.$options.i18n.successMessage
              : this.$options.i18n.successMessageMultiple,
            variant: VARIANT_SUCCESS,
          });
        }
      } catch (error) {
        createAlert({
          message: isSinglePackage
            ? this.$options.i18n.errorMessage
            : this.$options.i18n.errorMessageMultiple,
          variant: VARIANT_WARNING,
          captureError: true,
          error,
        });
      }
      this.$emit('end');
    },
  },
  render() {
    return this.$scopedSlots.default({ deletePackages: this.deletePackages });
  },
};
</script>
