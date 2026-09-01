import FocusCarousel from './focus_carousel.vue';

const items = [
  {
    id: 'item-1',
    title: 'Roll out API rate limiting',
    timestamp: '2026-08-18T13:00:00.000Z',
    meta: ['Duo UI', 'Software development'],
    summary:
      'The rollout plan is drafted and waiting for approval: staged limits per tier, with a dry-run week before enforcement.',
    status: { text: 'Plan approval required', variant: 'warning', icon: 'status' },
    href: 'https://gitlab.example.com/items/1',
  },
  {
    id: 'item-2',
    title: 'Fix nightly pipeline dependency error',
    timestamp: '2026-08-18T11:20:00.000Z',
    meta: ['Duo UI', 'Fix pipeline'],
    summary:
      'The nightly job failed twice on the same missing-package error, so the retry loop stopped and flagged it for a person.',
    status: { text: 'Failed', variant: 'danger', icon: 'status-alert' },
    href: 'https://gitlab.example.com/items/2',
  },
  {
    id: 'item-3',
    title: 'Bulk-archive stale projects',
    timestamp: '2026-08-18T08:00:00.000Z',
    meta: ['Smoke Tests', 'Software development'],
    summary: null,
    status: { text: 'Finished', variant: 'success', icon: 'status-success' },
    href: null,
    actionable: true,
  },
  {
    id: 'item-4',
    title: 'Migrate avatar uploads to object storage',
    timestamp: '2026-08-17T16:00:00.000Z',
    meta: ['Software development'],
    summary:
      'New uploads work end to end; backfilling existing avatars is a migration-strategy decision with real cost either way.',
    status: { text: 'Finished', variant: 'success', icon: 'status-success' },
    href: 'https://gitlab.example.com/items/4',
  },
];

const Template = (args, { argTypes }) => ({
  components: { FocusCarousel },
  props: Object.keys(argTypes),
  template: `
    <div style="height: 640px;">
      <focus-carousel v-bind="$props" />
    </div>
  `,
});

const defaultArgs = {
  regionLabel: 'Recent items',
  emptyStateText: 'No recent items',
  actionLabel: 'Open item',
  actionIcon: 'doc-text',
};

export const Default = Template.bind({});
Default.args = { ...defaultArgs, items };

export const SingleItem = Template.bind({});
SingleItem.args = { ...defaultArgs, items: [items[1]] };

export const TwoItems = Template.bind({});
TwoItems.args = { ...defaultArgs, items: items.slice(2) };

export const ActionableWithoutHref = Template.bind({});
ActionableWithoutHref.args = { ...defaultArgs, items: [items[2]] };

export const NoActionAffordance = Template.bind({});
NoActionAffordance.args = {
  ...defaultArgs,
  items: [{ ...items[2], href: null, actionable: false }],
};

export const MinimalItems = Template.bind({});
MinimalItems.args = {
  ...defaultArgs,
  items: items.map(({ id, title }) => ({ id, title })),
};

export const LongTitle = Template.bind({});
LongTitle.args = {
  ...defaultArgs,
  items: [
    {
      ...items[0],
      title:
        'Reconcile the observability field standardisation rollout across all twelve ingestion pipelines without breaking existing dashboards',
    },
    ...items.slice(1),
  ],
};

export const Loading = Template.bind({});
Loading.args = { ...defaultArgs, items: [], loading: true };

export const Empty = Template.bind({});
Empty.args = { ...defaultArgs, items: [] };

export default {
  component: FocusCarousel,
  title: 'vue_shared/focus_carousel',
};
