import { mount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import DiscussionsBadge from '~/merge_requests/list/components/discussions_badge.vue';

describe('Merge requests list discussions badge component', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  function createComponent(mergeRequest = {}) {
    wrapper = mount(DiscussionsBadge, {
      propsData: {
        mergeRequest,
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
      expect(findBadge().attributes('title')).toBe('The only thread is resolved');
    });
  });

  describe('when not all discussions resolved', () => {
    it('renders badge as success variant', () => {
      createComponent({
        resolvedDiscussionsCount: 0,
        resolvableDiscussionsCount: 2,
      });

      expect(findBadge().props('variant')).toBe('muted');
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

        expect(findBadge().attributes('title')).toBe(tooltip);
      },
    );
  });
});
