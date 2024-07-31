import { GlAvatarLabeled, GlTokenSelector, GlToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TopicsTokenSelector from '~/projects/settings/topics/components/topics_token_selector.vue';

const mockTopics = [
  { id: 1, name: 'topic1', title: 'Topic 1', avatarUrl: 'avatar.com/topic1.png' },
  { id: 2, name: 'GitLab', title: 'GitLab', avatarUrl: 'avatar.com/GitLab.png' },
];

const USER_DEFINED_TOKEN = 'user defined token';

describe('TopicsTokenSelector', () => {
  let wrapper;
  let div;
  let input;

  const createComponent = ({ selected, topics = mockTopics } = {}) => {
    wrapper = mount(TopicsTokenSelector, {
      attachTo: div,
      propsData: {
        selected,
      },
      data() {
        return {
          topics,
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
  };

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  const findTokenSelectorInput = () => findTokenSelector().find('input[type="text"]');

  const findAllAvatars = () => wrapper.findAllComponents(GlAvatarLabeled).wrappers;

  const findSelectedTokensText = () =>
    wrapper.findAllComponents(GlToken).wrappers.map((w) => w.text());

  const setTokenSelectorInputValue = (value) => {
    const tokenSelectorInput = findTokenSelectorInput();

    tokenSelectorInput.element.value = value;
    tokenSelectorInput.trigger('input');

    return nextTick();
  };

  const tokenSelectorTriggerEnter = (event) => {
    const tokenSelectorInput = findTokenSelectorInput();
    tokenSelectorInput.trigger('keydown.enter', event);
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

  describe('when component is mounted', () => {
    it('parses selected into tokens', async () => {
      const selected = [
        { id: 11, name: 'topic1' },
        { id: 12, name: 'topic2' },
        { id: 13, name: 'topic3' },
      ];
      createComponent({ selected });
      await nextTick();

      wrapper.findAllComponents(GlToken).wrappers.forEach((tokenWrapper, index) => {
        expect(tokenWrapper.text()).toBe(selected[index].name);
      });
    });

    it('passes topic title to the avatar', () => {
      createComponent();
      const avatars = findAllAvatars();

      mockTopics.map((topic, index) => expect(avatars[index].text()).toBe(topic.title));
    });
  });

  describe('when enter key is pressed', () => {
    it('does not submit the form if token selector text input has a value', async () => {
      createComponent();

      await setTokenSelectorInputValue('topic');

      const event = { preventDefault: jest.fn() };
      tokenSelectorTriggerEnter(event);

      expect(event.preventDefault).toHaveBeenCalled();
    });
  });

  describe('when tokens are added', () => {
    it('properly updates selectedTokens and emits `update` with existing token', async () => {
      createComponent();

      await setTokenSelectorInputValue(mockTopics[0].name);
      await tokenSelectorTriggerEnter();

      expect(findSelectedTokensText()).toStrictEqual([mockTopics[0].name]);
      expect(wrapper.emitted('update')[0][0]).toStrictEqual([mockTopics[0]]);
    });

    it('properly updates selectedTokens and emits `update` with user defined token', async () => {
      createComponent({ topics: [] });

      await setTokenSelectorInputValue(USER_DEFINED_TOKEN);
      await tokenSelectorTriggerEnter();

      expect(findSelectedTokensText()).toStrictEqual([USER_DEFINED_TOKEN]);
      expect(wrapper.emitted('update')[0][0]).toStrictEqual([
        expect.objectContaining({ name: USER_DEFINED_TOKEN }),
      ]);
    });

    it('properly omits duplicate tokens, updates selectedTokens, and emits `update`', async () => {
      createComponent({ selected: mockTopics });

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
  });
});
