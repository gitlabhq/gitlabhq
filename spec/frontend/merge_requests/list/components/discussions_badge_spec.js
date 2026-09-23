import { mount } from '@vue/test-utils';
import { GlBadge, GlIcon } from '@gitlab/ui';
import DiscussionsBadge from '~/merge_requests/list/components/discussions_badge.vue';

describe('Merge requests list discussions badge component', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findButton = () => wrapper.find('button');
  const findIcon = () => wrapper.findComponent(GlIcon);

  function createComponent(mergeRequest = {}, props = {}) {
    wrapper = mount(DiscussionsBadge, {
      propsData: {
        mergeRequest,
        ...props,
      },
    });
  }

  describe('when all discussions resolved', () => {
    beforeEach(() => {
      createComponent({
        resolvedDiscussionsCount: 1,
        resolvableDiscussionsCount: 1,
      });
    });

    it('renders badge as success variant', () => {
      expect(findBadge().props('variant')).toBe('success');
    });

    it('renders resolved text', () => {
      expect(wrapper.text()).toBe('Resolved');
    });

    it('renders resolved tooltip', () => {
      expect(findButton().attributes('title')).toBe('The only thread is resolved');
    });
  });

  describe('when not all discussions resolved', () => {
    it('renders badge as success variant', () => {
      createComponent({
        resolvedDiscussionsCount: 0,
        resolvableDiscussionsCount: 2,
      });

      expect(findBadge().props('variant')).toBe('neutral');
    });

    it.each`
      resolvedDiscussionsCount | resolvableDiscussionsCount | message
      ${0}                     | ${2}                       | ${'0 of 2'}
      ${1}                     | ${2}                       | ${'1 of 2'}
    `(
      'renders text with correct $message',
      ({ resolvedDiscussionsCount, resolvableDiscussionsCount, message }) => {
        createComponent({
          resolvedDiscussionsCount,
          resolvableDiscussionsCount,
        });

        expect(wrapper.text()).toBe(message);
      },
    );

    it.each`
      resolvedDiscussionsCount | resolvableDiscussionsCount | tooltip
      ${0}                     | ${2}                       | ${'0 of 2 threads resolved'}
      ${1}                     | ${2}                       | ${'1 of 2 threads resolved'}
    `(
      'renders tooltip with correct $tooltip',
      ({ resolvedDiscussionsCount, resolvableDiscussionsCount, tooltip }) => {
        createComponent({
          resolvedDiscussionsCount,
          resolvableDiscussionsCount,
        });

        expect(findButton().attributes('title')).toBe(tooltip);
      },
    );
  });

  describe('when neutral', () => {
    beforeEach(() => {
      createComponent(
        { resolvedDiscussionsCount: 1, resolvableDiscussionsCount: 2 },
        { neutral: true },
      );
    });

    it('does not render the badge', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('renders a subtle comments icon and the count', () => {
      expect(findIcon().props('name')).toBe('comments');
      expect(findIcon().props('variant')).toBe('subtle');
      expect(wrapper.text()).toBe('1 of 2');
    });

    it('keeps the tooltip', () => {
      expect(findButton().attributes('title')).toBe('1 of 2 threads resolved');
    });
  });

  describe('when neutral and all discussions are resolved', () => {
    beforeEach(() => {
      createComponent(
        { resolvedDiscussionsCount: 4, resolvableDiscussionsCount: 4 },
        { neutral: true },
      );
    });

    it('shows the count rather than the Resolved label', () => {
      expect(wrapper.text()).toBe('4 of 4');
    });
  });
});
