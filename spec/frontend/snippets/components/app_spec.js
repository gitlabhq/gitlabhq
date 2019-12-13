import SnippetApp from '~/snippets/components/app.vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';

describe('Snippet view app', () => {
  let wrapper;
  let snippetDataMock;
  const localVue = createLocalVue();
  const defaultProps = {
    snippetGid: 'gid://gitlab/PersonalSnippet/35',
  };

  function createComponent({ props = defaultProps, snippetData = {} } = {}) {
    snippetDataMock = jest.fn();
    const $apollo = {
      queries: {
        snippetData: snippetDataMock,
      },
    };

    wrapper = shallowMount(SnippetApp, {
      sync: false,
      mocks: { $apollo },
      localVue,
      propsData: {
        ...props,
      },
    });

    wrapper.setData({
      snippetData,
    });
  }
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders itself', () => {
    createComponent();
    expect(wrapper.find('.js-snippet-view').exists()).toBe(true);
  });
});
