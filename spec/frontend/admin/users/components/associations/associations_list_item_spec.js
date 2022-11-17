import { mountExtended } from 'helpers/vue_test_utils_helper';
import AssociationsListItem from '~/admin/users/components/associations/associations_list_item.vue';
import { n__ } from '~/locale';

describe('AssociationsListItem', () => {
  let wrapper;
  const count = 5;

  const createComponent = () => {
    wrapper = mountExtended(AssociationsListItem, {
      propsData: {
        message: n__('%{count} group', '%{count} groups', count),
        count,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders interpolated message in a `li` element', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });
});
