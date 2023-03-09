import { GlTab, GlBadge } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import { setLanguage } from 'helpers/locale_helper';

import IssuableTabs from '~/vue_shared/issuable/list/components/issuable_tabs.vue';

import { mockIssuableListProps } from '../mock_data';

const createComponent = ({
  tabs = mockIssuableListProps.tabs,
  tabCounts = mockIssuableListProps.tabCounts,
  currentTab = mockIssuableListProps.currentTab,
  truncateCounts = false,
  mountFn = shallowMount,
} = {}) =>
  mountFn(IssuableTabs, {
    propsData: {
      tabs,
      tabCounts,
      currentTab,
      truncateCounts,
    },
    slots: {
      'nav-actions': `<button class="js-new-issuable">New issuable</button>`,
    },
  });

describe('IssuableTabs', () => {
  let wrapper;

  beforeEach(() => {
    setLanguage('en');
  });

  afterEach(() => {
    setLanguage(null);
  });

  const findAllGlBadges = () => wrapper.findAllComponents(GlBadge);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);

  describe('tabs', () => {
    it.each`
      currentTab  | returnValue
      ${'opened'} | ${'true'}
      ${'closed'} | ${undefined}
    `(
      'when "$currentTab" is the selected tab, the Open tab is active=$returnValue',
      ({ currentTab, returnValue }) => {
        wrapper = createComponent({ currentTab });

        const openTab = findAllGlTabs().at(0);

        expect(openTab.attributes('active')).toBe(returnValue);
      },
    );
  });

  describe('template', () => {
    it('renders gl-tab for each tab within `tabs` array', () => {
      wrapper = createComponent();

      const tabs = findAllGlTabs();

      expect(tabs).toHaveLength(mockIssuableListProps.tabs.length);
    });

    it('renders gl-badge component within a tab', async () => {
      wrapper = createComponent({ mountFn: mount });
      await nextTick();

      const badges = findAllGlBadges();

      // Does not render `All` badge since it has an undefined count
      expect(badges).toHaveLength(2);
      expect(badges.at(0).text()).toBe('5,678');
      expect(badges.at(1).text()).toBe(`${mockIssuableListProps.tabCounts.closed}`);
    });

    it('renders contents for slot "nav-actions"', () => {
      wrapper = createComponent();

      const button = wrapper.find('button.js-new-issuable');

      expect(button.text()).toBe('New issuable');
    });
  });

  describe('counts', () => {
    it('can display as truncated', async () => {
      wrapper = createComponent({ truncateCounts: true, mountFn: mount });
      await nextTick();

      expect(findAllGlBadges().at(0).text()).toBe('5.7k');
    });
  });

  describe('events', () => {
    it('gl-tab component emits `click` event on `click` event', () => {
      wrapper = createComponent();

      const openTab = findAllGlTabs().at(0);

      openTab.vm.$emit('click', 'opened');

      expect(wrapper.emitted('click')).toEqual([['opened']]);
    });
  });
});
