<script>
import { isEmpty } from 'lodash';
import { createAlert, VARIANT_DANGER } from '~/alert';
import destroyModelMutation from '~/ml/model_registry/graphql/mutations/destroy_model.mutation.graphql';
import { s__, sprintf } from '~/locale';

const makeDeleteModelErrorMessage = (message) => {
  if (!message) return '';

  return sprintf(s__('MlModelRegistry|Failed to delete model with error: %{message}'), {
    message,
  });
};

export default {
  name: 'DeleteModel',
  inject: ['projectPath'],
  props: {
    modelId: {
      type: String,
      required: true,
    },
  },
  methods: {
    handleError(error) {
      createAlert({
        message: makeDeleteModelErrorMessage(error.message),
        variant: VARIANT_DANGER,
        captureError: true,
        error,
      });
    },
    async deleteModel() {
      try {
        const variables = {
          projectPath: this.projectPath,
          id: this.modelId,
        };

        const { data } = await this.$apollo.mutate({
          mutation: destroyModelMutation,
          variables,
        });

        if (isEmpty(data?.mlModelDelete?.errors)) {
          this.$emit('model-deleted');
        } else {
          this.handleError(new Error(data.mlModelDelete.errors.join(', ')));
        }
      } catch (error) {
        this.handleError(error);
      }
    },
  },
  render() {
    return this.$scopedSlots.default({ deleteModel: this.deleteModel });
  },
};
</script>
