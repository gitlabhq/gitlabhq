import { GlIcon, GlBadge, GlButton, GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import IssuableTitle from '~/vue_shared/issuable/show/components/issuable_title.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

const issuableTitleProps = {
  issuable: mockIssuable,
  ...mockIssuableShowProps,
};

const createComponent = (propsData = issuableTitleProps) =>
  shallowMountExtended(IssuableTitle, {
    propsData,
    slots: {
      'status-badge': 'Open',
    },
    directives: {
      GlTooltip: createMockDirective('gl-tooltip'),
    },
  });

describe('IssuableTitle', () => {
  let wrapper;

  const findStickyHeader = () => wrapper.findByTestId('header');

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('methods', () => {
    describe('handleTitleAppear', () => {
      it('sets value of `stickyTitleVisible` prop to false', async () => {
        wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');
        await nextTick();

        expect(findStickyHeader().exists()).toBe(false);
      });
    });

    describe('handleTitleDisappear', () => {
      it('sets value of `stickyTitleVisible` prop to true', async () => {
        wrapper.findComponent(GlIntersectionObserver).vm.$emit('disappear');
        await nextTick();

        expect(findStickyHeader().exists()).toBe(true);
      });
    });
  });

  describe('template', () => {
    const findTitleEl = (wrapperWithTitle) => wrapperWithTitle.findByTestId('issuable-title');

    it('renders issuable title with rendered references', async () => {
      const wrapperWithTitle = createComponent({
        ...mockIssuableShowProps,
        issuable: {
          ...mockIssuable,
          title: 'Sample with reference #1',
          titleHtml: 'Sample with reference <a href="example">#1</a>',
        },
      });

      await nextTick();
      const titleEl = findTitleEl(wrapperWithTitle);

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.element.innerHTML.trim()).toBe(
        'Sample with reference <a href="example">#1</a>',
      );

      wrapperWithTitle.destroy();
    });

    it('renders edit button', () => {
      const editButtonEl = wrapper.findComponent(GlButton);
      const tooltip = getBinding(editButtonEl.element, 'gl-tooltip');

      expect(editButtonEl.exists()).toBe(true);
      expect(editButtonEl.props('icon')).toBe('pencil');
      expect(editButtonEl.attributes('title')).toBe('Edit title and description');
      expect(tooltip).toBeDefined();
    });

    describe('sticky header', () => {
      it('renders when `stickyTitleVisible` prop is true', async () => {
        wrapper.findComponent(GlIntersectionObserver).vm.$emit('disappear');
        await nextTick();

        const stickyHeaderEl = findStickyHeader();

        expect(stickyHeaderEl.exists()).toBe(true);
        expect(stickyHeaderEl.findComponent(GlBadge).props('variant')).toBe('success');
        expect(stickyHeaderEl.findComponent(GlIcon).props('name')).toBe(
          issuableTitleProps.statusIcon,
        );
        expect(stickyHeaderEl.text()).toContain('Open');
        expect(stickyHeaderEl.findComponent(ConfidentialityBadge).exists()).toBe(false);
        expect(stickyHeaderEl.text()).toContain(issuableTitleProps.issuable.title);
      });

      it('renders ConfidentialityBadge when issuable is confidential', async () => {
        wrapper = createComponent({
          ...mockIssuableShowProps,
          issuable: {
            ...mockIssuable,
            confidential: true,
          },
        });

        wrapper.findComponent(GlIntersectionObserver).vm.$emit('disappear');
        await nextTick();

        const stickyHeaderEl = findStickyHeader();

        expect(stickyHeaderEl.findComponent(ConfidentialityBadge).exists()).toBe(true);
      });
    });
  });
});
