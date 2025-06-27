import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsWidget from '~/homepage/components/work_items_widget.vue';

describe('WorkItemsWidget', () => {
  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';
  const MOCK_AUTHORED_BY_YOU_PATH = '/authored/to/you/path';

  let wrapper;

  const findGlLinks = () => wrapper.findAllComponents(GlLink);

  function createWrapper() {
    wrapper = shallowMountExtended(WorkItemsWidget, {
      propsData: {
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
        authoredByYouPath: MOCK_AUTHORED_BY_YOU_PATH,
      },
    });
  }

  describe('links', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the "Assigned to you" link', () => {
      const link = findGlLinks().at(0);

      expect(link.props('href')).toBe(MOCK_ASSIGNED_TO_YOU_PATH);
      expect(link.text()).toBe('Assigned to you');
    });

    it('renders the "Authored by you" link', () => {
      const link = findGlLinks().at(1);

      expect(link.props('href')).toBe(MOCK_AUTHORED_BY_YOU_PATH);
      expect(link.text()).toBe('Authored by you');
    });
  });
});
