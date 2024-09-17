import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemRolledUpCountInfo from '~/work_items/components/work_item_links/work_item_rolled_up_count_info.vue';
import { mockRolledUpCountsByType } from 'jest/work_items/mock_data';

describe('Work item rolled up count info', () => {
  let wrapper;

  const createComponent = ({ filteredRollUpCountsByType = mockRolledUpCountsByType } = {}) => {
    wrapper = shallowMountExtended(WorkItemRolledUpCountInfo, {
      propsData: {
        filteredRollUpCountsByType,
      },
    });
  };

  const findRolledUpCountInfo = () => wrapper.findByTestId('rolled-up-count-info');
  const findCountInfo = () => wrapper.findAllByTestId('rolled-up-type-info');

  it('renders the info in detail', () => {
    createComponent();

    expect(findRolledUpCountInfo().exists()).toBe(true);
  });

  it('does not render the info if there are no counts', () => {
    createComponent({ filteredRollUpCountsByType: [] });

    expect(findRolledUpCountInfo().exists()).toBe(false);
  });

  it('renders the correct number of counts', () => {
    createComponent();

    expect(findCountInfo().length).toBe(mockRolledUpCountsByType.length);
  });
});
