<script>
import emptyEnvironmentsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-environment-md.svg';
import { GlButton, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import EmptyResult from '~/vue_shared/components/empty_result.vue';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
    EmptyResult,
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
    title: s__('Environments|Get started with environments'),
    content: s__(
      'Environments|Environments are places where code gets deployed, such as staging or production. You can create an environment in the UI or in your .gitlab-ci.yml file. You can also enable review apps, which assist with providing an environment to showcase product changes. %{linkStart}Learn more%{linkEnd} about environments.',
    ),
    newEnvironmentButtonLabel: s__('Environments|Create an environment'),
    enablingReviewButtonLabel: s__('Environments|Enable review apps'),
  },
  emptyEnvironmentsSvgPath,
};
</script>
<template>
  <empty-result v-if="hasTerm" type="search" />
  <gl-empty-state
    v-else
    class="gl-mx-auto gl-max-w-limited"
    :title="$options.i18n.title"
    :svg-path="$options.emptyEnvironmentsSvgPath"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.content">
        <template #link="{ content: contentToDisplay }">
          <gl-link :href="helpPath">{{ contentToDisplay }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <template v-if="!hasTerm" #actions>
      <gl-button
        class="gl-mx-2 gl-mb-3"
        :href="newEnvironmentPath"
        variant="confirm"
        data-testid="new-environment-button"
      >
        {{ $options.i18n.newEnvironmentButtonLabel }}
      </gl-button>
      <gl-button
        class="gl-mx-2 gl-mb-3"
        data-testid="enable-review-button"
        @click="$emit('enable-review')"
      >
        {{ $options.i18n.enablingReviewButtonLabel }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
