<script>
import emptyEntironmentsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-environment-md.svg';
import { GlButton, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  inject: ['newEnvironmentPath'],
  props: {
    helpPath: {
      type: String,
      required: true,
    },
    hasTerm: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return this.hasTerm ? this.$options.i18n.searchingTitle : this.$options.i18n.title;
    },
    content() {
      return this.hasTerm ? this.$options.i18n.searchingContent : this.$options.i18n.content;
    },
  },
  i18n: {
    searchingTitle: s__('Environments|No results found'),
    title: s__('Environments|Get started with environments'),
    searchingContent: s__('Environments|Edit your search and try again'),
    content: s__(
      'Environments|Environments are places where code gets deployed, such as staging or production. You can create an environment in the UI or in your .gitlab-ci.yml file. You can also enable review apps, which assist with providing an environment to showcase product changes. %{linkStart}Learn more%{linkEnd} about environments.',
    ),
    newEnvironmentButtonLabel: s__('Environments|Create an environment'),
    enablingReviewButtonLabel: s__('Environments|Enable review apps'),
  },
  emptyEntironmentsSvgPath,
};
</script>
<template>
  <gl-empty-state
    class="gl-max-w-limited gl-mx-auto"
    :title="title"
    :svg-path="$options.emptyEntironmentsSvgPath"
  >
    <template #description>
      <gl-sprintf :message="content">
        <template #link="{ content: contentToDisplay }">
          <gl-link :href="helpPath">{{ contentToDisplay }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <template v-if="!hasTerm" #actions>
      <gl-button class="gl-mx-2 gl-mb-3" :href="newEnvironmentPath" variant="confirm">
        {{ $options.i18n.newEnvironmentButtonLabel }}
      </gl-button>
      <gl-button class="gl-mx-2 gl-mb-3" @click="$emit('enable-review')">
        {{ $options.i18n.enablingReviewButtonLabel }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
