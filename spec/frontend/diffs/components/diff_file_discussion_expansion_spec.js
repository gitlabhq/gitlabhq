import { GlAvatarsInline } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DiffFileDiscussionExpansion from '~/diffs/components/diff_file_discussion_expansion.vue';

const createMockDiscussions = () => [
  {
    notes: [
      {
        author: {
          id: 1,
          path: '/',
          username: 'root',
          avatar_url: '/avatar_url',
        },
        created_at: '2017-02-07T10:11:18.395Z',
      },
    ],
  },
  {
    notes: [
      {
        author: {
          id: 2,
          path: '/',
          username: 'root',
          avatar_url: '/avatar_url2',
        },
        created_at: '2017-02-07T10:11:18.395Z',
      },
    ],
  },
];

describe('Diff file discussion expansion component', () => {
  let wrapper;

  const findAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findToggle = () => wrapper.findByTestId('toggle-btn');

  function createComponent() {
    wrapper = mountExtended(DiffFileDiscussionExpansion, {
      propsData: {
        discussions: createMockDiscussions(),
      },
    });
  }

  it('renders first avatar of all discussions', () => {
    createComponent();

    expect(findAvatars().props('avatars')).toEqual([
      expect.objectContaining({ avatar_url: '/avatar_url' }),
      expect.objectContaining({ avatar_url: '/avatar_url2' }),
    ]);
  });

  it('renders text with amount of discussions', () => {
    createComponent();

    expect(wrapper.text()).toContain('2 comments');
  });

  it('emits toggle on toggle button click', () => {
    createComponent();

    findToggle().trigger('click');

    expect(wrapper.emitted('toggle')).toHaveLength(1);
  });
});
