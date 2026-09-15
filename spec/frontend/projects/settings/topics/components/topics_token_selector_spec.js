import { GlAvatarLabeled, GlTokenSelector, GlToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TopicsTokenSelector from '~/projects/settings/topics/components/topics_token_selector.vue';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

Vue.use(VueApollo);

const mockTopics = [
  {
    __typename: 'Topic',
    id: 'gid://gitlab/Projects::Topic/1',
    name: 'topic1',
    title: 'Topic 1',
    avatarUrl: 'avatar.com/topic1.png',
  },
  {
    __typename: 'Topic',
    id: 'gid://gitlab/Projects::Topic/2',
    name: 'GitLab',
    title: 'GitLab',
    avatarUrl: 'avatar.com/GitLab.png',
  },
];

const USER_DEFINED_TOKEN = 'user defined token';

describe('TopicsTokenSelector', () => {
  let wrapper;
  let div;
  let input;

  const createComponent = async ({ selected, topics = mockTopics } = {}) => {
    const searchTopicsHandler = jest.fn().mockResolvedValue({
      data: { topics: { __typename: 'TopicConnection', nodes: topics } },
    });

    wrapper = mount(TopicsTokenSelector, {
      attachTo: div,
      apolloProvider: createMockApollo([[searchProjectTopics, searchTopicsHandler]]),
      propsData: {
        organizationId: '1',
        selected,
      },
    });

    // The `topics` query is debounced, so the timers need advancing before it fires.
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

    await waitForPromises();
  };

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  const findTokenSelectorInput = () => findTokenSelector().find('input[type="text"]');

  const findAllAvatars = () => wrapper.findAllComponents(GlAvatarLabeled).wrappers;

  const findSelectedTokensText = () =>
    wrapper.findAllComponents(GlToken).wrappers.map((w) => w.text());

  const setTokenSelectorInputValue = async (value) => {
    const tokenSelectorInput = findTokenSelectorInput();

    tokenSelectorInput.element.value = value;
    await tokenSelectorInput.trigger('input');
    await waitForPromises();
  };

  const tokenSelectorTriggerEnter = async (event) => {
    const tokenSelectorInput = findTokenSelectorInput();
    await tokenSelectorInput.trigger('keydown.enter', event);
    await waitForPromises();
  };

  beforeEach(() => {
    div = document.createElement('div');
    input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.id = 'project_topic_list_field';
    document.body.appendChild(div);
    document.body.appendChild(input);
  });

  afterEach(() => {
    div.remove();
    input.remove();
  });

  describe('accessibility', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders a label in the form group', () => {
      expect(wrapper.find('label').attributes('for')).toBe('project_topics_input');
    });

    it('passes text-input-attrs with correct id to the token selector', () => {
      expect(findTokenSelector().props('textInputAttrs')).toMatchObject({
        id: 'project_topics_input',
      });
    });
  });

  describe('when component is mounted', () => {
    it('parses selected into tokens', async () => {
      // Unlike `mockTopics`, which comes from the GraphQL query and so uses GIDs, `selected` is
      // built from the hidden input in `topics/index.js` and uses the array index as the id.
      const selected = [
        { id: 0, name: 'topic1' },
        { id: 1, name: 'topic2' },
        { id: 2, name: 'topic3' },
      ];
      await createComponent({ selected });
      await nextTick();

      wrapper.findAllComponents(GlToken).wrappers.forEach((tokenWrapper, index) => {
        expect(tokenWrapper.text()).toBe(selected[index].name);
      });
    });

    it('passes topic title to the avatar', async () => {
      await createComponent();

      const avatars = findAllAvatars();

      expect(avatars).toHaveLength(mockTopics.length);
    });

    it('syncs internal state when selected prop changes', async () => {
      const initialSelected = [{ id: 11, name: 'topic1' }];
      createComponent({ selected: initialSelected });

      expect(findSelectedTokensText()).toStrictEqual(['topic1']);

      const newSelected = [
        { id: 11, name: 'topic1' },
        { id: 12, name: 'topic2' },
      ];
      await wrapper.setProps({ selected: newSelected });

      expect(findSelectedTokensText()).toStrictEqual(['topic1', 'topic2']);
    });
  });

  describe('when enter key is pressed', () => {
    it('does not submit the form if token selector text input has a value', async () => {
      await createComponent();

      await setTokenSelectorInputValue('topic');

      const event = { preventDefault: jest.fn() };
      tokenSelectorTriggerEnter(event);

      expect(event.preventDefault).toHaveBeenCalled();
    });
  });

  describe('when tokens are added', () => {
    it('properly updates selectedTokens and emits `update` with existing token', async () => {
      await createComponent();

      await setTokenSelectorInputValue(mockTopics[0].name);
      await tokenSelectorTriggerEnter();

      expect(findSelectedTokensText()).toStrictEqual([mockTopics[0].name]);
      expect(wrapper.emitted('update')[0][0]).toStrictEqual([mockTopics[0]]);
    });

    it('properly updates selectedTokens and emits `update` with user defined token', async () => {
      await createComponent({ topics: [] });

      await setTokenSelectorInputValue(USER_DEFINED_TOKEN);
      await tokenSelectorTriggerEnter();

      expect(findSelectedTokensText()).toStrictEqual([USER_DEFINED_TOKEN]);
      expect(wrapper.emitted('update')[0][0]).toStrictEqual([
        expect.objectContaining({ name: USER_DEFINED_TOKEN }),
      ]);
    });

    it('properly omits duplicate tokens, updates selectedTokens, and emits `update`', async () => {
      await createComponent({ selected: mockTopics });

      await setTokenSelectorInputValue(USER_DEFINED_TOKEN);
      await tokenSelectorTriggerEnter();

      expect(findSelectedTokensText()).toStrictEqual([
        mockTopics[0].name,
        mockTopics[1].name,
        USER_DEFINED_TOKEN,
      ]);
      expect(wrapper.emitted('update')[0][0]).toStrictEqual([
        ...mockTopics,
        expect.objectContaining({ name: USER_DEFINED_TOKEN }),
      ]);

      await setTokenSelectorInputValue(USER_DEFINED_TOKEN);
      await tokenSelectorTriggerEnter();

      expect(findSelectedTokensText()).toStrictEqual([
        mockTopics[0].name,
        mockTopics[1].name,
        USER_DEFINED_TOKEN,
      ]);
      expect(wrapper.emitted('update')[0][0]).toStrictEqual([
        ...mockTopics,
        expect.objectContaining({ name: USER_DEFINED_TOKEN }),
      ]);
    });

    it('filters selected tokens out of the dropdown without refetching', async () => {
      await createComponent({ selected: [{ id: 11, name: mockTopics[0].name }] });

      expect(findTokenSelector().props('dropdownItems')).toStrictEqual([mockTopics[1]]);

      await setTokenSelectorInputValue(mockTopics[1].name);
      await tokenSelectorTriggerEnter();

      expect(findTokenSelector().props('dropdownItems')).toStrictEqual([]);
    });
  });
});
