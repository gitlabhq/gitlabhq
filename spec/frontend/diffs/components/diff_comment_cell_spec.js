import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import DiffCommentCell from '~/diffs/components/diff_comment_cell.vue';
import DiffDiscussionReply from '~/diffs/components/diff_discussion_reply.vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';

Vue.use(PiniaVuePlugin);

describe('DiffCommentCell', () => {
  let pinia;

  const createWrapper = (props = {}) => {
    const { renderDiscussion, ...otherProps } = props;
    const line = {
      discussions: [],
      renderDiscussion,
    };
    const diffFileHash = 'abc';

    return shallowMount(DiffCommentCell, {
      pinia,
      propsData: { line, diffFileHash, ...otherProps },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia();
  });

  it('renders discussions if line has discussions', () => {
    const wrapper = createWrapper({ renderDiscussion: true });

    expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(true);
  });

  it('does not render discussions if line has no discussions', () => {
    const wrapper = createWrapper();

    expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(false);
  });

  it('renders discussion reply if line has no draft', () => {
    const wrapper = createWrapper();

    expect(wrapper.findComponent(DiffDiscussionReply).exists()).toBe(true);
  });

  it('does not render discussion reply if line has draft', () => {
    const wrapper = createWrapper({ hasDraft: true });

    expect(wrapper.findComponent(DiffDiscussionReply).exists()).toBe(false);
  });
});
