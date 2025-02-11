<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { sortBy } from 'lodash';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import deployFreezesQuery from '../graphql/queries/deploy_freezes.query.graphql';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['projectFullPath'],
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  data() {
    return { deployFreezes: [] };
  },

  apollo: {
    deployFreezes: {
      query: deployFreezesQuery,
      update(data) {
        const freezes = data?.project?.environment?.deployFreezes;
        return sortBy(freezes, [(freeze) => freeze.startTime]);
      },
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.name,
        };
      },
    },
  },
  computed: {
    shouldShowDeployFreezeAlert() {
      return this.deployFreezes.length > 0;
    },
    nextDeployFreeze() {
      return this.deployFreezes[0];
    },
    deployFreezeStartTime() {
      return localeDateFormat.asDateTimeFull.format(this.nextDeployFreeze.startTime);
    },
    deployFreezeEndTime() {
      return localeDateFormat.asDateTimeFull.format(this.nextDeployFreeze.endTime);
    },
  },
  i18n: {
    deployFreezeAlert: s__(
      'Environments|A freeze period is in effect from %{startTime} to %{endTime}. Deployments might fail during this time. For more information, see the %{docsLinkStart}deploy freeze documentation%{docsLinkEnd}.',
    ),
  },
  deployFreezeDocsPath: helpPagePath('user/project/releases/_index', {
    anchor: 'prevent-unintentional-releases-by-setting-a-deploy-freeze',
  }),
};
</script>
<template>
  <gl-alert v-if="shouldShowDeployFreezeAlert" :dismissible="false" class="gl-mt-4">
    <gl-sprintf :message="$options.i18n.deployFreezeAlert">
      <template #startTime
        ><span class="gl-font-bold">{{ deployFreezeStartTime }}</span></template
      >
      <template #endTime
        ><span class="gl-font-bold">{{ deployFreezeEndTime }}</span></template
      >
      <template #docsLink="{ content }"
        ><gl-link :href="$options.deployFreezeDocsPath">{{ content }}</gl-link></template
      >
    </gl-sprintf>
  </gl-alert>
</template>
