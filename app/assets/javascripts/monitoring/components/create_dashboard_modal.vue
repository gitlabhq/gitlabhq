<script>
import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { isSafeURL } from '~/lib/utils/url_utility';

export default {
  components: { GlButton, GlModal, GlSprintf },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
      validator: isSafeURL,
    },
    addDashboardDocumentationPath: {
      type: String,
      required: true,
    },
  },
  methods: {
    cancelHandler() {
      this.$refs.modal.hide();
    },
  },
  i18n: {
    titleText: s__('Metrics|Create your dashboard configuration file'),
    mainText: s__(
      'Metrics|To create a new dashboard, add a new YAML file to %{codeStart}.gitlab/dashboards%{codeEnd} at the root of this project.',
    ),
  },
};
</script>

<template>
  <gl-modal ref="modal" :modal-id="modalId" :title="$options.i18n.titleText">
    <p>
      <gl-sprintf :message="$options.i18n.mainText">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <template #modal-footer>
      <gl-button category="secondary" @click="cancelHandler">{{ s__('Metrics|Cancel') }}</gl-button>
      <gl-button
        category="secondary"
        variant="info"
        target="_blank"
        :href="addDashboardDocumentationPath"
        data-testid="create-dashboard-modal-docs-button"
      >
        {{ s__('Metrics|View documentation') }}
      </gl-button>
      <gl-button
        variant="success"
        data-testid="create-dashboard-modal-repo-button"
        :href="projectPath"
      >
        {{ s__('Metrics|Open repository') }}
      </gl-button>
    </template>
  </gl-modal>
</template>
