import { mount } from '@vue/test-utils';
import noSavedRepliesResponse from 'test_fixtures/graphql/saved_replies/saved_replies_empty.query.graphql.json';
import savedRepliesResponse from 'test_fixtures/graphql/saved_replies/saved_replies.query.graphql.json';
import List from '~/saved_replies/components/list.vue';
import ListItem from '~/saved_replies/components/list_item.vue';

let wrapper;

function createComponent(res = {}) {
  const { savedReplies } = res.data.currentUser;

  return mount(List, {
    propsData: {
      savedReplies: savedReplies.nodes,
      pageInfo: savedReplies.pageInfo,
      count: savedReplies.count,
    },
  });
}

describe('Saved replies list component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('does not render any list items when response is empty', () => {
    wrapper = createComponent(noSavedRepliesResponse);

    expect(wrapper.findAllComponents(ListItem).length).toBe(0);
  });

  it('render saved replies count', () => {
    wrapper = createComponent(savedRepliesResponse);

    expect(wrapper.find('[data-testid="title"]').text()).toEqual('My saved replies (2)');
  });

  it('renders list of saved replies', () => {
    const savedReplies = savedRepliesResponse.data.currentUser.savedReplies.nodes;
    wrapper = createComponent(savedRepliesResponse);

    expect(wrapper.findAllComponents(ListItem).length).toBe(2);
    expect(wrapper.findAllComponents(ListItem).at(0).props('reply')).toEqual(
      expect.objectContaining(savedReplies[0]),
    );
    expect(wrapper.findAllComponents(ListItem).at(1).props('reply')).toEqual(
      expect.objectContaining(savedReplies[1]),
    );
  });
});
