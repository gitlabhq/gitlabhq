<script>
import { GlButton } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'ScanTriggersDetail',
  components: {
    CrudComponent,
    GlButton,
  },
  i18n: {
    triggerTitle: s__('ScanProfiles|Git Push Events'),
    triggerSubtitle: s__(
      'ScanProfiles|Scan all Git push events and block pushes with detected secrets.',
    ),
    triggerDescription: s__(
      'ScanProfiles|Block secrets such as keys and API tokens from being pushed to your repositories. Secret detection is triggered when commits are pushed to a repository. If any secrets are detected, the push is blocked.',
    ),
    viewDocs: s__('ScanProfiles|View documentation'),
  },
  data() {
    return {
      collapsed: true,
      docsPath: helpPagePath(
        'user/application_security/secret_detection/secret_push_protection/_index',
      ),
    };
  },
};
</script>

<template>
  <crud-component
    :is-collapsible="true"
    :collapsed="collapsed"
    :title="$options.i18n.triggerTitle"
    :description="$options.i18n.triggerSubtitle"
    anchor-id="git-push-events"
    icon="push-rules"
  >
    <p class="gl-mb-4">
      {{ $options.i18n.triggerDescription }}
    </p>

    <gl-button variant="link" icon="external-link" class="gl-p-0" :href="docsPath" target="_blank">
      {{ $options.i18n.viewDocs }}
    </gl-button>
  </crud-component>
</template>
