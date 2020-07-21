<script>
import { GlAvatar, GlTooltipDirective, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { __, s__ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  name: 'PackageActivity',
  components: {
    ClipboardButton,
    GlAvatar,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  data() {
    return {
      showDescription: false,
    };
  },
  computed: {
    ...mapState(['packageEntity']),
    ...mapGetters(['packagePipeline']),
    publishedDate() {
      return formatDate(this.packageEntity.created_at, 'HH:MM yyyy-mm-dd');
    },
  },
  methods: {
    toggleShowDescription() {
      this.showDescription = !this.showDescription;
    },
  },
  i18n: {
    showCommit: __('Show commit description'),
    pipelineText: s__(
      'PackageRegistry|Pipeline %{linkStart}%{linkEnd} triggered %{timestamp} by %{author}',
    ),
    publishText: s__('PackageRegistry|Published to the repository at %{timestamp}'),
  },
};
</script>

<template>
  <div class="mb-3">
    <h3 class="gl-font-lg">{{ __('Activity') }}</h3>

    <div ref="commit-info" class="info-well">
      <div v-if="packagePipeline" class="well-segment">
        <div class="d-flex align-items-center">
          <gl-icon name="commit" class="d-none d-sm-block" />

          <button
            v-if="packagePipeline.git_commit_message"
            ref="commit-message-toggle"
            v-gl-tooltip
            :title="$options.i18n.showCommit"
            :aria-label="$options.i18n.showCommit"
            class="text-expander mr-2 d-none d-sm-flex"
            type="button"
            @click="toggleShowDescription"
          >
            <gl-icon name="ellipsis_h" :size="12" />
          </button>

          <gl-link :href="`../../commit/${packagePipeline.sha}`">{{ packagePipeline.sha }}</gl-link>

          <clipboard-button
            :text="packagePipeline.sha"
            :title="__('Copy commit SHA')"
            css-class="border-0 text-secondary py-0"
          />
        </div>

        <div v-if="showDescription" ref="commit-message" class="mt-2 d-none d-sm-block">
          <pre class="commit-row-description mb-0 pl-2">{{
            packagePipeline.git_commit_message
          }}</pre>
        </div>
      </div>

      <div v-if="packagePipeline" ref="pipeline-info" class="well-segment">
        <div class="d-flex align-items-center">
          <gl-icon name="pipeline" class="mr-2 d-none d-sm-block" />

          <gl-sprintf :message="$options.i18n.pipelineText">
            <template #link>
              &nbsp;
              <gl-link :href="`../../pipelines/${packagePipeline.id}`"
                >#{{ packagePipeline.id }}</gl-link
              >
              &nbsp;
            </template>

            <template #timestamp>
              <span v-gl-tooltip :title="tooltipTitle(packagePipeline.created_at)">
                &nbsp;{{ timeFormatted(packagePipeline.created_at) }}&nbsp;
              </span>
            </template>

            <template #author
              >{{ packagePipeline.user.name }}
              <gl-avatar
                class="ml-2 d-none d-sm-block"
                :src="packagePipeline.user.avatar_url"
                :size="24"
            /></template>
          </gl-sprintf>
        </div>
      </div>

      <div class="well-segment d-flex align-items-center">
        <gl-icon name="clock" class="mr-2 d-none d-sm-block" />

        <gl-sprintf :message="$options.i18n.publishText">
          <template #timestamp>
            {{ publishedDate }}
          </template>
        </gl-sprintf>
      </div>
    </div>
  </div>
</template>
