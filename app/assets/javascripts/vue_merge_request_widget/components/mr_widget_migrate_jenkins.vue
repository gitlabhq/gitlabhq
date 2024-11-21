<script>
import { GlBadge, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { reportToSentry } from '~/ci/utils';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { InternalEvents } from '~/tracking';
import { JM_JENKINS_TITLE_ICON_NAME, JM_MIGRATION_LINK, JM_EVENT_NAME } from '../constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'MRWidgetMigrateJenkinsCallout',
  JM_JENKINS_TITLE_ICON_NAME,
  JM_EVENT_NAME,
  JM_MIGRATION_LINK,
  components: {
    GlBadge,
    GlLink,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [trackingMixin],
  props: {
    humanAccess: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    featureId: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: s__('mrWidget|Migrate to GitLab CI/CD from Jenkins'),
    description: s__(
      'mrWidget|Take advantage of simple, scalable pipelines and CI/CD enabled features. You can view integration results, security scans, tests, code coverage and more directly in merge requests!',
    ),
    migrationPlan: s__('mrWidget|Start with migration plan'),
    information: s__('mrWidget|Information'),
  },
  methods: {
    dismiss() {
      axios
        .post(this.path, {
          feature_name: this.featureId,
        })
        .catch((error) => {
          reportToSentry(this.$options.name, error);
        });

      this.trackEvent(this.$options.JM_EVENT_NAME);

      this.$emit('dismiss');
    },
  },
};
</script>
<template>
  <div class="mr-widget-body mr-pipeline-suggest gl-mb-3">
    <div class="gl-flex gl-items-center gl-justify-between">
      <gl-badge
        v-gl-tooltip.viewport.left
        class="ci-icon ci-icon-variant-info gl-mr-3 gl-self-start gl-p-2 gl-pl-2"
        variant="info"
        :title="$options.i18n.information"
        :href="$options.MIGRATION_LINK"
        data-testid="ci-icon"
      >
        <span class="ci-icon-gl-icon-wrapper"
          ><gl-icon :name="$options.JM_JENKINS_TITLE_ICON_NAME"
        /></span>
      </gl-badge>
      <div class="gl-flex gl-items-center gl-justify-between">
        <div class="gl-flex gl-flex-wrap gl-items-center gl-justify-between">
          <div class="gl-flex gl-w-full gl-flex-wrap">
            <strong class="gl-flex gl-grow">{{ $options.i18n.title }}</strong>
            <div class="gl-flex">
              <gl-link
                data-testid="migration-plan"
                :href="$options.JM_MIGRATION_LINK"
                target="blank"
                >{{ $options.i18n.migrationPlan }}</gl-link
              >
              <button
                :aria-label="__('Close')"
                class="gl-ml-4 gl-border-0 gl-border-l-2 gl-border-solid gl-bg-transparent gl-p-0 gl-pl-2"
                type="button"
                data-testid="close"
                @click="dismiss"
              >
                <gl-icon name="close" />
              </button>
            </div>
          </div>
          <div class="gl-mt-2">
            {{ $options.i18n.description }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
