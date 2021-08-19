<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  i18n: {
    edit: __('Edit'),
    webIde: __('Web IDE'),
  },
  components: {
    GlButton,
    WebIdeLink,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    showEditButton: {
      type: Boolean,
      required: true,
    },
    editPath: {
      type: String,
      required: true,
    },
    webIdePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <web-ide-link
    v-if="glFeatures.consolidatedEditButton"
    :show-edit-button="showEditButton"
    class="gl-mr-3"
    :edit-url="editPath"
    :web-ide-url="webIdePath"
    :is-blob="true"
  />
  <div v-else>
    <gl-button
      v-if="showEditButton"
      class="gl-mr-2"
      category="primary"
      variant="confirm"
      :href="editPath"
      data-testid="edit"
    >
      {{ $options.i18n.edit }}
    </gl-button>

    <gl-button
      class="gl-mr-3"
      category="primary"
      variant="confirm"
      :href="webIdePath"
      data-testid="web-ide"
    >
      {{ $options.i18n.webIde }}
    </gl-button>
  </div>
</template>
