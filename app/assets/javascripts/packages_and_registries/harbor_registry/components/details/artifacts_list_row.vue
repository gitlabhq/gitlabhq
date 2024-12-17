<script>
import { GlTooltipDirective, GlSprintf, GlIcon } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  DIGEST_LABEL,
  CREATED_AT_LABEL,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
} from '~/packages_and_registries/harbor_registry/constants';
import { artifactPullCommand } from '~/packages_and_registries/harbor_registry/utils';

export default {
  name: 'TagsListRow',
  components: {
    GlSprintf,
    GlIcon,
    ListItem,
    ClipboardButton,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['repositoryUrl', 'harborIntegrationProjectName'],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    digestLabel: DIGEST_LABEL,
    createdAtLabel: CREATED_AT_LABEL,
  },
  computed: {
    formattedSize() {
      return this.artifact.size
        ? numberToHumanSize(Number(this.artifact.size))
        : NOT_AVAILABLE_SIZE;
    },
    tagsCountText() {
      const count = this.artifact?.tags.length ? this.artifact?.tags.length : 0;

      return n__('%d tag', '%d tags', count);
    },
    shortDigest() {
      // remove sha256: from the string, and show only the first 7 char
      const PREFIX_LENGTH = 'sha256:'.length;
      const DIGEST_LENGTH = 7;
      return (
        this.artifact.digest?.substring(PREFIX_LENGTH, PREFIX_LENGTH + DIGEST_LENGTH) ??
        NOT_AVAILABLE_TEXT
      );
    },
    getPullCommand() {
      if (this.artifact?.digest) {
        const { image } = this.$route.params;
        return artifactPullCommand({
          digest: this.artifact.digest,
          imageName: image,
          repositoryUrl: this.repositoryUrl,
          harborProjectName: this.harborIntegrationProjectName,
        });
      }

      return '';
    },
    linkTo() {
      const { project, image } = this.$route.params;

      return { name: 'tags', params: { project, image, digest: this.artifact.digest } };
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <div class="gl-flex gl-items-center">
        <router-link
          class="gl-break-all gl-font-bold gl-text-default"
          data-testid="name"
          :to="linkTo"
        >
          {{ artifact.digest }}
        </router-link>
        <clipboard-button
          v-if="getPullCommand"
          :title="getPullCommand"
          :text="getPullCommand"
          category="tertiary"
        />
      </div>
    </template>

    <template #left-secondary>
      <span class="gl-mr-3" data-testid="size">
        {{ formattedSize }}
      </span>
      <span id="tagsCount" class="gl-flex gl-items-center" data-testid="tags-count">
        <gl-icon name="tag" class="gl-mr-2" />
        {{ tagsCountText }}
      </span>
    </template>
    <template #right-primary>
      <span data-testid="time">
        <gl-sprintf :message="$options.i18n.createdAtLabel">
          <template #timeInfo>
            <time-ago-tooltip :time="artifact.pushTime" />
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #right-secondary>
      <span data-testid="digest">
        <gl-sprintf :message="$options.i18n.digestLabel">
          <template #imageId>{{ shortDigest }}</template>
        </gl-sprintf>
      </span>
      <clipboard-button
        v-if="artifact.digest"
        :title="artifact.digest"
        :text="artifact.digest"
        category="tertiary"
      />
    </template>
  </list-item>
</template>
