import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitInfo from '~/repository/components/commit_info.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

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
const findUserAvatarLink = () => wrapper.findComponent(UserAvatarLink);
const findAuthorName = () => wrapper.findByText(`${commit.authorName} authored`);
const findCommitRowDescription = () => wrapper.find('pre');
const findTitleHtml = () => wrapper.findByText(commit.titleHtml);

const createComponent = async ({ commitMock = {} } = {}) => {
  wrapper = shallowMountExtended(CommitInfo, {
    propsData: { commit: { ...commit, ...commitMock } },
  });

  await nextTick();
};

describe('Repository last commit component', () => {
  it('renders author info', () => {
    createComponent();

    expect(findUserLink().exists()).toBe(true);
    expect(findUserAvatarLink().exists()).toBe(true);
  });

  it('hides author component when author does not exist', () => {
    createComponent({ commitMock: { author: null } });

    expect(findUserLink().exists()).toBe(false);
    expect(findUserAvatarLink().exists()).toBe(false);
    expect(findAuthorName().exists()).toBe(true);
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
        '<pre class="commit-row-description gl-mb-3 gl-white-space-pre-line">Update ADOPTERS.md</pre>',
      );
    });

    it('renders commit description collapsed by default', () => {
      expect(findCommitRowDescription().classes('gl-display-block!')).toBe(false);
      expect(findTextExpander().classes('open')).toBe(false);
      expect(findTextExpander().props('selected')).toBe(false);
    });

    it('expands commit description when clicking expander', async () => {
      findTextExpander().vm.$emit('click');
      await nextTick();

      expect(findCommitRowDescription().classes('gl-display-block!')).toBe(true);
      expect(findTextExpander().classes('open')).toBe(true);
      expect(findTextExpander().props('selected')).toBe(true);
    });
  });

  it('sets correct CSS class if the commit message is empty', () => {
    createComponent({ commitMock: { message: '' } });

    expect(findTitleHtml().classes()).toContain('gl-font-style-italic');
  });
});
