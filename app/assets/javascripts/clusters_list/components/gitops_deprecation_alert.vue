<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import Api from '~/api';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  props: {
    agentConfigs: {
      required: true,
      type: Array,
    },
    projectGid: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      hasGitopsKeyword: false,
    };
  },
  computed: {
    projectId() {
      return getIdFromGraphQLId(this.projectGid);
    },
  },
  mounted() {
    this.searchForGitopsKeyword();
  },
  methods: {
    async searchForGitopsKeyword() {
      for (const path of this.agentConfigs) {
        // eslint-disable-next-line no-await-in-loop
        const config = await this.getConfigFile(`${path}/config.yaml`);
        const regexp = /\bgitops:\s/;
        const match = regexp.exec(config);
        if (match) {
          this.hasGitopsKeyword = true;
          return;
        }
      }
    },
    async getConfigFile(path) {
      try {
        const { data } = await Api.getRawFile(this.projectId, path);
        return data;
      } catch {
        return '';
      }
    },
  },
  i18n: {
    alertText: s__(
      'ClusterAgents|The pull-based deployment features of the GitLab agent for Kubernetes is deprecated. If you use the agent for pull-based deployments, you should %{linkStart}migrate to Flux%{linkEnd}.',
    ),
  },
  documentationLink: helpPagePath('user/clusters/agent/gitops/migrate_to_flux'),
};
</script>

<template>
  <gl-alert v-if="hasGitopsKeyword" variant="warning" :dismissible="false" class="gl-mb-4">
    <gl-sprintf :message="$options.i18n.alertText">
      <template #link="{ content }">
        <gl-link :href="$options.documentationLink">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
