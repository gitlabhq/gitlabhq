<script>
import { GlLink, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import ShowMore from '~/vue_shared/components/show_more.vue';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import { __, s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { InternalEvents } from '~/tracking';
import { CLICK_PIPELINE_LINK_ON_DEPLOYMENT_PAGE } from '~/deployments/utils';
import AsideItem from './aside_item.vue';

export default {
  components: {
    AsideItem,
    AssigneeAvatarLink,
    ShowMore,
    GlButton,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    deployment: {
      required: true,
      type: Object,
    },
    environment: {
      required: true,
      type: Object,
    },
    loading: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isDesktop: bp.isDesktop(),
      isExpanded: false,
    };
  },
  computed: {
    isMobile() {
      return !this.isDesktop;
    },
    triggererClasses() {
      return this.isDesktop ? 'gl-mt-8 gl-border-subtle' : 'gl-mt-5';
    },
    toggleCategory() {
      return this.isExpanded ? 'tertiary' : 'secondary';
    },
    toggleIcon() {
      return this.isExpanded ? 'chevron-double-lg-right' : 'chevron-double-lg-left';
    },
    toggleLabel() {
      return this.isExpanded ? __('Collapse sidebar') : __('Expand sidebar');
    },
    isShowAsideItems() {
      return this.isDesktop || this.isExpanded;
    },
    triggerer() {
      return this.deployment.triggerer;
    },
    hasTags() {
      return this.deployment.tags?.length > 0;
    },
    hasJob() {
      return Boolean(this.deployment?.job);
    },
    refTitle() {
      return this.deployment?.tag ? this.$options.i18n.tag : this.$options.i18n.branch;
    },
    hasUrl() {
      return Boolean(this.environment.externalUrl);
    },
    pipelineId() {
      return getIdFromGraphQLId(this.deployment.job.pipeline.id);
    },
  },
  mounted() {
    window.addEventListener('resize', this.handleWindowResize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleWindowResize);
  },
  methods: {
    handleWindowResize() {
      this.isDesktop = bp.isDesktop();
      if (this.isDesktop) this.isExpanded = false;
    },
    toggleSidebar() {
      this.isExpanded = !this.isExpanded;
    },
    trackPipelineLinkClick() {
      this.trackEvent(CLICK_PIPELINE_LINK_ON_DEPLOYMENT_PAGE);
    },
  },
  i18n: {
    openUrl: s__('Deployment|Open URL'),
    triggerer: s__('Deployment|Triggerer'),
    relatedTags: s__('Deployment|Related Tags'),
    pipeline: s__('Deployment|Pipeline'),
    job: s__('Deployment|Job'),
    branch: s__('Deployment|Branch'),
    tag: s__('Deployment|Tag'),
  },
};
</script>

<template>
  <aside
    v-if="!loading"
    :class="{
      'right-sidebar right-sidebar-expanded gl-shadow-md': isMobile && isExpanded,
      'gl-fixed gl-right-0': isMobile && !isExpanded,
    }"
    class="gl-border-l-0 gl-p-4"
    data-testid="deployment-sidebar"
  >
    <gl-button
      v-gl-tooltip.hover.left
      size="medium"
      class="gl-ml-auto gl-flex lg:gl-hidden"
      data-testid="deployment-sidebar-toggle-button"
      :category="toggleCategory"
      :icon="toggleIcon"
      :title="toggleLabel"
      :aria-label="toggleLabel"
      @click="toggleSidebar"
    />

    <div
      v-if="isShowAsideItems"
      data-testid="deployment-sidebar-items"
      :class="{ 'gl-border-t gl-mt-5': isMobile }"
    >
      <div
        v-if="hasUrl"
        data-testid="deployment-url-button-wrapper"
        :class="{
          'gl-border-b gl-mt-5 gl-pb-5': isMobile,
        }"
      >
        <gl-button
          category="secondary"
          variant="confirm"
          :href="environment.externalUrl"
          is-unsafe-link
          target="_blank"
          rel="noopener noreferrer nofollow"
        >
          {{ $options.i18n.openUrl }}
        </gl-button>
      </div>

      <aside-item
        data-testid="deployment-triggerer-item"
        :class="triggererClasses"
        class="gl-border-b gl-pb-5"
      >
        <template #header>
          {{ $options.i18n.triggerer }}
        </template>

        <assignee-avatar-link :user="triggerer" data-testid="deployment-triggerer">
          <span class="gl-ml-2">{{ triggerer.name }}</span>
        </assignee-avatar-link>
      </aside-item>

      <div class="gl-mt-5">
        <aside-item v-if="hasTags" class="gl-mb-3">
          <template #header>{{ $options.i18n.relatedTags }}</template>
          <show-more :items="deployment.tags" :limit="5">
            <template #default="{ item, isLast }">
              <span class="gl-mr-2">
                <gl-link :href="item.webPath">{{ item.name }}</gl-link
                ><template v-if="!isLast">,</template>
              </span>
            </template>
          </show-more>
        </aside-item>

        <aside-item v-if="hasJob" class="gl-mb-3" data-testid="deployment-pipeline">
          <template #header>{{ $options.i18n.pipeline }}</template>
          <gl-link
            :href="deployment.job.pipeline.path"
            data-testid="deployment-pipeline-link"
            @click="trackPipelineLinkClick"
          >
            #{{ pipelineId }}
          </gl-link>
        </aside-item>

        <aside-item v-if="hasJob" class="gl-mb-3">
          <template #header>{{ $options.i18n.job }}</template>
          <gl-link :href="deployment.job.webPath">
            {{ deployment.job.name }}
          </gl-link>
        </aside-item>

        <aside-item class="gl-mb-3" data-testid="deployment-ref">
          <template #header>{{ refTitle }}</template>
          <gl-link :href="deployment.refPath">
            {{ deployment.ref }}
          </gl-link>
        </aside-item>
      </div>
    </div>
  </aside>
</template>
