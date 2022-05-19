import { GlDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';

describe('WorkItemActions component', () => {
  let wrapper;
  let glModalDirective;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findComponent(GlDropdownItem);

  const createComponent = ({ canDelete = true } = {}) => {
    glModalDirective = jest.fn();
    wrapper = shallowMount(WorkItemActions, {
      propsData: { workItemId: '123', canDelete },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders modal', () => {
    createComponent();

    expect(findModal().exists()).toBe(true);
    expect(findModal().props('visible')).toBe(false);
  });

  it('shows confirm modal when clicking Delete work item', () => {
    createComponent();

    findDeleteButton().vm.$emit('click');

    expect(glModalDirective).toHaveBeenCalled();
  });

  it('emits event when clicking OK button', () => {
    createComponent();

    findModal().vm.$emit('ok');

    expect(wrapper.emitted('deleteWorkItem')).toEqual([[]]);
  });

  it('does not render when canDelete is false', () => {
    createComponent({
      canDelete: false,
    });

    expect(wrapper.html()).toBe('');
  });
});
