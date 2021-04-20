import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import Component from '~/diffs/components/commit_item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import getDiffWithCommit from '../mock_data/diff_with_commit';

jest.mock('~/user_popovers');

const TEST_AUTHOR_NAME = 'test';
const TEST_AUTHOR_EMAIL = 'test+test@gitlab.com';
const TEST_AUTHOR_GRAVATAR = `${TEST_HOST}/avatar/test?s=40`;
const TEST_SIGNATURE_HTML = '<a>Legit commit</a>';
const TEST_PIPELINE_STATUS_PATH = `${TEST_HOST}/pipeline/status`;

describe('diffs/components/commit_item', () => {
  let wrapper;

  const timeago = getTimeago();
  const { commit } = getDiffWithCommit();

  const getTitleElement = () => wrapper.find('.commit-row-message.item-title');
  const getDescElement = () => wrapper.find('pre.commit-row-description');
  const getDescExpandElement = () => wrapper.find('.commit-content .js-toggle-button');
  const getShaElement = () => wrapper.find('[data-testid="commit-sha-group"]');
  const getAvatarElement = () => wrapper.find('.user-avatar-link');
  const getCommitterElement = () => wrapper.find('.committer');
  const getCommitActionsElement = () => wrapper.find('.commit-actions');
  const getCommitPipelineStatus = () => wrapper.find(CommitPipelineStatus);

  const mountComponent = (propsData) => {
    wrapper = mount(Component, {
      propsData: {
        commit,
        ...propsData,
      },
      stubs: {
        CommitPipelineStatus: true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders commit title', () => {
      const titleElement = getTitleElement();

      expect(titleElement.attributes('href')).toBe(commit.commit_url);
      expect(titleElement.text()).toBe(commit.title_html);
    });

    it('renders commit description', () => {
      const descElement = getDescElement();
      const descExpandElement = getDescExpandElement();

      const expected = commit.description_html.replace(/&#x000A;/g, '');

      expect(trimText(descElement.text())).toEqual(trimText(expected));
      expect(descExpandElement.exists()).toBe(true);
    });

    it('renders commit sha', () => {
      const shaElement = getShaElement();
      const labelElement = shaElement.find('[data-testid="commit-sha-short-id"]');
      const buttonElement = shaElement.find('button.input-group-text');

      expect(labelElement.text()).toEqual(commit.short_id);
      expect(buttonElement.props('text')).toBe(commit.id);
    });

    it('renders author avatar', () => {
      const avatarElement = getAvatarElement();
      const imgElement = avatarElement.find('img');

      expect(avatarElement.attributes('href')).toBe(commit.author.web_url);
      expect(imgElement.classes()).toContain('s40');
      expect(imgElement.attributes('alt')).toBe(commit.author.name);
      expect(imgElement.attributes('src')).toBe(commit.author.avatar_url);
    });

    it('renders committer text', () => {
      const committerElement = getCommitterElement();
      const nameElement = committerElement.find('a');

      const expectTimeText = timeago.format(commit.authored_date);
      const expectedText = `${commit.author.name} authored ${expectTimeText}`;

      expect(trimText(committerElement.text())).toEqual(expectedText);
      expect(nameElement.attributes('href')).toBe(commit.author.web_url);
      expect(nameElement.text()).toBe(commit.author.name);
      expect(nameElement.classes()).toContain('js-user-link');
      expect(nameElement.attributes('data-user-id')).toEqual(commit.author.id.toString());
    });
  });

  describe('without commit description', () => {
    beforeEach(() => {
      mountComponent({ commit: { ...commit, description_html: '' } });
    });

    it('hides description', () => {
      const descElement = getDescElement();
      const descExpandElement = getDescExpandElement();

      expect(descElement.exists()).toBeFalsy();
      expect(descExpandElement.exists()).toBeFalsy();
    });
  });

  describe('with no matching user', () => {
    beforeEach(() => {
      mountComponent({
        commit: {
          ...commit,
          author: null,
          author_email: TEST_AUTHOR_EMAIL,
          author_name: TEST_AUTHOR_NAME,
          author_gravatar_url: TEST_AUTHOR_GRAVATAR,
        },
      });
    });

    it('renders author avatar', () => {
      const avatarElement = getAvatarElement();
      const imgElement = avatarElement.find('img');

      expect(avatarElement.attributes('href')).toBe(`mailto:${TEST_AUTHOR_EMAIL}`);
      expect(imgElement.attributes('alt')).toBe(TEST_AUTHOR_NAME);
      expect(imgElement.attributes('src')).toBe(TEST_AUTHOR_GRAVATAR);
    });

    it('renders committer text', () => {
      const committerElement = getCommitterElement();
      const nameElement = committerElement.find('a');

      expect(nameElement.attributes('href')).toBe(`mailto:${TEST_AUTHOR_EMAIL}`);
      expect(nameElement.text()).toBe(TEST_AUTHOR_NAME);
    });
  });

  describe('with signature', () => {
    beforeEach(() => {
      mountComponent({
        commit: { ...commit, signature_html: TEST_SIGNATURE_HTML },
      });
    });

    it('renders signature html', () => {
      const actionsElement = getCommitActionsElement();

      expect(actionsElement.html()).toContain(TEST_SIGNATURE_HTML);
    });
  });

  describe('with pipeline status', () => {
    beforeEach(() => {
      mountComponent({
        commit: { ...commit, pipeline_status_path: TEST_PIPELINE_STATUS_PATH },
      });
    });

    it('renders pipeline status', () => {
      expect(getCommitPipelineStatus().exists()).toBe(true);
    });
  });
});
