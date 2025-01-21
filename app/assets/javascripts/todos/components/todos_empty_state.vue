<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import emptyTodosAllDoneSvg from '@gitlab/svgs/dist/illustrations/empty-todos-all-done-md.svg';
import emptyTodosSvg from '@gitlab/svgs/dist/illustrations/empty-todos-md.svg';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { TODO_EMPTY_TITLE_POOL, TABS_INDICES } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  inject: {
    currentTab: {
      type: Number,
      required: true,
    },
    issuesDashboardPath: {
      type: String,
      required: true,
    },
    mergeRequestsDashboardPath: {
      type: String,
      required: true,
    },
  },
  props: {
    isFiltered: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    title() {
      if (this.isFiltered) {
        return s__('Todos|Sorry, your filter produced no results');
      }
      if (this.isSnoozedTab) {
        return s__('Todos|There are no snoozed to-do items yet.');
      }
      if (this.isDoneTab) {
        return s__('Todos|There are no done to-do items yet.');
      }
      return this.pickRandomTitle();
    },
    illustration() {
      if (this.isFiltered || this.isDoneTab) {
        return this.$options.emptyTodosSvg;
      }
      return this.$options.emptyTodosAllDoneSvg;
    },
    isDoneTab() {
      return this.currentTab === TABS_INDICES.done;
    },
    isSnoozedTab() {
      return this.currentTab === TABS_INDICES.snoozed;
    },
  },
  methods: {
    pickRandomTitle() {
      return this.$options.titles[Math.floor(Math.random() * this.$options.titles.length)];
    },
  },

  emptyTodosAllDoneSvg,
  emptyTodosSvg,
  docsPath: helpPagePath('user/todos', { anchor: 'actions-that-create-to-do-items' }),
  titles: TODO_EMPTY_TITLE_POOL,

  i18n: {
    whatNext: s__(
      'Todos|Not sure where to go next? Take a look at your %{assignedIssuesLinkStart}assigned issues%{assignedIssuesLinkEnd} or %{mergeRequestLinkStart}merge requests%{mergeRequestLinkEnd}.',
    ),
  },
};
</script>

<template>
  <gl-empty-state :title="title" :svg-path="illustration">
    <template v-if="!isFiltered && isSnoozedTab" #description>
      <p>{{ s__('Todos|When to-do items are snoozed, they will appear here.') }}</p>
    </template>
    <template v-else-if="!isFiltered && !isDoneTab" #description>
      <p>
        <gl-sprintf :message="$options.i18n.whatNext">
          <template #assignedIssuesLink="{ content }">
            <gl-link :href="issuesDashboardPath">{{ content }}</gl-link>
          </template>
          <template #mergeRequestLink="{ content }">
            <gl-link :href="mergeRequestsDashboardPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <p>
        <a :href="$options.docsPath" target="_blank" data-testid="doc-link">
          {{ s__('Todos| What actions create to-do items?') }}
        </a>
      </p>
    </template>
    <template v-else-if="!isFiltered && isDoneTab" #description>
      <p>{{ s__('Todos|When to-do items are done, they will appear here.') }}</p>
    </template>
  </gl-empty-state>
</template>
