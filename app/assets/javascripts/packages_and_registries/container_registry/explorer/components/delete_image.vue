<script>
import { produce } from 'immer';
import { GRAPHQL_PAGE_SIZE } from '../constants/index';
import deleteContainerRepositoryMutation from '../graphql/mutations/delete_container_repository.mutation.graphql';
import getContainerRepositoryDetailsQuery from '../graphql/queries/get_container_repository_details.query.graphql';

export default {
  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
    useUpdateFn: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    updateImageStatus(store, { data: { destroyContainerRepository } }) {
      const variables = {
        id: this.id,
        first: GRAPHQL_PAGE_SIZE,
      };
      const sourceData = store.readQuery({
        query: getContainerRepositoryDetailsQuery,
        variables,
      });

      const data = produce(sourceData, (draftState) => {
        draftState.containerRepository.status =
          destroyContainerRepository.containerRepository.status;
      });

      store.writeQuery({
        query: getContainerRepositoryDetailsQuery,
        variables,
        data,
      });
    },
    doDelete() {
      this.$emit('start');
      return this.$apollo
        .mutate({
          mutation: deleteContainerRepositoryMutation,
          variables: {
            id: this.id,
          },
          update: this.useUpdateFn ? this.updateImageStatus : undefined,
        })
        .then(({ data }) => {
          if (data?.destroyContainerRepository?.errors[0]) {
            this.$emit('error', data?.destroyContainerRepository?.errors);
            return;
          }
          this.$emit('success');
        })
        .catch((e) => {
          // note: we are adding an array to follow the same format of the error raised above
          this.$emit('error', [e]);
        })
        .finally(() => {
          this.$emit('end');
        });
    },
  },
  render() {
    if (this.$scopedSlots?.default) {
      return this.$scopedSlots.default({ doDelete: this.doDelete });
    }
    return null;
  },
};
</script>
