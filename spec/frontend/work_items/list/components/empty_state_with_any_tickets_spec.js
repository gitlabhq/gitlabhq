import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-service-desk-md.svg';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyStateWithAnyTickets from '~/work_items/list/components/empty_state_with_any_tickets.vue';

describe('EmptyStateWithAnyTickets component', () => {
  let wrapper;

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = (props = {}) => {
    wrapper = shallowMount(EmptyStateWithAnyTickets, {
      propsData: {
        hasSearch: true,
        isOpenTab: true,
        ...props,
      },
    });
  };

  describe('when there is a search (with no results)', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description: 'To widen your search, change or remove filters above',
        title: 'Sorry, your filter produced no results',
        svgPath: emptyStateSvg,
      });
    });
  });

  describe('when "Open" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        description:
          'Tickets created from Service Desk emails will appear here. Each comment becomes part of the email conversation.',
        title: 'There are no open issues',
        svgPath: emptyStateSvg,
      });
    });
  });

  describe('when "Closed" tab is active', () => {
    beforeEach(() => {
      mountComponent({ hasSearch: false, isClosedTab: true, isOpenTab: false });
    });

    it('shows empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: 'There are no closed issues',
        svgPath: emptyStateSvg,
      });
    });
  });
});
