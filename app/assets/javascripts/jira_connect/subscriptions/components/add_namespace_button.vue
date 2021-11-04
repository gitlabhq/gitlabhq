<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { ADD_NAMESPACE_MODAL_ID } from '../constants';
import AddNamespaceModal from './add_namespace_modal/add_namespace_modal.vue';

export default {
  components: {
    GlButton,
    AddNamespaceModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  ADD_NAMESPACE_MODAL_ID,
};
</script>
<template>
  <div>
    <gl-button v-gl-modal="$options.ADD_NAMESPACE_MODAL_ID" category="primary" variant="info">
      {{ s__('Integrations|Add namespace') }}
    </gl-button>
    <add-namespace-modal />
  </div>
</template>
