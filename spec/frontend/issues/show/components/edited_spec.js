import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { getTimeago } from '~/lib/utils/datetime_utility';
import Edited from '~/issues/show/components/edited.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Edited component', () => {
  let wrapper;

  const timeago = getTimeago();
  const updatedAt = '2017-05-15T12:31:04.428Z';

  const findAuthorLink = () => wrapper.findComponent(GlLink);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const formatText = (text) => text.trim().replace(/\s\s+/g, ' ');

  const mountComponent = (propsData) => mount(Edited, { propsData });

  describe('task status section', () => {
    describe('task status text', () => {
      describe('when there is completion_count', () => {
        it('renders when there is a task status', () => {
          wrapper = mountComponent({ taskCompletionStatus: { completed_count: 1, count: 3 } });

          expect(wrapper.text()).toContain('1 of 3 checklist items completed');
        });

        it('does not render when task count is 0', () => {
          wrapper = mountComponent({ taskCompletionStatus: { completed_count: 0, count: 0 } });

          expect(wrapper.text()).not.toContain('0 of 0 checklist items completed');
        });

        it('renders "0 of x" when there is a task status and no items were checked yet', () => {
          wrapper = mountComponent({ taskCompletionStatus: { completed_count: 0, count: 3 } });

          expect(wrapper.text()).toContain('0 of 3 checklist items completed');
        });
      });

      describe('when there is completionCount', () => {
        it('renders when there is a task status', () => {
          wrapper = mountComponent({ taskCompletionStatus: { completedCount: 1, count: 3 } });

          expect(wrapper.text()).toContain('1 of 3 checklist items completed');
        });

        it('does not render when task count is 0', () => {
          wrapper = mountComponent({ taskCompletionStatus: { completedCount: 0, count: 0 } });

          expect(wrapper.text()).not.toContain('0 of 0 checklist items completed');
        });

        it('renders "0 of x" when there is a task status and no items were checked yet', () => {
          wrapper = mountComponent({ taskCompletionStatus: { completedCount: 0, count: 3 } });

          expect(wrapper.text()).toContain('0 of 3 checklist items completed');
        });
      });
    });

    describe('checkmark', () => {
      it('renders when all tasks are completed', () => {
        wrapper = mountComponent({ taskCompletionStatus: { completed_count: 3, count: 3 } });

        expect(wrapper.text()).toContain('✓');
      });

      it('does not render when tasks are incomplete', () => {
        wrapper = mountComponent({ taskCompletionStatus: { completed_count: 2, count: 3 } });

        expect(wrapper.text()).not.toContain('✓');
      });

      it('does not render when task count is 0', () => {
        wrapper = mountComponent({ taskCompletionStatus: { completed_count: 0, count: 0 } });

        expect(wrapper.text()).not.toContain('✓');
      });
    });

    describe('middot', () => {
      it('renders when there is also "Edited by" text', () => {
        wrapper = mountComponent({
          taskCompletionStatus: { completed_count: 3, count: 3 },
          updatedAt,
        });

        expect(wrapper.text()).toContain('·');
      });

      it('does not render when there is no "Edited by" text', () => {
        wrapper = mountComponent({ taskCompletionStatus: { completed_count: 3, count: 3 } });

        expect(wrapper.text()).not.toContain('·');
      });
    });
  });

  it('renders an edited at+by string', () => {
    wrapper = mountComponent({
      updatedAt,
      updatedByName: 'Some User',
      updatedByPath: '/some_user',
    });

    expect(formatText(wrapper.text())).toBe(`Edited ${timeago.format(updatedAt)} by Some User`);
    expect(findAuthorLink().attributes('href')).toBe('/some_user');
    expect(findTimeAgoTooltip().exists()).toBe(true);
  });

  it('if no updatedByName and updatedByPath is provided, no user element will be rendered', () => {
    wrapper = mountComponent({
      updatedAt,
    });

    expect(formatText(wrapper.text())).toBe(`Edited ${timeago.format(updatedAt)}`);
    expect(findAuthorLink().exists()).toBe(false);
    expect(findTimeAgoTooltip().exists()).toBe(true);
  });
});
