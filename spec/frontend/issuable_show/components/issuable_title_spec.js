import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlButton, GlIntersectionObserver } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import IssuableTitle from '~/issuable_show/components/issuable_title.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

const issuableTitleProps = {
  issuable: mockIssuable,
  ...mockIssuableShowProps,
};

const createComponent = (propsData = issuableTitleProps) =>
  shallowMount(IssuableTitle, {
    propsData,
    stubs: {
      transition: true,
    },
    slots: {
      'status-badge': 'Open',
    },
    directives: {
      GlTooltip: createMockDirective(),
    },
  });

describe('IssuableTitle', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('handleTitleAppear', () => {
      it('sets value of `stickyTitleVisible` prop to false', () => {
        wrapper.find(GlIntersectionObserver).vm.$emit('appear');

        expect(wrapper.vm.stickyTitleVisible).toBe(false);
      });
    });

    describe('handleTitleDisappear', () => {
      it('sets value of `stickyTitleVisible` prop to true', () => {
        wrapper.find(GlIntersectionObserver).vm.$emit('disappear');

        expect(wrapper.vm.stickyTitleVisible).toBe(true);
      });
    });
  });

  describe('template', () => {
    it('renders issuable title', async () => {
      const wrapperWithTitle = createComponent({
        ...mockIssuableShowProps,
        issuable: {
          ...mockIssuable,
          titleHtml: '<b>Sample</b> title',
        },
      });

      await wrapperWithTitle.vm.$nextTick();
      const titleEl = wrapperWithTitle.find('h2');

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.html()).toBe('<h2 dir="auto" class="title qa-title"><b>Sample</b> title</h2>');

      wrapperWithTitle.destroy();
    });

    it('renders edit button', () => {
      const editButtonEl = wrapper.find(GlButton);
      const tooltip = getBinding(editButtonEl.element, 'gl-tooltip');

      expect(editButtonEl.exists()).toBe(true);
      expect(editButtonEl.props('icon')).toBe('pencil');
      expect(editButtonEl.attributes('title')).toBe('Edit title and description');
      expect(tooltip).toBeDefined();
    });

    it('renders sticky header when `stickyTitleVisible` prop is true', async () => {
      wrapper.setData({
        stickyTitleVisible: true,
      });

      await wrapper.vm.$nextTick();
      const stickyHeaderEl = wrapper.find('[data-testid="header"]');

      expect(stickyHeaderEl.exists()).toBe(true);
      expect(stickyHeaderEl.find(GlIcon).props('name')).toBe(issuableTitleProps.statusIcon);
      expect(stickyHeaderEl.text()).toContain('Open');
      expect(stickyHeaderEl.text()).toContain(issuableTitleProps.issuable.title);
    });
  });
});
