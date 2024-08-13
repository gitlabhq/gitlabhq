import { GlAvatarLabeled, GlCollapsibleListbox, GlListboxItem, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import TopicSelect from '~/admin/topics/components/topic_select.vue';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

const mockTopics = [
  {
    id: 'gid://gitlab/Projects::Topic/6',
    name: 'topic1',
    title: 'Topic 1',
    avatarUrl: 'avatar.com/topic1.png',
    __typename: 'Topic',
  },
  {
    id: 'gid://gitlab/Projects::Topic/5',
    name: 'gitlab',
    title: 'GitLab',
    avatarUrl: 'avatar.com/GitLab.png',
    __typename: 'Topic',
  },
];

const mockTopicsQueryResponse = {
  data: {
    topics: {
      nodes: mockTopics,
      __typename: 'TopicConnection',
    },
  },
};

describe('TopicSelect', () => {
  let wrapper;
  const mockSearchTopicsSuccess = jest.fn().mockResolvedValue(mockTopicsQueryResponse);

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);

  function createMockApolloProvider({ mockSearchTopicsQuery = mockSearchTopicsSuccess } = {}) {
    Vue.use(VueApollo);

    return createMockApollo([[searchProjectTopics, mockSearchTopicsQuery]]);
  }

  function createComponent({ props = {}, mockApollo } = {}) {
    wrapper = mount(TopicSelect, {
      apolloProvider: mockApollo || createMockApolloProvider(),
      propsData: props,
      data() {
        return {
          topics: mockTopics,
        };
      },
    });
  }

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

    expect(findListbox().props('toggleText')).toBe('Select a topic');
  });

  it('renders selected topic', () => {
    const mockTopic = mockTopics[0];

    createComponent({
      props: {
        selectedTopic: mockTopic,
      },
    });

    expect(findListbox().props('toggleText')).toBe(mockTopic.name);
  });

  it('renders label', () => {
    const labelText = 'my label';

    createComponent({
      props: {
        labelText,
      },
    });

    expect(wrapper.findComponent(GlFormGroup).text()).toContain(labelText);
  });

  it('renders dropdown items', () => {
    createComponent();

    const listboxItems = findAllListboxItems();

    expect(listboxItems.at(0).findComponent(GlAvatarLabeled).props('label')).toBe('Topic 1');
    expect(listboxItems.at(1).findComponent(GlAvatarLabeled).props('label')).toBe('GitLab');
  });

  it('dropdown `toggledAriaLabelledBy` prop is not set if `labelText` prop is null', () => {
    createComponent();

    expect(findListbox().props('toggle-aria-labelled-by')).toBe(undefined);
  });

  it('emits `click` event when topic selected', async () => {
    createComponent();

    await findAllListboxItems().at(0).trigger('click');

    expect(wrapper.emitted('click')).toEqual([[mockTopics[0]]]);
  });

  describe('when searching a topic', () => {
    const searchTopic = (searchTerm) => findListbox().vm.$emit('search', searchTerm);
    const mockSearchTerm = 'gitl';

    it('toggles loading state', async () => {
      createComponent();
      jest.runOnlyPendingTimers();

      await searchTopic(mockSearchTerm);

      expect(findListbox().props('searching')).toBe(true);

      await waitForPromises();

      expect(findListbox().props('searching')).toBe(false);
    });

    it('fetches topics matching search string', async () => {
      createComponent();

      await searchTopic(mockSearchTerm);
      jest.runOnlyPendingTimers();

      expect(mockSearchTopicsSuccess).toHaveBeenCalledWith({
        search: mockSearchTerm,
      });
    });
  });
});
