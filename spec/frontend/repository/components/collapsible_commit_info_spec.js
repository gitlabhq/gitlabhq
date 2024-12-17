import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CollapsibleCommitInfo from '~/repository/components/collapsible_commit_info.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('CollapsibleCommitInfo', () => {
  let wrapper;
  const defaultProps = {
    sha: '1234567890abcdef',
    authorName: 'John Doe',
    authoredDate: '2023-06-01T12:00:00Z',
    titleHtml: 'Initial commit',
    message: 'Commit message',
    descriptionHtml: '&#x000A;This is a commit description',
    webPath: '/commit/1234567890abcdef',
    author: {
      webPath: '/users/johndoe',
      avatarUrl: 'https://example.com/avatar.jpg',
      name: 'John Doe',
    },
  };

  const createComponent = async (props = {}) => {
    wrapper = shallowMountExtended(CollapsibleCommitInfo, {
      propsData: { commit: { ...defaultProps, ...props }, historyUrl: '/project/history' },
    });
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  const findCommitterAvatar = () => wrapper.findComponent(UserAvatarLink);
  const findDefaultAvatar = () => wrapper.findComponent(UserAvatarImage);
  const findCommitTimeAgo = () => wrapper.findComponent(TimeagoTooltip);
  const findCommitId = () => wrapper.findByText('12345678');
  const findHistoryButton = () => wrapper.findByTestId('collapsible-commit-history');
  const findTextExpander = () => wrapper.findByTestId('text-expander');
  const findCommitRowDescription = () => wrapper.find('pre');
  const findCommitTitle = () => wrapper.findByText('Initial commit');
  const findCommitterName = () => wrapper.findByText('John Doe');

  describe('renders user avatar correctly', () => {
    it('renders avatar link if user has a custom profile photo', () => {
      expect(findCommitterAvatar().exists()).toBe(true);
      expect(findDefaultAvatar().exists()).toBe(false);
      expect(findCommitterAvatar().props()).toStrictEqual({
        imgAlt: "John Doe's avatar",
        imgCssClasses: '',
        imgCssWrapperClasses: '',
        imgSize: 32,
        imgSrc: 'https://example.com/avatar.jpg',
        lazy: false,
        linkHref: '/users/johndoe',
        popoverUserId: '',
        popoverUsername: '',
        tooltipPlacement: 'top',
        tooltipText: '',
        username: '',
      });
    });

    it('renders default avatar image if user does not have a custom profile photo', () => {
      createComponent({
        sha: '1234567890abcdef',
        authorName: 'John Doe',
        author: null,
        authoredDate: '2023-06-01T12:00:00Z',
        titleHtml: 'Initial commit',
        descriptionHtml: '&#x000A;This is a commit description',
        webPath: '/commit/1234567890abcdef',
      });
      expect(findCommitterAvatar().exists()).toBe(false);
      expect(findDefaultAvatar().exists()).toBe(true);
      expect(findDefaultAvatar().props()).toStrictEqual({
        cssClasses: '',
        imgAlt: 'user avatar',
        imgSrc: 'file-mock',
        pseudo: false,
        size: 32,
        lazy: false,
        tooltipPlacement: 'top',
        tooltipText: '',
      });
    });
  });

  it('renders commit details correctly', () => {
    expect(findCommitTimeAgo().props().time).toBe('2023-06-01T12:00:00Z');
    expect(findCommitId().exists()).toBe(true);
    expect(findHistoryButton().exists()).toBe(true);
    expect(findHistoryButton().attributes('href')).toBe('/project/history');
  });

  describe('text expander', () => {
    it('renders commit details collapsed by default', () => {
      expect(findTextExpander().exists()).toBe(true);
      expect(findCommitTitle().exists()).toBe(false);
      expect(findCommitterName().exists()).toBe(false);
      expect(findCommitRowDescription().exists()).toBe(false);
    });

    it('shows commit details when clicking the expander button', async () => {
      await findTextExpander().vm.$emit('click');
      await nextTick();

      expect(findTextExpander().classes('open')).toBe(true);
      expect(findTextExpander().props('selected')).toBe(true);
      expect(findCommitTitle().exists()).toBe(true);
      expect(findCommitterName().exists()).toBe(true);
      expect(findCommitRowDescription().html()).toBe(
        '<pre class="commit-row-description gl-mb-3 gl-whitespace-pre-wrap">This is a commit description</pre>',
      );
    });

    it('sets correct CSS class if the commit message is empty', async () => {
      createComponent({ message: '' });
      await findTextExpander().vm.$emit('click');
      await nextTick();
      expect(findCommitTitle().classes()).toContain('gl-italic');
    });

    it('does not render description when description is null', async () => {
      createComponent({
        sha: '1234567890abcdef',
        authorName: 'John Doe',
        authoredDate: '2023-06-01T12:00:00Z',
        titleHtml: 'Initial commit',
        descriptionHtml: null,
        webPath: '/commit/1234567890abcdef',
      });

      await findTextExpander().vm.$emit('click');
      await nextTick();

      expect(findCommitRowDescription().exists()).toBe(false);
    });
  });
});
