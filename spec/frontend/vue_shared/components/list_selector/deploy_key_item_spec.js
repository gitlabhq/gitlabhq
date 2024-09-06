import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeployKeyItem from '~/vue_shared/components/list_selector/deploy_key_item.vue';

describe('DeployKeyItem spec', () => {
  let wrapper;

  const MOCK_DATA = { title: 'Some key', user: { name: 'root' }, id: '123' };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(DeployKeyItem, {
      propsData: {
        data: MOCK_DATA,
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findDeleteButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => createComponent());

  it('renders a key icon component', () => {
    expect(findIcon().props('name')).toBe('key');
  });

  it('renders a title and username', () => {
    expect(wrapper.text()).toContain('Some key');
    expect(wrapper.text()).toContain('@root');
  });

  it('does not render a delete button by default', () => {
    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('Delete button', () => {
    beforeEach(() => createComponent({ canDelete: true }));

    it('renders a delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
      expect(findDeleteButton().props('icon')).toBe('remove');
    });

    it('emits a delete event if the delete button is clicked', () => {
      const stopPropagation = jest.fn();

      findDeleteButton().vm.$emit('click', { stopPropagation });

      expect(stopPropagation).toHaveBeenCalled();
      expect(wrapper.emitted('delete')).toEqual([[MOCK_DATA.id]]);
    });
  });
});
