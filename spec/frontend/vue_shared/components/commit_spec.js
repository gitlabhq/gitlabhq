import { shallowMount } from '@vue/test-utils';
import CommitComponent from '~/vue_shared/components/commit.vue';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

describe('Commit component', () => {
  let props;
  let wrapper;

  const findUserAvatar = () => wrapper.find(UserAvatarLink);

  const createComponent = propsData => {
    wrapper = shallowMount(CommitComponent, {
      propsData,
      sync: false,
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a fork icon if it does not represent a tag', () => {
    createComponent({
      tag: false,
      commitRef: {
        name: 'master',
        ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
      },
      commitUrl:
        'https://gitlab.com/gitlab-org/gitlab-foss/commit/b7836eddf62d663c665769e1b0960197fd215067',
      shortSha: 'b7836edd',
      title: 'Commit message',
      author: {
        avatar_url: 'https://gitlab.com/uploads/-/system/user/avatar/300478/avatar.png',
        web_url: 'https://gitlab.com/jschatz1',
        path: '/jschatz1',
        username: 'jschatz1',
      },
    });

    expect(
      wrapper
        .find('.icon-container')
        .find(Icon)
        .exists(),
    ).toBe(true);
  });

  describe('Given all the props', () => {
    beforeEach(() => {
      props = {
        tag: true,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-foss/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: 'Commit message',
        author: {
          avatar_url: 'https://gitlab.com/uploads/-/system/user/avatar/300478/avatar.png',
          web_url: 'https://gitlab.com/jschatz1',
          path: '/jschatz1',
          username: 'jschatz1',
        },
      };
      createComponent(props);
    });

    it('should render a tag icon if it represents a tag', () => {
      expect(wrapper.find('icon-stub[name="tag"]').exists()).toBe(true);
    });

    it('should render a link to the ref url', () => {
      expect(wrapper.find('.ref-name').attributes('href')).toBe(props.commitRef.ref_url);
    });

    it('should render the ref name', () => {
      expect(wrapper.find('.ref-name').text()).toContain(props.commitRef.name);
    });

    it('should render the commit short sha with a link to the commit url', () => {
      expect(wrapper.find('.commit-sha').attributes('href')).toEqual(props.commitUrl);

      expect(wrapper.find('.commit-sha').text()).toContain(props.shortSha);
    });

    it('should render icon for commit', () => {
      expect(wrapper.find('icon-stub[name="commit"]').exists()).toBe(true);
    });

    describe('Given commit title and author props', () => {
      it('should render a link to the author profile', () => {
        const userAvatar = findUserAvatar();

        expect(userAvatar.props('linkHref')).toBe(props.author.path);
      });

      it('Should render the author avatar with title and alt attributes', () => {
        const userAvatar = findUserAvatar();

        expect(userAvatar.exists()).toBe(true);

        expect(userAvatar.props('imgAlt')).toBe(`${props.author.username}'s avatar`);
      });
    });

    it('should render the commit title', () => {
      expect(wrapper.find('.commit-row-message').attributes('href')).toEqual(props.commitUrl);

      expect(wrapper.find('.commit-row-message').text()).toContain(props.title);
    });
  });

  describe('When commit title is not provided', () => {
    it('should render default message', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-foss/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      createComponent(props);

      expect(wrapper.find('.commit-title span').text()).toContain(
        "Can't find HEAD commit for this branch",
      );
    });
  });

  describe('When commit ref is provided, but merge ref is not', () => {
    it('should render the commit ref', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-foss/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      createComponent(props);
      const refEl = wrapper.find('.ref-name');

      expect(refEl.text()).toContain('master');

      expect(refEl.attributes('href')).toBe(props.commitRef.ref_url);

      expect(refEl.attributes('data-original-title')).toBe(props.commitRef.name);

      expect(wrapper.find('icon-stub[name="branch"]').exists()).toBe(true);
    });
  });

  describe('When both commit and merge ref are provided', () => {
    it('should render the merge ref', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-foss/commit/b7836eddf62d663c665769e1b0960197fd215067',
        mergeRequestRef: {
          iid: 1234,
          path: 'https://example.com/path/to/mr',
          title: 'Test MR',
        },
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      createComponent(props);
      const refEl = wrapper.find('.ref-name');

      expect(refEl.text()).toContain('1234');

      expect(refEl.attributes('href')).toBe(props.mergeRequestRef.path);

      expect(refEl.attributes('data-original-title')).toBe(props.mergeRequestRef.title);

      expect(wrapper.find('icon-stub[name="git-merge"]').exists()).toBe(true);
    });
  });

  describe('When showRefInfo === false', () => {
    it('should not render any ref info', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-foss/commit/b7836eddf62d663c665769e1b0960197fd215067',
        mergeRequestRef: {
          iid: 1234,
          path: '/path/to/mr',
          title: 'Test MR',
        },
        shortSha: 'b7836edd',
        title: null,
        author: {},
        showRefInfo: false,
      };

      createComponent(props);

      expect(wrapper.find('.ref-name').exists()).toBe(false);
    });
  });
});
