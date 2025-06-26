<script>
import { GlIcon, GlBadge, GlMarkdown, GlLink, GlAvatar, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { sprintf, s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { AI_CATALOG_AGENTS_SHOW_ROUTE } from '../router/constants';

export default {
  name: 'AiCatalogListItem',
  components: {
    GlIcon,
    GlBadge,
    GlMarkdown,
    GlLink,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    fullDate() {
      if (!this.item.releasedAt) return undefined;
      const date = new Date(this.item.releasedAt);
      if (Number.isNaN(date.getTime())) return undefined;
      return formatDate(date);
    },
    releasedTooltipTitle() {
      if (!this.fullDate) return undefined;
      return sprintf(s__('AiCatalog|Released %{fullDate}'), {
        fullDate: this.fullDate,
      });
    },
  },
  methods: {
    formatId(id) {
      return getIdFromGraphQLId(id);
    },
  },
  showRoute: AI_CATALOG_AGENTS_SHOW_ROUTE,
};
</script>

<template>
  <li
    data-testid="ai-catalog-list-item"
    class="gl-flex gl-items-center gl-border-b-1 gl-border-default gl-py-3 gl-text-subtle gl-border-b-solid"
  >
    <gl-avatar
      :alt="`${item.name} avatar`"
      :entity-name="item.name"
      :size="48"
      class="gl-mr-4 gl-self-start"
    />
    <div class="gl-flex gl-grow gl-flex-col gl-gap-1">
      <div>
        <span class="gl-text-sm">{{ item.model }}</span>
        <gl-icon
          v-if="item.verified"
          name="tanuki-verified"
          class="gl-ml-1 gl-text-status-info"
          :size="16"
          data-testid="tanuki-verified-icon"
        />
      </div>

      <div class="gl-mb-1 gl-flex gl-flex-wrap gl-items-center gl-gap-2">
        <gl-link :to="{ name: $options.showRoute, params: { id: formatId(item.id) } }">
          {{ item.name }}
        </gl-link>
        <gl-badge variant="neutral" class="gl-self-center">{{ item.type }}</gl-badge>
        <gl-badge v-gl-tooltip="releasedTooltipTitle" variant="info" class="gl-self-center">
          {{ item.version }}
        </gl-badge>
      </div>

      <div v-if="item.description" class="gl-line-clamp-2 gl-break-words gl-text-default">
        <gl-markdown compact class="gl-text-sm">{{ item.description }}</gl-markdown>
      </div>
    </div>
  </li>
</template>
