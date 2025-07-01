import { nextTick } from 'vue';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitInfo from '~/repository/components/commit_info.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

let wrapper;
const commit = {
  title: 'Commit title',
  titleHtml: 'Commit title html',
  message: 'Commit message',
  authoredDate: '2019-01-01',
  authorName: 'Test authorName',
  author: { name: 'Test name', avatarUrl: 'https://test.com', webPath: '/test' },
};

const findTextExpander = () => wrapper.findComponent(GlButton);
const findUserLink = () => wrapper.findByText(commit.author.name);
const findCommitterWrapper = () => wrapper.findByTestId('committer');
const findUserAvatarLink = () => wrapper.findComponent(UserAvatarLink);
const findUserAvatarImages = () => wrapper.findAllComponents(UserAvatarImage);
const findTimeagoTooltips = () => wrapper.findAllComponents(TimeagoTooltip);
const findCommitRowDescription = () => wrapper.find('pre');
const findTitleHtml = () => wrapper.findByText(commit.titleHtml);

const createComponent = async ({ commitMock = {}, prevBlameLink, span = 3 } = {}) => {
  wrapper = shallowMountExtended(CommitInfo, {
    propsData: { commit: { ...commit, ...commitMock }, prevBlameLink, span },
    stubs: { GlSprintf },
  });

  await nextTick();
};

describe('Repository last commit component', () => {
  it('renders author info', () => {
    createComponent();

    expect(findUserLink().exists()).toBe(true);
    expect(findUserAvatarLink().exists()).toBe(true);
    expect(findUserAvatarLink().props('imgAlt')).toBe("Test authorName's avatar");
  });

  it('hides author component when author does not exist', () => {
    createComponent({ commitMock: { author: null } });

    expect(findUserLink().exists()).toBe(false);
    expect(findUserAvatarLink().exists()).toBe(false);
  });

  it('truncates author name when commit spans less than 3 lines', () => {
    createComponent({ span: 2 });

    expect(findCommitterWrapper().classes()).toEqual([
      'committer',
      'gl-basis-full',
      'gl-truncate',
      'gl-text-sm',
      'gl-inline-flex',
    ]);
    expect(findUserLink().classes()).toEqual([
      'commit-author-link',
      'js-user-link',
      'gl-inline-block',
      'gl-truncate',
    ]);
  });

  it('does not render description expander when description is null', () => {
    createComponent();

    expect(findTextExpander().exists()).toBe(false);
    expect(findCommitRowDescription().exists()).toBe(false);
  });

  describe('when the description is present', () => {
    beforeEach(() => {
      createComponent({ commitMock: { descriptionHtml: '&#x000A;Update ADOPTERS.md' } });
    });

    it('strips the first newline of the description', () => {
      expect(findCommitRowDescription().html()).toBe(
        '<pre class="commit-row-description gl-mb-3 gl-whitespace-pre-wrap">Update ADOPTERS.md</pre>',
      );
    });

    it('renders commit description collapsed by default', () => {
      expect(findCommitRowDescription().classes('!gl-block')).toBe(false);
      expect(findTextExpander().classes('open')).toBe(false);
      expect(findTextExpander().props('selected')).toBe(false);
    });

    it('expands commit description when clicking expander', async () => {
      findTextExpander().vm.$emit('click');
      await nextTick();

      expect(findCommitRowDescription().classes('!gl-block')).toBe(true);
      expect(findTextExpander().classes('open')).toBe(true);
      expect(findTextExpander().props('selected')).toBe(true);
    });
  });

  describe('previous blame link', () => {
    const prevBlameLink = '<a>Previous blame link</a>';

    it('renders a previous blame link when it is present', () => {
      createComponent({ prevBlameLink });

      expect(wrapper.html()).toContain(prevBlameLink);
    });

    it('does not render a previous blame link when it is not present', () => {
      createComponent({ prevBlameLink: null });

      expect(wrapper.html()).not.toContain(prevBlameLink);
    });
  });

  it('sets correct CSS class if the commit message is empty', () => {
    createComponent({ commitMock: { message: '' } });

    expect(findTitleHtml().classes()).toContain('gl-italic');
  });

  describe('when committer is different from author', () => {
    const commitMockWithDifferentCommitter = {
      author: { name: 'John Doe', email: 'john@example.com' },
      committerName: 'Jane Smith',
      committerEmail: 'jane@example.com',
      committerAvatarUrl: 'https://committer-avatar.com/avatar.jpg',
      committedDate: '2019-02-01',
    };

    beforeEach(() => createComponent({ commitMock: commitMockWithDifferentCommitter }));

    it('displays committer information when committer differs from author', () => {
      const text = findCommitterWrapper().text();

      expect(text).toContain('John Doe');
      expect(text).toContain('authored');
      expect(text).toContain('and');
      expect(text).toContain('Jane Smith');
      expect(text).toContain('committed');
    });

    it('displays committer avatar when committer avatar URL is provided', () => {
      expect(findUserAvatarImages().at(0).props()).toMatchObject({
        size: 16,
        imgSrc: commitMockWithDifferentCommitter.committerAvatarUrl,
      });
    });

    it('displays both authored and committed dates', () => {
      const timeagoTooltips = findTimeagoTooltips();

      expect(timeagoTooltips.at(0).props('time')).toBe(commit.authoredDate);
      expect(timeagoTooltips.at(1).props('time')).toBe(
        commitMockWithDifferentCommitter.committedDate,
      );
    });
  });
});
