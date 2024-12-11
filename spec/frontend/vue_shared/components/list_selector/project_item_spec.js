import { GlAvatarLabeled, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectItem from '~/vue_shared/components/list_selector/project_item.vue';

describe('GroupItem spec', () => {
  let wrapper;

  const MOCK_PROJECT = {
    name: 'Project 1',
    avatarUrl: 'some/avatar.jpg',
    id: 1,
    nameWithNamespace: 'Group 1 / Project 1',
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(ProjectItem, {
      propsData: {
        data: MOCK_PROJECT,
        ...props,
      },
      stubs: {
        GlAvatarLabeled,
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findDeleteButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => createComponent());

  it('renders AvatarLabeled component', () => {
    expect(findAvatarLabeled().props()).toMatchObject({
      label: 'Project 1',
      subLabel: 'Group 1 / Project 1',
    });
    expect(findAvatarLabeled().attributes()).toMatchObject({
      size: '32',
      src: 'some/avatar.jpg',
    });
  });

  it('does not render a delete button by default', () => {
    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('Delete button', () => {
    beforeEach(() => createComponent({ canDelete: true }));

    it('renders a delete button', () => {
      expect(findDeleteButton().props('icon')).toBe('remove');
    });

    it('emits a delete event if the delete button is clicked', () => {
      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')).toEqual([[MOCK_PROJECT.id]]);
    });
  });
});
