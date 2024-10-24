import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FindingsDrawerDetails from '~/diffs/components/shared/findings_drawer_details.vue';
import {
  mockFindingDetected,
  mockFindingsMultiple,
  mockProject,
} from '../../mock_data/findings_drawer';

describe('Findings Drawer Details', () => {
  let wrapper;

  const findingDetailsProps = {
    drawer: mockFindingDetected,
    project: mockProject,
  };

  const createWrapper = (findingDetailsOverrides = {}) => {
    const propsData = {
      drawer: findingDetailsProps.drawer,
      project: findingDetailsProps.project,
      ...findingDetailsOverrides,
    };

    wrapper = shallowMountExtended(FindingsDrawerDetails, {
      propsData,
    });
  };

  const findTitle = () => wrapper.findByTestId('findings-drawer-title');

  describe('General Rendering', () => {
    it('renders without errors', () => {
      createWrapper();
      expect(wrapper.exists()).toBe(true);
    });

    it('matches the snapshot with dismissed badge', () => {
      createWrapper();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('matches the snapshot with detected badge', () => {
      createWrapper();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('Active Index Handling', () => {
    it('watcher sets active index on drawer prop change', () => {
      createWrapper({ drawer: mockFindingsMultiple[2] });
      expect(findTitle().props().value).toBe(mockFindingsMultiple[2].title);
    });
  });
});
