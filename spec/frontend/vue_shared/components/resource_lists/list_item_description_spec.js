import { GlTruncateText } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';

describe('ListItemDescription', () => {
  let wrapper;

  const defaultPropsData = {
    descriptionHtml: '<p>Dolorem dolorem omnis impedit cupiditate pariatur officia velit.</p>',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ListItemDescription, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  it('renders description', () => {
    createComponent();

    expect(wrapper.findComponent(GlTruncateText).element.firstChild.innerHTML).toBe(
      defaultPropsData.descriptionHtml,
    );
  });
});
