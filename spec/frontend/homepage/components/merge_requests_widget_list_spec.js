import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import MergeRequestsWidgetList from '~/homepage/components/merge_requests_widget_list.vue';
import MergeRequestItem from '~/homepage/components/merge_request_item.vue';
import { buildMergeRequests } from './mocks/merge_requests_widget_query_mocks';

describe('MergeRequestsWidgetList', () => {
  let wrapper;

  const findItems = () => wrapper.findAllComponents(MergeRequestItem);
  const findToggle = () => wrapper.findComponent(GlButton);
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findDashboardLink = () => wrapper.find('a');

  const createComponent = ({ mergeRequests = buildMergeRequests(2) } = {}) => {
    wrapper = shallowMountExtended(MergeRequestsWidgetList, {
      propsData: {
        mergeRequests,
        emptyText: 'No merge requests assigned to you.',
        trackingProperty: 'Assigned to you',
      },
    });
  };

  describe('when there are merge requests', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders one item per merge request', () => {
      expect(findItems()).toHaveLength(2);
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('links to the merge requests dashboard', () => {
      expect(findDashboardLink().attributes('href')).toBe('/dashboard/merge_requests');
    });
  });

  describe('when there are no merge requests', () => {
    beforeEach(() => {
      createComponent({ mergeRequests: [] });
    });

    it('renders the empty text', () => {
      expect(findEmptyState().text()).toBe('No merge requests assigned to you.');
    });

    it('renders no items', () => {
      expect(findItems()).toHaveLength(0);
    });

    it('still links to the merge requests dashboard', () => {
      expect(findDashboardLink().exists()).toBe(true);
    });
  });

  describe('when there are 4 or fewer merge requests', () => {
    beforeEach(() => {
      createComponent({ mergeRequests: buildMergeRequests(4) });
    });

    it('renders all of them', () => {
      expect(findItems()).toHaveLength(4);
    });

    it('does not render the show more toggle', () => {
      expect(findToggle().exists()).toBe(false);
    });
  });

  describe('when there are more than 4 merge requests', () => {
    beforeEach(() => {
      createComponent({ mergeRequests: buildMergeRequests(8) });
    });

    it('renders only the first 4', () => {
      expect(findItems()).toHaveLength(4);
    });

    it('renders a show more toggle', () => {
      expect(findToggle().text()).toBe('Show more');
    });

    describe('when the toggle is clicked', () => {
      beforeEach(() => {
        findToggle().vm.$emit('click');
      });

      it('reveals the remaining merge requests', () => {
        expect(findItems()).toHaveLength(8);
      });

      it('changes the toggle to show less', () => {
        expect(findToggle().text()).toBe('Show less');
      });

      describe('when the toggle is clicked again', () => {
        beforeEach(() => {
          findToggle().vm.$emit('click');
        });

        it('collapses back to 4', () => {
          expect(findItems()).toHaveLength(4);
        });
      });
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks a row click with the tab property', () => {
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findItems().at(0).vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'user_follows_link_on_homepage',
        { label: 'Merge requests widget', property: 'Assigned to you' },
        undefined,
      );
    });

    it('tracks a click on the dashboard link', () => {
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findDashboardLink().element.addEventListener('click', (e) => e.preventDefault(), {
        once: true,
      });

      findDashboardLink().trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'user_follows_link_on_homepage',
        { label: 'Merge requests widget', property: 'All merge requests' },
        undefined,
      );
    });
  });
});
