import { GlAvatarLabeled, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TopicSelect from '~/admin/topics/components/topic_select.vue';

const mockTopics = [
  { id: 1, name: 'topic1', title: 'Topic 1', avatarUrl: 'avatar.com/topic1.png' },
  { id: 2, name: 'GitLab', title: 'GitLab', avatarUrl: 'avatar.com/GitLab.png' },
];

describe('TopicSelect', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  function createComponent(props = {}) {
    wrapper = shallowMount(TopicSelect, {
      propsData: props,
      data() {
        return {
          topics: mockTopics,
          search: '',
        };
      },
      mocks: {
        $apollo: {
          queries: {
            topics: { loading: false },
          },
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('mounts', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });

  it('`selectedTopic` prop defaults to `{}`', () => {
    createComponent();

    expect(wrapper.props('selectedTopic')).toEqual({});
  });

  it('`labelText` prop defaults to `null`', () => {
    createComponent();

    expect(wrapper.props('labelText')).toBe(null);
  });

  it('renders default text if no selected topic', () => {
    createComponent();

    expect(findDropdown().props('text')).toBe('Select a topic');
  });

  it('renders selected topic', () => {
    createComponent({ selectedTopic: mockTopics[0] });

    expect(findDropdown().props('text')).toBe('topic1');
  });

  it('renders label', () => {
    createComponent({ labelText: 'my label' });

    expect(wrapper.find('label').text()).toBe('my label');
  });

  it('renders dropdown items', () => {
    createComponent();

    const dropdownItems = findAllDropdownItems();

    expect(dropdownItems.at(0).findComponent(GlAvatarLabeled).props('label')).toBe('Topic 1');
    expect(dropdownItems.at(1).findComponent(GlAvatarLabeled).props('label')).toBe('GitLab');
  });

  it('emits `click` event when topic selected', () => {
    createComponent();

    findAllDropdownItems().at(0).vm.$emit('click');

    expect(wrapper.emitted('click')).toEqual([[mockTopics[0]]]);
  });
});
