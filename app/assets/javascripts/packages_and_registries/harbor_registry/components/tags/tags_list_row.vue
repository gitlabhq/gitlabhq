<script>
import { GlSprintf } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { CREATED_AT_LABEL } from '~/packages_and_registries/harbor_registry/constants';
import { tagPullCommand } from '~/packages_and_registries/harbor_registry/utils';

export default {
  name: 'TagsListRow',
  components: {
    GlSprintf,
    ListItem,
    ClipboardButton,
    TimeAgoTooltip,
  },
  inject: ['harborIntegrationProjectName', 'repositoryUrl'],
  props: {
    tag: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    createdAtLabel: CREATED_AT_LABEL,
  },
  methods: {
    getPullCommand(tagName) {
      if (tagName) {
        const { image } = this.$route.params;

        return tagPullCommand({
          imageName: image,
          tag: tagName,
          repositoryUrl: this.repositoryUrl,
          harborProjectName: this.harborIntegrationProjectName,
        });
      }

      return '';
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <div class="gl-flex gl-items-center">
        <div data-testid="name" class="gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap">
          {{ tag.name }}
        </div>
        <clipboard-button
          :title="getPullCommand(tag.name)"
          :text="getPullCommand(tag.name)"
          category="tertiary"
        />
      </div>
    </template>

    <template #right-primary>
      <span data-testid="time">
        <gl-sprintf :message="$options.i18n.createdAtLabel">
          <template #timeInfo>
            <time-ago-tooltip :time="tag.pushTime" />
          </template>
        </gl-sprintf>
      </span>
    </template>
  </list-item>
</template>
