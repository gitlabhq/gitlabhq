import { GlAvatar, GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CommentPopover from '~/issuable/popover/components/comment_popover.vue';
import noteQuery from '~/issuable/popover/queries/note.query.graphql';

const noteId = 123;
const mockNote = {
  id: `gid://gitlab/Note/${noteId}`,
  author: {
    __typename: 'User',
    id: 'gid://gitlab/User/1',
    avatarUrl: '/avatar.jpg',
    name: 'John Doe',
    username: 'johndoe',
    webUrl: '/johndoe',
    webPath: '/johndoe',
  },
  bodyFirstLineHtml: '<p>Test note</p>',
  createdAt: '2024-07-17T12:00:00Z',
  internal: false,
};

describe('CommentPopover', () => {
  Vue.use(VueApollo);
  let wrapper;
  const mockTarget = document.createElement('a');
  mockTarget.href = `/gitlab-org/gitlab/issues/1#note_${noteId}`;

  const createComponent = ({ apolloQueryHandler } = {}) => {
    const mockApollo = createMockApollo([[noteQuery, apolloQueryHandler]]);

    return mount(CommentPopover, {
      propsData: {
        target: mockTarget,
      },
      apolloProvider: mockApollo,
    });
  };

  it('shows loading state', async () => {
    const handler = jest.fn().mockReturnValue(new Promise(() => {}));
    wrapper = createComponent({ apolloQueryHandler: handler });

    await nextTick();
    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  it('renders author information when note is loaded', async () => {
    const handler = jest.fn().mockResolvedValue({ data: { note: mockNote } });
    wrapper = createComponent({ apolloQueryHandler: handler });

    await waitForPromises();

    expect(wrapper.findComponent(GlAvatar).props('src')).toBe('/avatar.jpg');
    expect(wrapper.text()).toContain('John Doe');
  });

  it('renders note text', async () => {
    const handler = jest.fn().mockResolvedValue({ data: { note: mockNote } });
    wrapper = createComponent({ apolloQueryHandler: handler });

    await waitForPromises();

    expect(wrapper.find('.md').exists()).toBe(true);
    expect(wrapper.find('.md').html()).toContain('<p>Test note</p>');
  });

  it('hides if popover query errors', async () => {
    const handler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
    wrapper = createComponent({ apolloQueryHandler: handler });

    await waitForPromises();

    expect(wrapper.findComponent(GlPopover).props('show')).toBe(false);
  });

  it('hides if empty query result', async () => {
    const handler = jest.fn().mockResolvedValue({ data: { note: null } });
    wrapper = createComponent({ apolloQueryHandler: handler });

    await waitForPromises();

    expect(wrapper.findComponent(GlPopover).props('show')).toBe(false);
  });

  it('does not render empty note text <p>', async () => {
    const handler = jest
      .fn()
      .mockResolvedValue({ data: { note: { ...mockNote, bodyFirstLineHtml: '<p></p>' } } });
    wrapper = createComponent({ apolloQueryHandler: handler });

    await waitForPromises();

    expect(wrapper.find('.md').exists()).toBe(false);
  });
});
