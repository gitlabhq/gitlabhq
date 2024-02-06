import { mount } from '@vue/test-utils';
import noSavedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies_empty.query.graphql.json';
import savedRepliesResponse from 'test_fixtures/graphql/comment_templates/saved_replies.query.graphql.json';
import List from '~/comment_templates/components/list.vue';
import ListItem from '~/comment_templates/components/list_item.vue';
import deleteSavedReplyMutation from '~/pages/profiles/comment_templates/queries/delete_saved_reply.mutation.graphql';

let wrapper;

function createComponent(res = {}) {
  const { savedReplies } = res.data.object;

  return mount(List, {
    provide: {
      deleteMutation: deleteSavedReplyMutation,
    },
    propsData: {
      savedReplies: savedReplies.nodes,
      pageInfo: savedReplies.pageInfo,
      count: savedReplies.count,
    },
  });
}

describe('Comment templates list component', () => {
  it('does not render any list items when response is empty', () => {
    wrapper = createComponent(noSavedRepliesResponse);

    expect(wrapper.findAllComponents(ListItem).length).toBe(0);
  });

  it('renders list of comment templates', () => {
    const savedReplies = savedRepliesResponse.data.object.savedReplies.nodes;
    wrapper = createComponent(savedRepliesResponse);

    expect(wrapper.findAllComponents(ListItem).length).toBe(2);
    expect(wrapper.findAllComponents(ListItem).at(0).props('template')).toEqual(
      expect.objectContaining(savedReplies[0]),
    );
    expect(wrapper.findAllComponents(ListItem).at(1).props('template')).toEqual(
      expect.objectContaining(savedReplies[1]),
    );
  });
});
