<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';

export default {
  name: 'PackageHistory',
  i18n: {
    createdOn: s__('PackageRegistry|%{name} version %{version} was created %{datetime}'),
    updatedAtText: s__('PackageRegistry|%{name} version %{version} was updated %{datetime}'),
    commitText: s__('PackageRegistry|Commit %{link} on branch %{branch}'),
    pipelineText: s__('PackageRegistry|Pipeline %{link} triggered %{datetime} by %{author}'),
    publishText: s__('PackageRegistry|Published to the %{project} Package Registry %{datetime}'),
  },
  components: {
    GlLink,
    GlSprintf,
    HistoryItem,
    TimeAgoTooltip,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showDescription: false,
    };
  },
  computed: {
    packagePipeline() {
      return this.packageEntity.pipeline?.id ? this.packageEntity.pipeline : null;
    },
  },
};
</script>

<template>
  <div class="issuable-discussion">
    <h3 class="gl-font-lg" data-testid="title">{{ __('History') }}</h3>
    <ul class="timeline main-notes-list notes gl-mb-4" data-testid="timeline">
      <history-item icon="clock" data-testid="created-on">
        <gl-sprintf :message="$options.i18n.createdOn">
          <template #name>
            <strong>{{ packageEntity.name }}</strong>
          </template>
          <template #version>
            <strong>{{ packageEntity.version }}</strong>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="packageEntity.created_at" />
          </template>
        </gl-sprintf>
      </history-item>
      <history-item icon="pencil" data-testid="updated-at">
        <gl-sprintf :message="$options.i18n.updatedAtText">
          <template #name>
            <strong>{{ packageEntity.name }}</strong>
          </template>
          <template #version>
            <strong>{{ packageEntity.version }}</strong>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="packageEntity.updated_at" />
          </template>
        </gl-sprintf>
      </history-item>
      <template v-if="packagePipeline">
        <history-item icon="commit" data-testid="commit">
          <gl-sprintf :message="$options.i18n.commitText">
            <template #link>
              <gl-link :href="packagePipeline.project.commit_url">{{
                packagePipeline.sha
              }}</gl-link>
            </template>
            <template #branch>
              <strong>{{ packagePipeline.ref }}</strong>
            </template>
          </gl-sprintf>
        </history-item>
        <history-item icon="pipeline" data-testid="pipeline">
          <gl-sprintf :message="$options.i18n.pipelineText">
            <template #link>
              <gl-link :href="packagePipeline.project.pipeline_url"
                >#{{ packagePipeline.id }}</gl-link
              >
            </template>
            <template #datetime>
              <time-ago-tooltip :time="packagePipeline.created_at" />
            </template>
            <template #author>{{ packagePipeline.user.name }}</template>
          </gl-sprintf>
        </history-item>
      </template>
      <history-item icon="package" data-testid="published">
        <gl-sprintf :message="$options.i18n.publishText">
          <template #project>
            <strong>{{ projectName }}</strong>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="packageEntity.created_at" />
          </template>
        </gl-sprintf>
      </history-item>
    </ul>
  </div>
</template>
