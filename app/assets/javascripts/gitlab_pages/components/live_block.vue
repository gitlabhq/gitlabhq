<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { SHORT_DATE_FORMAT_WITH_TIME } from '~/vue_shared/constants';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

export default {
  name: 'PrimaryDeployment',
  components: {
    GlButton,
    GlSkeletonLoader,
    TimeAgo,
    CrudComponent,
  },
  i18n: {
    createdLabel: s__('Pages|Created'),
    deployJobLabel: s__('Pages|Deploy job'),
    lastUpdatedLabel: s__('Pages|Last updated'),
    liveSite: s__('Pages|Your Pages site is live at'),
    buttonLabel: s__('Pages|Visit site'),
  },
  static: {
    SHORT_DATE_FORMAT_WITH_TIME,
  },
  inject: ['projectFullPath', 'primaryDomain'],
  props: {
    deployment: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    domainName() {
      return this.primaryDomain || this.deployment.url;
    },
    ciBuildUrl() {
      return joinPaths(
        gon.relative_url_root || '/',
        this.projectFullPath,
        '/-/jobs/',
        `${this.deployment.ciBuildId}`,
      );
    },
  },
};
</script>

<template>
  <crud-component header-class="gl-rounded-lg gl-border-b-0 gl-gap-y-3" body-class="gl-hidden">
    <template v-if="isLoading" #title>
      <gl-skeleton-loader v-if="isLoading" :width="400" :lines="2" />
    </template>
    <template v-else #title>
      <span data-testid="live-heading">
        {{ $options.i18n.liveSite }}
        <a
          v-if="deployment.active"
          :href="domainName"
          target="_blank"
          data-testid="live-heading-link"
        >
          {{ domainName }}
        </a>
        <span v-else class="gl-text-subtle">
          {{ domainName }}
        </span>
        🎉
      </span>
    </template>

    <template v-if="!isLoading" #description>
      {{ $options.i18n.deployJobLabel }}
      <a :href="ciBuildUrl" data-testid="deploy-job-number">{{ deployment.ciBuildId }}</a>

      <template v-if="deployment.updatedAt">
        <span aria-hidden="true">·</span>
        {{ $options.i18n.lastUpdatedLabel }}
        <time-ago :time="deployment.updatedAt" data-testid="last-updated-date" />
      </template>
    </template>

    <template v-if="!isLoading" #actions>
      <gl-button
        icon="external-link"
        :href="domainName"
        target="_blank"
        data-testid="visit-site-url"
      >
        {{ $options.i18n.buttonLabel }}
      </gl-button>
    </template>
  </crud-component>
</template>
