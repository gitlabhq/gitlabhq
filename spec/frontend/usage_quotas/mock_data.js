export const defaultProvide = {
  tabs: [],
};

export const provideWithTabs = {
  tabs: [
    {
      title: 'Tab 1 title',
      hash: '#tab-1-hash',
      testid: 'tab-1-testid',
      component: {
        name: 'Tab1Component',
        render: () => {},
      },
      tracking: {
        action: 'click_on_tab_on_usage_quotas',
      },
    },
    {
      title: 'Tab 2 title',
      hash: '#tab-2-hash',
      testid: 'tab-2-testid',
      component: {
        name: 'Tab2Component',
        render: () => {},
      },
    },
  ],
};
