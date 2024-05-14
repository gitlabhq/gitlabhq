<script>
import { GlLink, GlButton } from '@gitlab/ui';
import ShowMore from '~/vue_shared/components/show_more.vue';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import { s__ } from '~/locale';
import AsideItem from './aside_item.vue';

export default {
  components: {
    AsideItem,
    AssigneeAvatarLink,
    ShowMore,
    GlButton,
    GlLink,
  },
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
  computed: {
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
    hasRef() {
      return this.deployment?.ref;
    },
    hasUrl() {
      return Boolean(this.environment.externalUrl);
    },
  },
  i18n: {
    openUrl: s__('Deployment|Open URL'),
    triggerer: s__('Deployment|Triggerer'),
    relatedTags: s__('Deployment|Related Tags'),
    job: s__('Deployment|Job'),
    branch: s__('Deployment|Branch'),
    tag: s__('Deployment|Tag'),
  },
};
</script>
<template>
  <aside v-if="!loading" class="gl-mt-4 gl-border-l-0 gl-ml-4">
    <gl-button
      v-if="hasUrl"
      category="secondary"
      variant="confirm"
      :href="environment.externalUrl"
      is-unsafe-link
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      {{ $options.i18n.openUrl }}
    </gl-button>

    <aside-item class="gl-mt-8 gl-pb-5 gl-border-b-solid gl-border-b-1 gl-border-gray-50">
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
  </aside>
</template>
