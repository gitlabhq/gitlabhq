<script>
import { computed } from 'vue';
import workItemMetadataQuery from '~/work_items/graphql/work_item_metadata.query.graphql';

export default {
  provide() {
    // We provide the licensed features as computed properties
    // so that they can be reactive and update when the Apollo query updates.
    return Object.fromEntries(
      Object.keys(this.licensedFeatures).map((key) => [
        key,
        computed(() => this.licensedFeatures[key]),
      ]),
    );
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      licensedFeatures: {},
    };
  },
  apollo: {
    licensedFeatures: {
      query: workItemMetadataQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data?.namespace?.licensedFeatures || {};
      },
    },
  },
  render() {
    return this.$scopedSlots.default();
  },
};
</script>
