import { GlAvatar } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
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
    wrapper = mountExtended(ProjectItem, {
      propsData: {
        data: MOCK_PROJECT,
        ...props,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findDeleteButton = () => wrapper.findByRole('button', { fullName: 'Delete Group 1' });

  beforeEach(() => createComponent());

  it('renders an Avatar component', () => {
    expect(findAvatar().props('size')).toBe(32);
    expect(findAvatar().attributes()).toMatchObject({
      src: MOCK_PROJECT.avatarUrl,
      alt: MOCK_PROJECT.name,
    });
  });

  it('renders a name and namespace', () => {
    expect(wrapper.text()).toContain(MOCK_PROJECT.name);
    expect(wrapper.text()).toContain(MOCK_PROJECT.nameWithNamespace);
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
      findDeleteButton().trigger('click');

      expect(wrapper.emitted('delete')).toEqual([[MOCK_PROJECT.id]]);
    });
  });
});
