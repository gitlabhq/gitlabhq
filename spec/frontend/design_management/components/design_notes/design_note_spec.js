import { shallowMount } from '@vue/test-utils';
import DesignNote from '~/design_management/components/design_notes/design_note.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const $route = {
  hash: '#note_123',
};

describe('Design note component', () => {
  let wrapper;

  const findUserAvatar = () => wrapper.find(UserAvatarLink);
  const findUserLink = () => wrapper.find('.js-user-link');

  function createComponent(props = {}) {
    wrapper = shallowMount(DesignNote, {
      propsData: {
        note: {},
        ...props,
      },
      mocks: {
        $route,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('should match the snapshot', () => {
    createComponent({
      note: {
        id: '1',
        createdAt: '2019-07-26T15:02:20Z',
        author: {
          id: 'author-id',
        },
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('should render an author', () => {
    createComponent({
      note: {
        id: '1',
        author: {
          id: 'author-id',
        },
      },
    });

    expect(findUserAvatar().exists()).toBe(true);
    expect(findUserLink().exists()).toBe(true);
  });

  it('should render a time ago tooltip if note has createdAt property', () => {
    createComponent({
      note: {
        id: '1',
        createdAt: '2019-07-26T15:02:20Z',
        author: {
          id: 'author-id',
        },
      },
    });

    expect(wrapper.find(TimeAgoTooltip).exists()).toBe(true);
  });

  it('should trigger a scrollIntoView method', () => {
    createComponent({
      note: {
        id: 'gid://gitlab/DiffNote/123',
        author: {
          id: 'author-id',
        },
      },
    });

    expect(scrollIntoViewMock).toHaveBeenCalled();
  });
});
