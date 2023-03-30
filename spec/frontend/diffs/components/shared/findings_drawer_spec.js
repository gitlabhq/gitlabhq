import FindingsDrawer from '~/diffs/components/shared/findings_drawer.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import mockFinding from '../../mock_data/findings_drawer';

let wrapper;
describe('FindingsDrawer', () => {
  const createWrapper = () => {
    return shallowMountExtended(FindingsDrawer, {
      propsData: {
        drawer: mockFinding,
      },
    });
  };

  it('matches the snapshot', () => {
    wrapper = createWrapper();
    expect(wrapper.element).toMatchSnapshot();
  });
});
