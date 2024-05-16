<script>
import { GlLoadingIcon, GlAlert, GlModal } from '@gitlab/ui';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CONTAINER_REPOSITORY } from '~/graphql_shared/constants';
import { __ } from '~/locale';
import getManifestDetailsQuery from '../../graphql/queries/get_manifest_details.query.graphql';

export default {
  components: { GlLoadingIcon, GlAlert, GlModal, CodeBlockHighlighted },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    digest: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      manifestDetails: null,
    };
  },
  computed: {
    prettyFormattedDetails() {
      try {
        // Workaround for backend returning a serialized Ruby hash. The only difference between the hash and JSON is
        // that it uses '=>' instead of ':', so we'll replace it and try to parse it as JSON.
        const details = this.manifestDetails.replaceAll('=>', ':');
        const json = JSON.parse(details);
        return JSON.stringify(json, null, 2);
      } catch {
        // Use the raw manifest details if it couldn't be parsed.
        return this.manifestDetails;
      }
    },
  },
  apollo: {
    manifestDetails: {
      query: getManifestDetailsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_CONTAINER_REPOSITORY, this.$route.params.id),
          reference: this.digest,
        };
      },
      update({ containerRepository }) {
        return containerRepository.manifest;
      },
      skip() {
        return !this.digest;
      },
      error() {
        this.manifestDetails = null;
      },
    },
  },
  cancel: { text: __('Close') },
};
</script>

<template>
  <gl-modal
    modal-id="signature-details-modal"
    :visible="visible"
    :title="s__('ContainerRegistry|Signature details')"
    :action-cancel="$options.cancel"
    scrollable
    @hidden="$emit('close')"
  >
    <gl-loading-icon v-if="$apollo.queries.manifestDetails.loading" size="lg" />

    <gl-alert v-else-if="!manifestDetails" :dismissible="false" variant="danger">
      {{ s__('ContainerRegistry|Could not load signature details.') }}
    </gl-alert>

    <code-block-highlighted v-else language="json" :code="prettyFormattedDetails" />
  </gl-modal>
</template>
