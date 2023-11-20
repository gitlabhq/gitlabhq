import { GlDrawer } from '@gitlab/ui';
import FindingsDrawer from '~/diffs/components/shared/findings_drawer.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockFindingDismissed,
  mockFindingDetected,
  mockProject,
} from '../../mock_data/findings_drawer';

let wrapper;
const getDrawer = () => wrapper.findComponent(GlDrawer);
const closeEvent = 'close';

const createWrapper = (finding = mockFindingDismissed) => {
  return mountExtended(FindingsDrawer, {
    propsData: {
      drawer: finding,
      project: mockProject,
    },
  });
};

describe('FindingsDrawer', () => {
  it('renders without errors', () => {
    wrapper = createWrapper();
    expect(wrapper.exists()).toBe(true);
  });

  it('emits close event when gl-drawer emits close event', () => {
    wrapper = createWrapper();

    getDrawer().vm.$emit(closeEvent);
    expect(wrapper.emitted(closeEvent)).toHaveLength(1);
  });

  it('matches the snapshot with dismissed badge', () => {
    wrapper = createWrapper();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('matches the snapshot with detected badge', () => {
    wrapper = createWrapper(mockFindingDetected);
    expect(wrapper.element).toMatchSnapshot();
  });
});
