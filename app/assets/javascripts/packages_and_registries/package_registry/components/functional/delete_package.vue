<script>
import destroyPackageMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package.mutation.graphql';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/flash';
import { s__ } from '~/locale';

import { DELETE_PACKAGE_SUCCESS_MESSAGE } from '~/packages_and_registries/package_registry/constants';

export default {
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
    errorMessage: s__('PackageRegistry|Something went wrong while deleting the package.'),
    successMessage: DELETE_PACKAGE_SUCCESS_MESSAGE,
  },
  methods: {
    async deletePackage(packageEntity) {
      try {
        this.$emit('start');
        const { data } = await this.$apollo.mutate({
          mutation: destroyPackageMutation,
          variables: {
            id: packageEntity.id,
          },
          awaitRefetchQueries: Boolean(this.refetchQueries),
          refetchQueries: this.refetchQueries,
        });

        if (data?.destroyPackage?.errors[0]) {
          throw data.destroyPackage.errors[0];
        }
        if (this.showSuccessAlert) {
          createAlert({
            message: this.$options.i18n.successMessage,
            variant: VARIANT_SUCCESS,
          });
        }
      } catch (error) {
        createAlert({
          message: this.$options.i18n.errorMessage,
          variant: VARIANT_WARNING,
          captureError: true,
          error,
        });
      }
      this.$emit('end');
    },
  },
  render() {
    return this.$scopedSlots.default({ deletePackage: this.deletePackage });
  },
};
</script>
